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
    my $sql = {};
    $ax->reset_sql( $sql );
    my $old_idx_tbl = 0;

    TABLE: while ( 1 ) {
        my $enough_tables = '  Enough TABLES';
        my $derived_table = '  Derived';
        my $cte_table     = '  Cte';
        my $where         = '  Where';
        my $parentheses   = '  Parentheses';
        my @pre  = ( undef, $enough_tables );
        my @post;
        push @post, $derived_table if $sf->{o}{enable}{u_derived};
        push @post, $cte_table     if $sf->{o}{enable}{u_cte};
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
        $sql->{subselect_stmts} = $sf->__get_sub_select_stmts( $data );
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
                my $removed_table = pop @$used_tables;
                pop @$data;
                if ( @{$sf->{d}{ctes}//[]} && $removed_table eq $sf->{d}{ctes}[-1]{table} ) {
                    pop @{$sf->{d}{ctes}};
                }
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
            $sf->__where_conditions( $sql, $data );
            next TABLE;
        }
        elsif ( $table eq $parentheses ) {
            $sf->__parentheses( $sql, $data );
            next TABLE;
        }

        elsif ( $table eq $derived_table ) {
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $sql->{subselect_stmts} = $sf->__get_sub_select_stmts( $data );
            $table = $sq->subquery( $sql );
            if ( ! defined $table ) {
                next TABLE;
            }
            $qt_table = $table;
            my $default_alias = 'p' . ( @$used_tables + 1 );
            my $alias = $ax->alias( $sql, 'derived_table', $qt_table, $default_alias );
            $qt_table .= " " . $ax->quote_alias( $alias );
        }
        elsif ( $table eq $cte_table ) {
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $sql->{subselect_stmts} = $sf->__get_sub_select_stmts( $data );
            $table = $sq->prepare_cte( $sql );
            if ( ! defined $table ) {
                next TABLE;
            }
            $qt_table = $table;
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
                if ( @{$sf->{d}{ctes}//[]} && $table eq $sf->{d}{ctes}[-1]{table} ) {
                    pop @{$sf->{d}{ctes}};
                }
                next TABLE;
            }
        }
        my $ok = $sf->__choose_table_columns( $sql, $data, $table, $qt_table, $operator );
        if ( ! $ok ) {
            if ( @{$sf->{d}{ctes}//[]} && $table eq $sf->{d}{ctes}[-1]{table} ) {
                pop @{$sf->{d}{ctes}};
            }
            next TABLE;
        }
        push @$used_tables, $table;
    }
    my $qt_columns = delete $data->[0]{cols};
    my $qt_aliases = delete $data->[0]{alias};
    $sql->{subselect_stmts} = $sf->__get_sub_select_stmts( $data );
    my $union_derived_table = $ax->get_stmt( $sql, 'Union', 'prepare' );
    my $union_alias = $ax->alias( $sql, 'derived_table', '', 't1' );
    $union_derived_table .= " " . $ax->quote_alias( $union_alias );
    return $union_derived_table, $qt_columns, $qt_aliases;
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
    my $prompt = sprintf 'Add %s with:', $table;
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
    my ( $sf, $sql, $data, $table, $qt_table, $operator ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    #my $privious_cols =  "'^'"; ##
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
        #push @pre, $privious_cols          if $next_idx; ##
        $sf->__cols_alias_sub_stmt( $data, $next_idx, $chosen_cols );
        $sql->{subselect_stmts} = $sf->__get_sub_select_stmts( $data );
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
                next COLUMNS;
            }
            $#$data = $next_idx - 1;
            return;
        }
        #if ( $choices[0] eq $privious_cols ) { ##
        #    $data->[$next_idx]{qt_columns} = $data->[$next_idx-1]{qt_columns};
        #    return 1;
        #}
        #els
        if ( $choices[0] eq $sf->{i}{ok} ) {
            shift @choices;
            push @$chosen_cols, map { { name => $_ } } @choices;
            if ( ! @$chosen_cols ) {
                $chosen_cols = [ map { { name => $_ } } @{$sf->{d}{col_names}{$table}} ];
            }
            $sf->__cols_alias_sub_stmt( $data, $next_idx, $chosen_cols );
            if ( $next_idx == 0 ) {
                $sf->__cols_alias_main_stmt( $data, $chosen_cols );
            }
            return 1;
        }
        elsif ( $choices[0] eq $sf->{i}{menu_addition} ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $sql->{cols} = $ax->quote_cols( $sf->{d}{col_names}{$table} );
            my $complex_col = $ext->column( $sql, 'Union' );
            $sql->{cols} = [];
            if ( ! defined $complex_col ) {
                next COLUMNS;
            }
            my $default = 'col_' . ( @$chosen_cols + 1 );
            my $alias = $ax->alias( $sql, 'select_complex_col', $complex_col, $default );
            push @bu_cols, [ @$chosen_cols ];
            push @$chosen_cols, { name => $complex_col, alias => $alias };
         }
        else {
            push @bu_cols, [ @$chosen_cols ];
            push @$chosen_cols, map { { name => $_ } } @choices;
         }
    }
}


sub __cols_alias_main_stmt {
    my ( $sf, $data, $chosen_cols ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    # column names in the result-set of a UNION are taken from the first query.
    for my $col ( @$chosen_cols ) {
        if ( length $col->{alias} ) {
            $data->[0]{alias}{$col->{name}} = $ax->quote_alias( $col->{alias} );
            push @{$data->[0]{cols}}, $col->{name};
        }
        else {
            push @{$data->[0]{cols}}, $ax->quote_column( $col->{name} );
        }
    }
    return;
}


sub __cols_alias_sub_stmt {
    my ( $sf, $data, $tbl_idx, $chosen_cols ) = @_;
    if ( ! @{$chosen_cols//[]} ) {
        $data->[$tbl_idx]{qt_columns} = [ '*' ];
        return;
    }
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $qt_cols = [];
    for my $col ( @$chosen_cols ) {
        if ( length $col->{alias} ) {
            # $col->{name} is scalar_functions or a subquery if it has an alias
            push @$qt_cols, $col->{name} . ' AS ' . $ax->quote_alias( $col->{alias} );
        }
        else {
            push @$qt_cols, $ax->quote_column( $col->{name} );
        }
    }
    $data->[$tbl_idx]{qt_columns} = $qt_cols;
    return;
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


sub __where_conditions {
    my ( $sf, $sql, $data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @idx_changed_tables;
    my $old_idx_tbl = 0;

    TABLE: while ( 1 ) {
        my @pre = ( undef, $sf->{i}{confirm} );
        my $menu = [ @pre, map { '- ' . $_->{table} } @$data ];
        my $prompt = 'Where condition:';
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
        my $ok = $sf->__add_where_stmt( $data, $idx_tbl );
        if ( $ok ) {
            push @idx_changed_tables, $idx_tbl;
        }
    }
}


sub __add_where_stmt {
    my ( $sf, $data, $idx_tbl ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sb = App::DBBrowser::Table::Substatements->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $bu_stmt_types = [ @{$sf->{d}{stmt_types}} ];
    $sf->{d}{stmt_types} = [ 'Select' ]; # to see what is happening
    my $table = $data->[$idx_tbl]{table};
    my $qt_table = $data->[$idx_tbl]{qt_table};
    my $columns = $sf->{d}{col_names}{$table};
    my $qt_columns = $ax->quote_cols( $columns );
    my $tmp_sql = {};
    $ax->reset_sql( $tmp_sql );
    $tmp_sql->{table} = $qt_table;
    $tmp_sql->{cols} = $qt_columns;           # cols for where
    $tmp_sql->{selected_cols} = $qt_columns;  # selected_cols for select
    my $ret = $sb->where( $tmp_sql );
    $sf->{d}{stmt_types} = $bu_stmt_types;
    if ( ! defined $ret ) {
        return;
    }
    $data->[$idx_tbl]{where_stmt} = delete $tmp_sql->{where_stmt};
    return 1;
}


sub __parentheses {
    my ( $sf, $sql, $data ) = @_;
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
