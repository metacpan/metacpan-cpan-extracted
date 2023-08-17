package # hide from PAUSE
App::DBBrowser::Union; # required in App::DBBrowser.pm

use warnings;
use strict;
use 5.014;

use List::MoreUtils qw( any );

use Term::Choose qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Subqueries;
use App::DBBrowser::Table::Extensions;
use App::DBBrowser::Table::Substatements;

sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub union_tables {
    my ( $sf ) = @_;
    $sf->{d}{stmt_types} = [ 'Union' ];
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tables;
    if ( $sf->{o}{G}{metadata} ) {
        $tables = [ @{$sf->{d}{user_table_keys}}, @{$sf->{d}{sys_table_keys}} ];
    }
    else {
        $tables = [ @{$sf->{d}{user_table_keys}} ];
    }
    my $data = [];
    my $used_tables = [];
    my $old_idx_tbl = 0;

    TABLE: while ( 1 ) {
        my $enough_tables = '  Enough TABLES';
        my $from_subquery = '  Derived';
        my $where         = '  Where';
        my $parentheses   = '  Parentheses';
        my @pre  = ( undef, $enough_tables );
        my @post;
        push @post, $from_subquery if $sf->{o}{enable}{u_derived};
        push @post, $where         if $sf->{o}{enable}{u_where};
        push @post, $parentheses   if $sf->{o}{enable}{u_parentheses} && $sf->{i}{driver} !~ /^(?:SQLite|Firebird)\z/;
        my $used = ' (used)';
        my @tmp_tables;
        for my $table ( @$tables ) {
            if ( any { $_ eq $table } @$used_tables ) {
                push @tmp_tables, '- ' . $table . $used;
            }
            else {
                push @tmp_tables, '- ' . $table;
            }
        }
        my $prompt = 'Choose a table:';
        my $menu  = [ @pre, @tmp_tables, @post ];
        my $sql = {
            subselect_stmts => $sf->__get_sub_select_stmts( $data )
        };
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $idx_tbl = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => $prompt, index => 1, default => $old_idx_tbl }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $idx_tbl || ! defined $menu->[$idx_tbl] ) {
            if ( @$used_tables ) {
                $old_idx_tbl = 0;
                pop @$used_tables;
                pop @$data;
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
        my $table = $menu->[$idx_tbl];
        my $qt_table;
        if ( $table eq $enough_tables ) {
            if ( ! @$used_tables ) {
                return;
            }
            last TABLE;
        }
        elsif ( $table eq $where ) {
            $sf->__add_where_condition( $data );
            next TABLE;
        }
        elsif ( $table eq $parentheses ) {
            $sf->__add_parentheses( $data );
            next TABLE;
        }
        elsif ( $table eq $from_subquery ) {
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $sql = {
                subselect_stmts => $sf->__get_sub_select_stmts( $data )
            };
            $table = $sq->choose_subquery( $sql );
            if ( ! defined $table ) {
                next TABLE;
            }
            my $alias = 'p' . ( @$used_tables + 1 );
            $qt_table = $table . $sf->{i}{" AS "} . $ax->prepare_identifier( $alias );
        }
        else {
            $table =~ s/^-\s//;
            $table =~ s/\Q$used\E\z//;
            $qt_table = $ax->quote_table( $sf->{d}{tables_info}{$table} );
        }
        my $operator;
        if ( @$data ) {
            $operator = $sf->__set_operator( $sql, $table );
            if ( ! $operator ) {
                next TABLE;
            }
        }
        my $ok = $sf->__choose_table_columns( $data, $table, $qt_table, $operator );
        if ( ! $ok ) {
            next TABLE;
        }
        push @$used_tables, $table;
    }
    my $sql = {
        subselect_stmts => $sf->__get_sub_select_stmts( $data )
    };
    my $union_stmt = $ax->get_stmt( $sql, 'Union', 'prepare' );
    my $union_derived_table = $union_stmt =~ s/^\s*SELECT\s\*\sFROM\s+//r;
    $union_derived_table =~ s/\n\z//;
    if ( $sf->{o}{alias}{table} || $sf->{i}{driver} =~ /^(?:mysql|MariaDB|Pg)\z/ ) {
        $union_derived_table .= $sf->{i}{" AS "} . $ax->prepare_identifier( 't1' );
    }
    # column names in the result-set of a UNION are taken from the first query.
    my $columns = $ax->column_names( $union_derived_table );
    my $qt_columns = $ax->quote_cols( $columns );
    return $union_derived_table, $qt_columns;
}


sub __set_operator {
    my ( $sf, $sql, $table ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    # Precedence:
    # INTERSECT has priority over UNION or EXCEPT.
    # EXCEPT and UNION are evaluated Left to Right
    my @set_operators;
    if ( $sf->{i}{driver} eq 'Firebird' ) {
        @set_operators = ( 'UNION', 'UNION ALL' );
    }
    elsif ( $sf->{i}{driver} =~ /^(?:SQLite|Informix)\z/ ) {
        @set_operators = ( 'UNION', 'UNION ALL', 'INTERSECT', 'EXCEPT' );
    }
    else {
        @set_operators = ( 'UNION', 'UNION ALL', 'INTERSECT', 'INTERSECT ALL', 'EXCEPT', 'EXCEPT ALL' );
    }
    my @pre = ( undef );
    my $menu = [ @pre, map { '  ' . lc $_ } @set_operators ];
    my $prompt = sprintf 'Join %s with:', $table;
    my $info = $ax->get_sql_info( $sql );
    # Choose
    my $operator = $tc->choose(
        $menu,
        { %{$sf->{i}{lyt_v}}, info => $info, prompt => $prompt, undef => '  <=' }
    );
    $ax->print_sql_info( $info );
    if ( ! defined $operator ) {
        return;
    }
    return uc $operator =~ s/^\s\s//r;
}


sub __choose_table_columns {
    my ( $sf, $data, $table, $qt_table, $operator ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $privious_cols =  "'^'";
    my $next_idx = @$data;
    my $chosen_cols = [];
    my @bu_cols;
    $sf->{d}{col_names}{$table} //= $ax->column_names( $qt_table ); ##
    $data->[$next_idx] = { qt_table => $qt_table, table => $table };
    if ( $operator ) {
        $data->[$next_idx]{operator} = $operator;
    }

    COLUMNS: while ( 1 ) {
        my @pre = ( undef, $sf->{i}{ok} );
        push @pre, $sf->{i}{menu_addition} if $sf->{o}{enable}{extended_cols};
        #push @pre, $privious_cols          if $next_idx; # ###
        if ( ! @{$data->[$next_idx]{qt_columns}//[]} ) {
            $data->[$next_idx]{qt_columns} = [ '*' ];
        }
        my $sql = {
            subselect_stmts => $sf->__get_sub_select_stmts( $data )
        };
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my @choices = $tc->choose(
            [ @pre, @{$sf->{d}{col_names}{$table}} ],
            { %{$sf->{i}{lyt_h}}, info => $info, prompt => 'Columns:', meta_items => [ 0 .. $#pre ],
              include_highlighted => 2 }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $choices[0] ) {
            if ( @bu_cols ) {
                $chosen_cols = pop @bu_cols;
                $data->[$next_idx]{qt_columns} = $sf->__quote_union_table_cols( $chosen_cols );
                next COLUMNS;
            }
            $#$data = $next_idx - 1;
            return;
        }
        if ( $choices[0] eq $privious_cols ) {
            $data->[$next_idx]{qt_columns} = $data->[$next_idx-1]{qt_columns};
            return 1;
        }
        elsif ( $choices[0] eq $sf->{i}{ok} ) {
            shift @choices;
            push @$chosen_cols, map { { name => $_ } } @choices;
            if ( ! @$chosen_cols ) {
                $chosen_cols = [ map { { name => $_ } } @{$sf->{d}{col_names}{$table}} ];
            }
            $data->[$next_idx]{qt_columns} = $sf->__quote_union_table_cols( $chosen_cols );
            return 1;
        }
        #                                          INT                 String
        # SQLite, mysql, MariaDB, Pg, DB2 Oracle:  null                null
        # Informix                              :  cast('' as int)     ''
        # Firebird                              :  ''                  ''
        elsif ( $choices[0] eq $sf->{i}{menu_addition} ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $sql->{cols} = $ax->quote_cols( $sf->{d}{col_names}{$table} );
            my $complex_col = $ext->column( $sql, 'Union' );
            if ( ! defined $complex_col ) {
                next COLUMNS;
            }
            my $default = '_col' . ( @$chosen_cols + 1 );
            my $alias = $ax->alias( $sql, 'select_func_sq', $complex_col, $default );
            if ( ! length $alias ) {
                $alias = $default;
            }
            push @bu_cols, [ @$chosen_cols ];
            push @$chosen_cols, { name => $complex_col, alias => $alias };
            $data->[$next_idx]{qt_columns} = $sf->__quote_union_table_cols( $chosen_cols );
        }
        else {
            push @bu_cols, [ @$chosen_cols ];
            push @$chosen_cols, map { { name => $_ } } @choices;
            $data->[$next_idx]{qt_columns} = $sf->__quote_union_table_cols( $chosen_cols );
        }
    }
}


sub __quote_union_table_cols {
    my ( $sf, $cols ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $count = 0;
    my $qt_cols = [];
    for my $col ( @$cols ) {
        if ( length $col->{alias} ) {
            # only scalar functions and subqueries have an alias
            push @$qt_cols, $col->{name} . ' AS ' . $ax->prepare_identifier( $col->{alias} );
        }
        else {
            push @$qt_cols, $ax->prepare_identifier( $col->{name} );
        }
    }
    return $qt_cols;
}


sub __get_sub_select_stmts {
    my ( $sf, $data ) = @_;
    my $stmts = [];
    for my $d ( @$data ) {
        if ( $d->{operator} ) {
            push @$stmts, $d->{operator};
        };
        if ( $d->{parentheses_open} ) {
            push @$stmts, ( "(" ) x $d->{parentheses_open};
        }
        my $select = "SELECT " . join( ', ', @{$d->{qt_columns}} ) . " FROM " . $d->{qt_table};
        if ( length $d->{where_stmt} ) {
            $select .= " " . $d->{where_stmt};
        }
        push @$stmts, $select;
        if ( $d->{parentheses_close} ) {
            push @$stmts, ( ")" ) x $d->{parentheses_close};
        }
    }
    return $stmts;
}


sub __add_where_condition {
    my ( $sf, $data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $sb = App::DBBrowser::Table::Substatements->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @idx_changed_tables;
    my $old_idx_tbl = 0;

    TABLE: while ( 1 ) {
        my @pre = ( undef, $sf->{i}{confirm} );
        my $menu = [ @pre, map { '- ' . $_->{table} } @$data ];
        my $prompt = 'Where condition:';
        my $sql = {
            subselect_stmts => $sf->__get_sub_select_stmts( $data )
        };
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
                delete $data->[$idx]{where_stmt};
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
        $idx_tbl -= @pre;
        my $bu_stmt_types = [ @{$sf->{d}{stmt_types}} ];
        # begin stmt type select
        $sf->{d}{stmt_types} = [ 'Select' ]; # to see what is happening
        my $tmp_sql = {};
        $ax->reset_sql( $tmp_sql );
        $tmp_sql->{table} = $data->[$idx_tbl]{qt_table};
        $tmp_sql->{cols} = $data->[$idx_tbl]{qt_columns};           # cols for where
        $tmp_sql->{selected_cols} = $data->[$idx_tbl]{qt_columns};  # selected_cols for select
        my $ret = $sb->where( $tmp_sql );
        # end stmt type select
        $sf->{d}{stmt_types} = $bu_stmt_types;
        if ( defined $ret ) {
            $data->[$idx_tbl]{where_stmt} = delete $tmp_sql->{where_stmt};
            push @idx_changed_tables, $idx_tbl;
        }
    }
}


sub __add_parentheses {
    my ( $sf, $data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $sb = App::DBBrowser::Table::Substatements->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @idx_changed_tables;
    my $old_idx_tbl = 0;

    TABLE: while ( 1 ) {
        my @pre = ( undef, $sf->{i}{confirm} );
        my $reset_all = '  Reset all';
        my $menu = [ @pre, map('- ' . $_->{table}, @$data ) , $reset_all ];
        my $prompt = 'Parentheses:';
        my $sql = {
            subselect_stmts => $sf->__get_sub_select_stmts( $data )
        };
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
        $prompt .= $data->[$idx_tbl]{table} . ( ')' x ( $data->[$idx_tbl]{parentheses_close} // 0 ) ) . ':';
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
