package # hide from PAUSE
App::DBBrowser::From::Union;

use warnings;
use strict;
use 5.016;

use Term::Choose qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::From::Cte;
use App::DBBrowser::From::Subquery;
use App::DBBrowser::Table;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub __valid_operators {
    my ( $sf ) = @_;
    my $dbms = $sf->{i}{dbms};
    # Precedence:
    # INTERSECT has priority over UNION or EXCEPT.
    # EXCEPT and UNION are evaluated Left to Right
    if ( $dbms eq 'Firebird' ) {
        return [ 'Union', 'UNION ALL' ];
    }
    elsif ( $dbms =~ /^(?:SQLite|Informix)\z/ ) {
        return [ 'UNION', 'UNION ALL', 'INTERSECT', 'EXCEPT' ];
    }
    else {
        return [ 'UNION', 'UNION ALL', 'INTERSECT', 'INTERSECT ALL', 'EXCEPT', 'EXCEPT ALL' ];
    }
}


sub union_tables {
    my ( $sf ) = @_;
    $sf->{d}{stmt_types} = [ 'Union' ];
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $confirm = '  End of additions';
    my @pre = ( undef, $confirm );
    my $modify      = '  Edit';
    my $parentheses = '  Parentheses';
    my @post;
    push @post, $modify if $sf->{o}{enable}{u_edit_stmt};
    push @post, $parentheses if $sf->{o}{enable}{u_parentheses} && $sf->{i}{dbms} !~ /^(?:SQLite|Firebird)\z/;
    my $set_operators = $sf->__valid_operators();
    $set_operators = [ map { '- ' . $_ } map { s/\b(.)/uc $1/ger } map { lc } @$set_operators ];
    my $menu = [ @pre, @$set_operators, @post ];
    my $data = [];
    my $sql = {};
    $ax->reset_sql( $sql );

    UNION: while ( 1 ) {
        my $table = $sf->__add_table( $sql, $data );
        if ( ! defined $table ) {
            if ( @$data ) {
                delete $data->[-1]{operator};
            }
            else {
                return;
            }
        }
        my $old_idx = 0;

        OPERATOR: while ( 1 ) {
            $sql->{subselect_stmts} = $sf->__get_sub_select_stmts( $data );
            my $info = $ax->get_sql_info( $sql );
            # Choose
            my $idx = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, prompt => 'Your choice:', info => $info, index => 1, default => $old_idx }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $idx || ! defined $menu->[$idx] ) {
                if ( @$data ) {
                    $old_idx = 0;
                    pop @$data;
                    if ( @$data ) {                   #
                        delete $data->[-1]{operator}; #
                        next OPERATOR;                #
                    }                                 #
                    next UNION;
                }
                return;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx = 0;
                    next OPERATOR;
                }
                $old_idx = $idx;
            }
            if ( $menu->[$idx] eq $confirm ) {
                last UNION;
            }
            elsif ( $menu->[$idx] eq $modify ) {
                $sf->__edit_tables( $sql, $data );
                next OPERATOR;
            }
            elsif ( $menu->[$idx] eq $parentheses ) {
                $sf->__parentheses( $sql, $data );
                next OPERATOR;
            }
            my $operator = $menu->[$idx] =~ s/^-\s//r;
            $data->[-1]{operator} = $operator;
            next UNION;
        }
    }
    $sql->{subselect_stmts} = $sf->__get_sub_select_stmts( $data );
    my $union_derived_table = $ax->get_stmt( $sql, 'Union', 'prepare' );
    delete $sql->{subselect_stmts};
    my $union_alias = $ax->table_alias( $sql, 'derived_table', $union_derived_table );
    return $union_derived_table, $union_alias;
}


sub __add_table {
    my ( $sf, $sql, $data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @pre = ( undef );
    my ( $from_subquery, $from_cte ) = ( '  Subquery', '  Cte' );
    my @post;
    push @post, $from_subquery if $sf->{o}{enable}{u_derived};
    push @post, $from_cte      if $sf->{o}{enable}{u_cte};
    my $table_keys;
    if ( $sf->{o}{G}{metadata} ) {
        $table_keys = [ @{$sf->{d}{user_table_keys}}, @{$sf->{d}{sys_table_keys}} ];
    }
    else {
        $table_keys = [ @{$sf->{d}{user_table_keys}} ];
    }
    my $menu  = [ @pre, map( '- ' . $_, @$table_keys ), @post ];
    my $prompt = @$data ? 'Add a table:' : 'Choose the first table:';
    my $old_idx_tbl = 0;

    TABLE: while ( 1 ) {
        $sql->{subselect_stmts} = $sf->__get_sub_select_stmts( $data );
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $idx_tbl = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => $prompt, index => 1, default => $old_idx_tbl }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $idx_tbl || ! defined $menu->[$idx_tbl] ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx_tbl == $idx_tbl && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx_tbl = 0;
                next TABLE;
            }
            $old_idx_tbl = $idx_tbl;
        }
        my $table_key = $menu->[$idx_tbl];
        my $table;
        if ( $table_key eq $from_subquery ) {
            my $sq = App::DBBrowser::From::Subquery->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $sql->{subselect_stmts} = $sf->__get_sub_select_stmts( $data );
            $table = $sq->subquery( $sql );
            if ( ! defined $table ) {
                next TABLE;
            }
            my $default_alias = 'p' . ( @$data + 1 );
            my $bu_table_aliases = $ax->clone_data( $sf->{d}{table_aliases} ); ##
            my $alias = $ax->table_alias( $sql, 'derived_table', $table, $default_alias );
            $sf->{d}{table_aliases} = $bu_table_aliases;
            if ( length $alias ) {
                $table .= " " . $alias;
            }
        }
        elsif ( $table_key eq $from_cte ) {
            my $sq = App::DBBrowser::From::File->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $sql->{subselect_stmts} = $sf->__get_sub_select_stmts( $data );
            $table = $sq->file( $sql );
            if ( ! defined $table ) {
                next TABLE;
            }
        }
        else {
            $table_key =~ s/^-\s//;
            $table = $ax->qq_table( $sf->{d}{tables_info}{$table_key} );
        }
        my ( $columns, $column_types ) = $ax->column_names_and_types( $table );
        if ( ! defined $columns ) {
            next TABLE;
        }
        my $data_types = {};
        @{$data_types}{@$columns} = @$column_types; ##
        my $table_sql = {};
        $ax->reset_sql( $table_sql );
        $table_sql->{table} = $table;
        $table_sql->{columns} = $columns;
        $table_sql->{data_types} = $data_types;
        push @$data, { table_sql => $table_sql, table_key => $table_key };
        my $ok = $sf->__edit_table_stmt( $sql, $data, $#$data );
        if ( ! $ok ) {
            pop @$data;
            next TABLE;
        }
        return $table;
    }
}


sub __get_sub_select_stmts {
    my ( $sf, $data ) = @_;
    my $stmts = [];
    for my $d ( @$data ) {
        if ( $d->{parentheses_open} ) {
            push @$stmts, ( "(" ) x $d->{parentheses_open};
        }
        if ( $d->{stmt} ) {
            push @$stmts, $d->{stmt};
        }
        if ( $d->{parentheses_close} ) {
            push @$stmts, ( ")" ) x $d->{parentheses_close};
        }
        if ( $d->{operator} ) {
            push @$stmts, $d->{operator};
        };
    }
    return $stmts;
}


sub __edit_tables {
    my ( $sf, $sql, $data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $old_idx_tbl = 0;
    my @bu;

    TABLE: while ( 1 ) {
        my $confirm = $sf->{i}{_confirm};
        my @pre = ( undef, $confirm );
        my $menu = [ @pre, map { '- ' . $_->{table_key} } @$data ];
        my $prompt = 'Table:';
        $sql->{subselect_stmts} = $sf->__get_sub_select_stmts( $data );
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $idx_tbl = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => $prompt, index => 1, default => $old_idx_tbl,
              undef => $sf->{i}{_back} }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $idx_tbl || ! defined $menu->[$idx_tbl] ) {
            if ( @bu ) {
                my $bu_data = pop @bu;
                for my $i ( 0 .. $#$bu_data ) {
                    $data->[$i] = { %{$bu_data->[$i]} };
                }
                $old_idx_tbl = 0;
                next TABLE;
            }
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx_tbl == $idx_tbl && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx_tbl = 0;
                next TABLE;
            }
            $old_idx_tbl = $idx_tbl;
        }
        if ( $menu->[$idx_tbl] eq $confirm ) {
            return 1;
        }
        $idx_tbl -= @pre;
        push @bu, $ax->clone_data( $data );
        my $ok = $sf->__edit_table_stmt( $sql, $data, $idx_tbl );
        if ( ! $ok ) {
            my $bu_data = pop @bu;
            for my $i ( 0 .. $#$bu_data ) {
                $data->[$i] = { %{$bu_data->[$i]} };
            }
        }
    }
}


sub __edit_table_stmt {
    my ( $sf, $sql, $data, $idx_tbl ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tbl = App::DBBrowser::Table->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $table_sql = $data->[$idx_tbl]{table_sql};
    my $bu_stmt_types = [ @{$sf->{d}{stmt_types}} ];
    my $bu_main_info = $sf->{d}{main_info}; ##
    $sql->{subselect_stmts} = $sf->__get_sub_select_stmts( $data );
    $sf->{d}{main_info} = $ax->get_sql_info( $sql );
    my $stmt =  $tbl->browse_the_table( $table_sql, 'Edit the statement:' );
    $sf->{d}{main_info} = $bu_main_info;
    $sf->{d}{stmt_types} = $bu_stmt_types;
    if ( ! $stmt ) {
        return;
    }
    $stmt = $ax->normalize_space_in_stmt( $stmt );
    $data->[$idx_tbl]{stmt} = $stmt;
    $data->[$idx_tbl]{sql} = $table_sql;
    return 1;
}


sub __parentheses {
    my ( $sf, $sql, $data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @idx_changed_tables;
    my $old_idx_tbl = 0;

    TABLE: while ( 1 ) {
        my @pre = ( undef, $sf->{i}{confirm} );
        my $reset_all = '  Reset all';
        my $menu = [ @pre, map('- ' . $_->{table_key}, @$data ) , $reset_all ];
        my $prompt = 'Parentheses:';
        $sql->{subselect_stmts} = $sf->__get_sub_select_stmts( $data );
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $idx_tbl = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => $prompt, index => 1, default => $old_idx_tbl,
              undef => $sf->{i}{back} }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $idx_tbl || ! defined $menu->[$idx_tbl] ) {
            if ( @idx_changed_tables ) {
                my $idx = pop @idx_changed_tables;
                delete $data->[$idx]{parentheses_open};
                delete $data->[$idx]{parentheses_close};
                $old_idx_tbl = 0;
                next TABLE;
            }
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx_tbl == $idx_tbl && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx_tbl = 0;
                next TABLE;
            }
            $old_idx_tbl = $idx_tbl;
        }
        if ( $menu->[$idx_tbl] eq $sf->{i}{confirm} ) {
            return 1;
        }
        elsif ( $menu->[$idx_tbl] eq $reset_all ) {
            for my $d ( @$data ) {
                delete $d->{parentheses_open};
                delete $d->{parentheses_close};
            }
            $old_idx_tbl = 0;
            next TABLE;
        }
        $idx_tbl -= @pre;
        $prompt = 'Parentheses' . "\n" . ( '(' x ( $data->[$idx_tbl]{parentheses_open} // 0 ) );
        $prompt .= $data->[$idx_tbl]{table_key} . ( ')' x ( $data->[$idx_tbl]{parentheses_close} // 0 ) ) . ':';
        my $open = '  + (';
        my $close = '  + )';
        my $reset = '  Reset';
        # Choose
        my $p_type = $tc->choose(
            [ undef, $open, $close, $reset ],
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => $prompt,
              undef => '  <=' }
        );
        if ( ! defined $p_type ) {
            next TABLE;
        }
        my $max_depth = 3;
        if ( $p_type eq $open && ( $data->[$idx_tbl]{parentheses_open} // 0 ) < $max_depth ) {
            $data->[$idx_tbl]{parentheses_open} += 1;
        }
        elsif ( $p_type eq $close && ( $data->[$idx_tbl]{parentheses_close} // 0 ) < $max_depth ) {
            $data->[$idx_tbl]{parentheses_close} += 1;
        }
        if ( $p_type eq $reset ) {
            delete $data->[$idx_tbl]{parentheses_open};
            delete $data->[$idx_tbl]{parentheses_close};
        }
        push @idx_changed_tables, $idx_tbl;
    }
}



1;

__END__
