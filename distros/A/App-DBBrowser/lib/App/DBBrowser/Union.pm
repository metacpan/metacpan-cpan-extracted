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
    $sql->{ctes} = [ @{$sf->{d}{cte_history}} ];
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
            my $default_alias = 'p' . ( @$used_tables + 1 ); ##
            my $alias = $ax->alias( $sql, 'derived_table', $qt_table, $default_alias );
            $qt_table .= " " . $ax->quote_alias( $alias );
        }
        elsif ( $table eq $cte_table ) {
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $sql->{subselect_stmts} = $sf->__get_sub_select_stmts( $data );
            $table = $sq->choose_cte( $sql );
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
                next TABLE;
            }
        }
        my $ok = $sf->__choose_table_columns( $sql, $data, $table, $qt_table, $operator ); ##
        if ( ! $ok ) {
            next TABLE;
        }
        push @$used_tables, $table;
    }
    $sql->{subselect_stmts} = $sf->__get_sub_select_stmts( $data );
    my $union_derived_table = $ax->get_stmt( $sql, 'Union', 'prepare' );
    my $union_alias = $ax->alias( $sql, 'derived_table', '', 'u1' );
    $union_derived_table .= " " . $ax->quote_alias( $union_alias );
    return $union_derived_table, $sql->{ctes};
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
    my $idx = @$data;
    my @bu;
    ( my $column_names, undef ) = $ax->column_names_and_types( $qt_table, $sql->{ctes} );
    if ( ! defined $column_names ) {
        return;
    }
    my $qt_columns = $ax->quote_cols( $column_names );
    $data->[$idx] = {
        qt_table => $qt_table, table => $table, qt_columns => $qt_columns, chosen_qt_cols => [], qt_alias => {}
    };
    if ( $operator ) {
        $data->[$idx]{operator} = $operator;
    }

    COLUMNS: while ( 1 ) {
        my @pre = ( undef, $sf->{i}{ok} );
        push @pre, $sf->{i}{menu_addition} if $sf->{o}{enable}{extended_cols};
        $sql->{subselect_stmts} = $sf->__get_sub_select_stmts( $data );
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my @choices = $tc->choose(
            [ @pre, @$qt_columns ],
            { %{$sf->{i}{lyt_h}}, info => $info, prompt => 'Columns:', meta_items => [ 0 .. $#pre ],
              include_highlighted => 2 }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $choices[0] ) {
            if ( @bu ) {
                $data->[$idx] = pop @bu;
                next COLUMNS;
            }
            $#$data = $idx - 1;
            return;
        }
        if ( $choices[0] eq $sf->{i}{ok} ) {
            shift @choices;
            push @{$data->[$idx]{chosen_qt_cols}}, @choices;
            if ( ! @{$data->[$idx]{chosen_qt_cols}} ) {
                $data->[$idx]{chosen_qt_cols} = $qt_columns;
            }
            return 1;
        }
        elsif ( $choices[0] eq $sf->{i}{menu_addition} ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $bu_sql = $ax->clone_data( $sql );
            $sql->{columns} = [ @$qt_columns  ];
            $sql->{selected_cols} = [ @{$data->[$idx]{chosen_qt_cols}} ];
            $sql->{alias} = $ax->clone_data( $data->[$idx]{qt_alias} );
            my $complex_col = $ext->column( $sql, 'select' );
            $sql = $bu_sql;
            if ( ! defined $complex_col ) {
                next COLUMNS;
            }
            elsif ( ref( $complex_col ) eq 'HASH' ) {
                $data->[$idx]{qt_alias} = $complex_col;
            }
            else {
                my $default = 'col_' . ( @{$data->[$idx]{chosen_qt_cols}} + 1 );
                my $alias = $ax->alias( $sql, 'complex_cols_select', $complex_col, $default );
                push @bu, $ax->clone_data( $data->[$idx] );
                push @{$data->[$idx]{chosen_qt_cols}}, $complex_col;
                $data->[$idx]{qt_alias}{$complex_col} = $ax->quote_alias( $alias );
            }
        }
        else {
            push @bu, $ax->clone_data( $data->[$idx] );
            push @{$data->[$idx]{chosen_qt_cols}}, @choices;
        }
    }
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

        my $qt_columns = $d->{chosen_qt_cols};
        if ( ! @$qt_columns ) {
            $qt_columns = [ '*' ];
        }
        else {
            # it is a scalar_functions or a subquery if it has an alias
            $qt_columns = [ map { length $d->{qt_alias}{$_} ? $_ . ' AS ' . $d->{qt_alias}{$_} : $_ } @$qt_columns ];
        }
        my $select = "SELECT " . join( ', ', @$qt_columns ) . " FROM " . $d->{qt_table};
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
    my $qt_table = $data->[$idx_tbl]{qt_table};
    my $qt_columns = $data->[$idx_tbl]{qt_columns};
    my $tmp_sql = {};
    $ax->reset_sql( $tmp_sql );
    $tmp_sql->{table} = $qt_table;
    $tmp_sql->{columns} = $qt_columns;           # 'cols' required in WHERE
    $tmp_sql->{selected_cols} = $qt_columns;  # 'selected_cols' required in SELECT
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
