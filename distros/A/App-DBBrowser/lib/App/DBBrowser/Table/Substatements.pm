package # hide from PAUSE
App::DBBrowser::Table::Substatements;

use warnings;
use strict;
use 5.014;

use List::MoreUtils qw( any uniq );

use Term::Choose         qw();
use Term::Choose::Util   qw();
use Term::Form::ReadLine qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions;
use App::DBBrowser::Table::Substatements::Operators;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $d,
    };
    bless $sf, $class;
    my $driver = $sf->{i}{driver};
    my $group_concat = '';
    if ( $driver =~ /^(?:SQLite|mysql|MariaDB)\z/ ) {
        $group_concat = "GROUP_CONCAT(X)";
    }
    elsif ( $driver eq 'Pg' ) {
        $group_concat = "STRING_AGG(X)";
    }
    elsif ( $driver eq 'Firebird' ) {
        $group_concat = "LIST(X)";
    }
    elsif ( $driver =~ /^(?:DB2|Oracle)\z/ ) {
        $group_concat = "LISTAGG(X)";
    }
    my $avail_aggr = [ "COUNT(*)", "COUNT(X)", "SUM(X)", "AVG(X)", "MIN(X)", "MAX(X)" ];
    if ( $group_concat ) {
        push @$avail_aggr, $group_concat;
    }
    $sf->{i}{avail_aggr} = $avail_aggr;
    $sf->{i}{group_concat} = $group_concat =~ s/\(\X\)\z//r;
    return $sf;
}


sub select {
    my ( $sf, $sql ) = @_;
    my $clause = 'select';
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $menu = [];
    my @pre = ( undef, $sf->{i}{ok} );
    if ( $sf->{o}{enable}{extended_cols} ) {
        push @pre, $sf->{i}{menu_addition};
    }
    if ( $sql->{aggregate_mode} ) {
        $menu = [ @pre, @{$sf->{i}{avail_aggr}}, @{$sql->{group_by_cols}} ];
    }
    else {
        $menu = [ @pre, @{$sql->{columns}} ];
    }

    COLUMNS: while ( 1 ) {
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my @idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $info, meta_items => [ 0 .. $#pre - 1 ], no_spacebar => [ $#pre ],
              include_highlighted => 2, index => 1 }
        );
        $ax->print_sql_info( $info );
        if ( ! $idx[0] ) {
            if ( @{$sql->{selected_cols}} ) {
                pop @{$sql->{selected_cols}};
                next COLUMNS;
            }
            if ( $sql->{aggregate_mode} ) {
                $ax->reset_sql( $sql );
            }
            return;
        }
        if ( $menu->[$idx[0]] eq $sf->{i}{ok} ) {
            shift @idx;
            if ( @idx ) {
                $sf->__add_chosen_cols( $sql, $clause, [ @{$menu}[@idx] ] );
            }
            if ( ! @{$sql->{selected_cols}} && $sql->{aggregate_mode} ) { ##
                $ax->reset_sql( $sql );
                return;
            }
            return 1;
        }
        elsif ( $menu->[$idx[0]] eq $sf->{i}{menu_addition} ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_col = $ext->column( $sql, $clause );
            if ( ! defined $complex_col ) {
                next COLUMNS
            }
            elsif ( ref( $complex_col ) eq 'HASH' ) {
                $sql->{alias} = $complex_col;
            }
            else {
                my $alias = $ax->alias( $sql, 'complex_cols_select', $complex_col );
                if ( length $alias ) {
                    $sql->{alias}{$complex_col} = $alias;
                }
                push @{$sql->{selected_cols}}, $complex_col;
            }
        }
        else {
            $sf->__add_chosen_cols( $sql, $clause, [ @{$menu}[@idx] ] );
        }
    }
}


sub __add_chosen_cols {
    my ( $sf, $sql, $clause, $chosen_cols ) = @_;
    if ( $sql->{aggregate_mode} ) {
        my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $rx_groub_by_cols = join '|', map { quotemeta } @{$sql->{group_by_cols}};

        for my $aggr ( @$chosen_cols ) {
            my $prepared_aggr = $sf->get_prepared_aggr_func( $sql, $clause, $aggr );
            if ( ! length $prepared_aggr ) {
                next;
            }
            push @{$sql->{selected_cols}}, $prepared_aggr;
            if ( $prepared_aggr !~ /^(?:$rx_groub_by_cols)\z/ ) {
                my $alias = $ax->alias( $sql, 'complex_cols_select', $prepared_aggr );
                if ( length $alias ) {
                    $sql->{alias}{$prepared_aggr} = $alias;
                }
            }
        }
    }
    else {
        push @{$sql->{selected_cols}}, @$chosen_cols;
    }
}


sub distinct {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @pre = ( undef, $sf->{i}{ok} );

    DISTINCT: while ( 1 ) {
        my $menu = [ @pre, "DISTINCT", "ALL" ];
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $select_distinct = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $select_distinct ) {
            if ( $sql->{distinct_stmt} ) {
                $sql->{distinct_stmt} = '';
                next DISTINCT;
            }
            return;
        }
        elsif ( $select_distinct eq $sf->{i}{ok} ) {
            return 1;
        }
        $sql->{distinct_stmt} = ' ' . $select_distinct;
    }
}


sub set {
    my ( $sf, $sql ) = @_;
    my $clause = 'set';
    my $stmt = 'set_stmt';
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $so = App::DBBrowser::Table::Substatements::Operators->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $sql->{$stmt} = "SET";
    my @bu;
    my @pre = ( undef, $sf->{i}{ok} );

    COL: while ( 1 ) {
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $col = $tc->choose(
            [ @pre, @{$sql->{columns}} ],
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $col ) {
            if ( @bu ) {
                $sql->{$stmt} = pop @bu;
                next COL;
            }
            $sql->{$stmt} = '';
            return;
        }
        if ( $col eq $sf->{i}{ok} ) {
            if ( ! @bu ) {
                $sql->{$stmt} = '';
            }
            return 1;
        }
        push @bu, $sql->{$stmt};
        my $op = '=';
        if ( @bu == 1 ) {
            $sql->{$stmt} .= ' ' . $col . ' ' . $op;
        }
        else {
            $sql->{$stmt} .= ', ' . $col . ' ' . $op;
        }
        my $ok = $so->read_and_add_value( $sql, $clause, $stmt, $col, $op );
        if ( ! $ok ) {
            $sql->{$stmt} = pop @bu;
            next COL;
        }
    }
}


sub where {
    my ( $sf, $sql ) = @_;
    my $clause = 'where';
    my $cols = [ @{$sql->{columns}} ];
    my $ret = $sf->add_condition( $sql, $clause, $cols );
    return $ret;
}


sub group_by {
    my ( $sf, $sql ) = @_;
    my $clause = 'group_by';
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $bu_selected_cols = [ @{$sql->{selected_cols}} ];
    my $bu_order_by_stmt = $sql->{order_by_stmt};
    my $bu_aggregate_mode = $sql->{aggregate_mode} // 0;
    if ( ! $bu_aggregate_mode ) {
        $sql->{order_by_stmt} = '';
        $sql->{selected_cols} = [];
    }
    $sql->{aggregate_mode} = 1;
    my @pre = ( undef, $sf->{i}{ok} );
    if ( $sf->{o}{enable}{extended_cols} ) {
        push @pre, $sf->{i}{menu_addition};
    }
    my $menu = [ @pre, @{$sql->{columns}} ];
    my $aliases = $sf->{o}{alias}{use_in_group_by} ? $sql->{alias} : {};

    GROUP_BY: while ( 1 ) {
        $sql->{group_by_stmt} = "GROUP BY " . join ', ', map { length $aliases->{$_} ? $aliases->{$_} : $_ } @{$sql->{group_by_cols}};
#        @{$sql->{selected_cols}} = uniq @{$sql->{group_by_cols}}, @{$sql->{selected_cols}}; ##
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my @idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $info, meta_items => [ 0 .. $#pre - 1 ], no_spacebar => [ $#pre ],
              include_highlighted => 2, index => 1 }
        );
        $ax->print_sql_info( $info );
        if ( ! $idx[0] ) {
            if ( @{$sql->{group_by_cols}} ) {
                my $removed = pop @{$sql->{group_by_cols}};
                $bu_selected_cols = [ grep { ! /(?:^|\W)\Q$removed\E(?:\W|\z)/ } @$bu_selected_cols ]; ##
                next GROUP_BY;
            }
            if ( ! $bu_aggregate_mode ) {
                $sql->{selected_cols} = [ @$bu_selected_cols ];
                $sql->{order_by_stmt} = $bu_order_by_stmt;
                #$sql->{having_stmt} = '';
                $sql->{aggregate_mode} = 0;
            }
            $sql->{group_by_stmt} = '';
            return;
        }
        if ( $menu->[$idx[0]] eq $sf->{i}{ok} ) {
            shift @idx;
            push @{$sql->{group_by_cols}}, @{$menu}[@idx];
            if ( @{$sql->{group_by_cols}} ) {
                $sql->{group_by_stmt} = "GROUP BY " . join ', ', map { length $aliases->{$_} ? $aliases->{$_} : $_ } @{$sql->{group_by_cols}};
                @{$sql->{selected_cols}} = uniq @{$sql->{group_by_cols}}, @{$sql->{selected_cols}};
            }
            else {
                $sql->{group_by_stmt} = '';
            }
            $sql->{aggregate_mode} = 1;
            return 1;
        }
        elsif ( $menu->[$idx[0]] eq $sf->{i}{menu_addition} ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_col = $ext->column( $sql, $clause );
            if ( defined $complex_col ) {
                my $alias = $ax->alias( $sql, 'complex_cols_select', $complex_col );
                # this alias is used in select
                if ( length $alias ) {
                    $sql->{alias}{$complex_col} = $alias;
                }
                push @{$sql->{group_by_cols}}, $complex_col;
            }
            next GROUP_BY;
        }
        push @{$sql->{group_by_cols}}, @{$menu}[@idx];
    }
}


sub having {
    my ( $sf, $sql ) = @_;
    my $clause = 'having';
    my $cols = [ uniq @{$sql->{selected_cols}}, @{$sql->{group_by_cols}}, @{$sf->{i}{avail_aggr}} ];
    if ( $sf->{o}{alias}{use_in_having} ) {
        my $aliases = $sql->{alias};
        $cols = [ map { length $aliases->{$_} ? $aliases->{$_} : $_ } @$cols ];
    }
    my $ret = $sf->add_condition( $sql, $clause, $cols );
    return $ret;
}


sub order_by {
    my ( $sf, $sql ) = @_;
    my $clause = 'order_by';
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @pre = ( undef, $sf->{i}{ok} );
    if ( $sf->{o}{enable}{extended_cols} ) {
        push @pre, $sf->{i}{menu_addition};
    }
    my $cols;
    if ( $sql->{aggregate_mode} ) {
        $cols = [ uniq @{$sql->{selected_cols}}, @{$sql->{group_by_cols}}, @{$sf->{i}{avail_aggr}} ];
    }
    else {
        $cols = [ uniq @{$sql->{selected_cols}}, @{$sql->{columns}} ];
    }
    if ( $sf->{o}{alias}{use_in_having} ) {
        my $aliases = $sql->{alias};
        $cols = [ map { length $aliases->{$_} ? $aliases->{$_} : $_ } @$cols ];
    }

    ORDER_BY: while ( 1 ) {
        $sql->{order_by_stmt} = "ORDER BY " . join ',', @{$sql->{order_by_cols}};
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $col = $tc->choose(
            [ @pre, @$cols ],
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $col ) {
            if ( @{$sql->{order_by_cols}} ) {
                pop @{$sql->{order_by_cols}};
                next ORDER_BY;
            }
            $sql->{order_by_stmt} = '';
            return
        }
        if ( $col eq $sf->{i}{ok} ) {
            if ( ! @{$sql->{order_by_cols}} ) {
                $sql->{order_by_stmt} = '';
            }
            return 1;
        }
        elsif ( $col eq $sf->{i}{menu_addition} ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_col = $ext->column( $sql, $clause );
            if ( ! defined $complex_col ) {
                next ORDER_BY;
            }
            $col = $complex_col;
        }
        elsif ( $sql->{aggregate_mode} ) {
            $col = $sf->get_prepared_aggr_func( $sql, $clause, $col );
            if ( ! length $col ) {
                next ORDER_BY;
            }
        }
        push @{$sql->{order_by_cols}}, $col;
        $sql->{order_by_stmt} = "ORDER BY " . join ',', @{$sql->{order_by_cols}};
        $info = $ax->get_sql_info( $sql );
        # Choose
        my $direction = $tc->choose(
            [ undef, "ASC", "DESC" ],
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $direction ){
            pop @{$sql->{order_by_cols}};
            next ORDER_BY;
        }
        else {
            $sql->{order_by_cols}[-1] .= ' ' . $direction;
        }
    }
}


sub limit {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my ( $use_limit, $digits ) = $sf->__limit_and_offset_variables();
    my $bu_limit_stmt = $sql->{limit_stmt};
    if ( $use_limit ) {
        $sql->{limit_stmt} = "LIMIT";
    }
    else {
        $sql->{limit_stmt} = "FETCH NEXT";
    }
    my $info = $ax->get_sql_info( $sql );
    # Choose_a_number
    my $limit = $tu->choose_a_number(
        $digits,
        { info => $info, cs_label => 'LIMIT: ', confirm => $sf->{i}{confirm}, back => $sf->{i}{back} }
    );
    if ( ! defined $limit ) {
        $sql->{limit_stmt} = $bu_limit_stmt;
        return;
    }
    if ( $use_limit ) {
        $sql->{limit_stmt} = "LIMIT " . $limit;
    }
    else {
        $sql->{limit_stmt} = "FETCH NEXT " . $limit . " ROWS ONLY";
    }
    return 1;


}


sub offset {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my ( $use_limit, $digits ) = $sf->__limit_and_offset_variables();
    my $bu_offset_stmt = $sql->{offset_stmt};
    $sql->{offset_stmt} = "OFFSET";
    my $info = $ax->get_sql_info( $sql );
    # Choose_a_number
    my $offset = $tu->choose_a_number(
        $digits,
        { info => $info, cs_label => 'OFFSET: ', confirm => $sf->{i}{confirm}, back => $sf->{i}{back} }
    );
    if ( ! defined $offset ) {
        $sql->{offset_stmt} = $bu_offset_stmt;
        return;
    }
    if ( $use_limit ) {
        $sql->{offset_stmt} = "OFFSET " . $offset;
    }
    else {
        $sql->{offset_stmt} = "OFFSET " . $offset . " ROWS";
    }
    # Informix: no offset
    if ( ! $sql->{limit_stmt} ) {
        my $driver = $sf->{i}{driver};
        # SQLite/mysql/MariaDB: no offset without limit
        $sql->{limit_stmt} = "LIMIT " . '9223372036854775807'  if $driver eq 'SQLite';   # 2 ** 63 - 1
        $sql->{limit_stmt} = "LIMIT " . '18446744073709551615' if $driver =~ /^(?:mysql|MariaDB)\z/;    # 2 ** 64 - 1
        # MySQL 8.0 Reference Manual - SQL Statements/Data Manipulation Statements/Select Statement/Limit clause:
        #    SELECT * FROM tbl LIMIT 95,18446744073709551615;   -> all rows from the 95th to the last
    }
    return 1;
}


sub __limit_and_offset_variables {
    my ( $sf ) = @_;
    my $use_limit = $sf->{i}{driver} =~ /^(?:SQLite|mysql|MariaDB|Pg|Informix)\z/ ? 1 : 0;
    my $max_digits = 7;
    return $use_limit, $max_digits;
}


sub add_condition {
    my ( $sf, $sql, $clause, $cols, $r_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $so = App::DBBrowser::Table::Substatements::Operators->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $AND_OR = '';
    my @bu;
    my $stmt;
    if ( $clause =~ s/_(when)\z//i ) {
        $stmt = 'when_stmt';
        $sql->{$stmt} = uc $1;
    }
    elsif( $clause =~ /^on\z/i ) {
        $stmt = lc( $clause ) . '_stmt';
        $sql->{$stmt} = uc $clause;
    }
    else {
        $stmt = lc( $clause ) . '_stmt';
        @bu = @{$sql->{'bu_' . $stmt}//[]};
        $sql->{$stmt} = pop ( @bu ) // uc $clause;
    }
    my @pre = ( undef, $sf->{i}{ok} );
    if ( $sf->{o}{enable}{extended_cols} ) {
        push @pre, $sf->{i}{menu_addition};
    }

    COL: while ( 1 ) {
        my $info = $so->info_add_condition( $sql, $clause, $stmt, $r_data );
        # Choose
        my $col = $tc->choose(
            [ @pre, @$cols ],
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $col ) {
            if ( @bu ) {
                $sql->{$stmt} = pop @bu;
                next COL;
            }
            $sql->{'bu_' . $stmt} = [];
            $sql->{$stmt} = '';
            return;
        }
        if ( $col eq $sf->{i}{ok} ) {
            if ( ! @bu ) {
                $sql->{$stmt} = '';
            }
            else {
                push @bu, $sql->{$stmt};
            }
            $sql->{'bu_' . $stmt} = [ @bu ];
            return 1;
        }
        if ( $col eq $sf->{i}{menu_addition} ) {
            $r_data->[-1][-1] = $sql->{$stmt} if @{$r_data//[]};
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_col = $ext->column( $sql, $clause, $r_data, { add_parentheses => 1 } );
            if ( ! defined $complex_col ) {
                next COL;
            }
            $col = $complex_col;
        }
        push @bu, $sql->{$stmt};

        if ( $col eq ')' ) {
            $sql->{$stmt} .= ")";
            next COL;
        }
        if ( @bu > 1 && $sql->{$stmt} !~ /\(\z/ ) {
            my $info = $so->info_add_condition( $sql, $clause, $stmt, $r_data );
            # Choose
            my $choice = $tc->choose(
                [ undef, "AND", "OR" ],
                { %{$sf->{i}{lyt_h}}, info => $info }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $choice ) {
                $sql->{$stmt} = pop @bu;
                next COL;
            }
            $AND_OR = ' ' . $choice;
        }
        else {
            $AND_OR = '';
        }
        if ( $col eq '(' ) {
            $sql->{$stmt} .= $AND_OR . " (";
            next COL;
        }
        if ( $clause eq 'having' ) {
            $col = $sf->get_prepared_aggr_func( $sql, $clause, $col );
            if ( ! defined $col ) {
                $sql->{$stmt} = pop @bu;
                next COL;
            }
        }
        if ( $sql->{$stmt} =~ /\(\z/ ) {
            $sql->{$stmt} .= $col;
        }
        else {
            $sql->{$stmt} .= $AND_OR . ' ' . $col;
        }
        my $ok = $so->add_operator_and_value( $sql, $clause, $stmt, $col, $r_data );
        if ( ! $ok ) {
            $sql->{$stmt} = pop @bu;
            next COL;
        }
    }
}


sub get_prepared_aggr_func {
    my ( $sf, $sql, $clause, $aggr, $r_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $prepared_aggr;
    if ( $aggr !~ /\(X\)\z/ ) {
        $prepared_aggr = $aggr;
    }
    else {
        $aggr =~ s/\(X\)\z//;
        my @pre = ( undef );
        if ( $sf->{o}{enable}{extended_cols} ) {
            push @pre, $sf->{i}{menu_addition};
        }
        my $tmp_sql = $ax->clone_data( $sql );
        $prepared_aggr = $aggr . "(";

        COLUMN: while ( 1 ) {
            my $info = $sf->__prepared_aggr_info( $sql, $tmp_sql, $clause, $prepared_aggr, $r_data );
            # Choose
            my $col = $tc->choose(
                [ @pre, @{$tmp_sql->{columns}} ],
                { %{$sf->{i}{lyt_h}}, info => $info }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $col ) {
                return;
            }
            elsif ( $col eq $sf->{i}{menu_addition} ) {
                my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
                my $bu_aggregate_mode = $tmp_sql->{aggregate_mode};
                # use normal columns within aggregate functions
                $tmp_sql->{aggregate_mode} = 0;
                my $complex_col = $ext->column( $tmp_sql, $clause, $r_data );
                $tmp_sql->{aggregate_mode} = $bu_aggregate_mode;
                if ( ! defined $complex_col ) {
                    next COLUMN;
                }
                $col = $complex_col;
            }
            if ( $aggr =~ /^COUNT\z/i ) {
                my $is_distinct = $sf->__is_distinct( $sql, $tmp_sql, $clause, $prepared_aggr . $col, $r_data );
                if ( ! defined $is_distinct ) {
                    next COLUMN;
                }
                if ( $is_distinct ) {
                    $prepared_aggr .= "DISTINCT $col)";
                }
                else {
                    $prepared_aggr .= "$col)";
                }
            }
            elsif ( $aggr =~ /^$sf->{i}{group_concat}\z/ ) {
                my $bu_prepared_aggr = $prepared_aggr;
                $prepared_aggr = $sf->__opt_group_concat( $sql, $tmp_sql, $clause, $col, $prepared_aggr, $r_data );
                if ( ! defined $prepared_aggr ) {
                    $prepared_aggr = $bu_prepared_aggr;
                    next COLUMN;
                }
            }
            else {
                $prepared_aggr .= "$col)";
            }
            last COLUMN;
        }

    }
    return $prepared_aggr;
}


sub __is_distinct {
    my ( $sf, $sql, $tmp_sql, $clause, $prepared_aggr, $r_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my ( $all, $distinct ) = ( 'ALL', 'DISTINCT' );
    my $info = $sf->__prepared_aggr_info( $sql, $tmp_sql, $clause, $prepared_aggr, $r_data );
    # Choose
    my $choice = $tc->choose(
        [ undef, $all, $distinct ],
        { %{$sf->{i}{lyt_h}}, info => $info }
    );
    $ax->print_sql_info( $info );
    if ( ! defined $choice ) {
        return;
    }
    elsif ( $choice eq $all ) {
        return 0;
    }
    elsif ( $choice eq $distinct ) {
        return 1;
    }
}


sub __prepared_aggr_info {
    my ( $sf, $sql, $tmp_sql, $clause, $prepared_aggr, $r_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $info;
    if ( @{$r_data//[]} ) {
        my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
        $r_data->[-1] = [ 'aggr', $prepared_aggr ];
        $info = $ax->get_sql_info( $tmp_sql ) . $ext->nested_func_info( $r_data );
    }
    else {
        if ( $clause =~ /^(?:select|aggregate)\z/ ) {
            $tmp_sql->{selected_cols} = [ @{$sql->{selected_cols}}, $prepared_aggr ];
        }
        else {
            # having, order_by
            $tmp_sql->{$clause . '_stmt'} = $sql->{$clause . '_stmt'} . " " . $prepared_aggr;
        }
        $info = $ax->get_sql_info( $tmp_sql );
    }
    return $info;
}


sub __opt_group_concat {
    my ( $sf, $sql, $tmp_sql, $clause, $col, $prepared_aggr, $r_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $is_distinct = $sf->__is_distinct( $sql, $tmp_sql, $clause, $prepared_aggr . $col, $r_data );
    if ( ! defined $is_distinct ) {
        return;
    }
    if ( $is_distinct ) {
        $prepared_aggr .= "DISTINCT ";
    }
    if ( $sf->{i}{driver} eq 'Pg' ) {
        $prepared_aggr .= $ax->pg_column_to_text( $sql, $col );
    }
    else {
        $prepared_aggr .= $col;
    }
    my $sep = ',';
    my $order_by_stmt;
    if (      $sf->{i}{driver} =~ /^(?:mysql|MariaDB|Pg)\z/
         || ( $sf->{i}{driver} =~ /^(?:DB2|Oracle)\z/ && ! $is_distinct )
    ) {
        my $read = ':Read';
        if ( $sf->{i}{driver} eq 'Pg' && $is_distinct ) {
            $col = $ax->pg_column_to_text( $sql, $col );
        }
        my @choices = (
            "$col ASC",
            "$col DESC",
            $read,
        );
        my $menu = [ undef, @choices ];
        my $info = $sf->__prepared_aggr_info( $sql, $tmp_sql, $clause, $prepared_aggr, $r_data );
        # Choose
        my $choice = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $info, undef => '<<', prompt => 'Order:' }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $choice ) {
            # default order
        }
        elsif ( $choice eq $read ) {
            my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
            my $history = [
                join( ', ', @{$tmp_sql->{columns}} ),
                join( ' DESC, ', @{$tmp_sql->{columns}} ) . ' DESC',
            ];
            my $info = $sf->__prepared_aggr_info( $sql, $tmp_sql, $clause, $prepared_aggr, $r_data );
            # Readline
            $order_by_stmt = $tr->readline(
                'ORDER BY ',
                { info => $info, history => $history }
            );
            $ax->print_sql_info( $info );
            if ( length $order_by_stmt ) {
                $order_by_stmt = "ORDER BY " . $order_by_stmt;
            }
        }
        else {
            $order_by_stmt = "ORDER BY " . $choice;
        }
    }
    if ( $sf->{i}{driver} eq 'SQLite' ) {
        if ( $is_distinct ) {
            # https://sqlite.org/forum/info/221c2926f5e6f155
            # SQLite: GROUP_CONCAT with DISTINCT and custom seperator does not work
            # default separator is ','
            $prepared_aggr .= ")";
        }
        else {
            $prepared_aggr .= ",'$sep')";
        }
    }
    elsif ( $sf->{i}{driver} =~ /^(?:mysql|MariaDB)\z/ ) {
        if ( $order_by_stmt ) {
            $prepared_aggr .= " $order_by_stmt SEPARATOR '$sep')";
        }
        else {
            $prepared_aggr .= " SEPARATOR '$sep')";
        }
    }
    elsif ( $sf->{i}{driver} eq 'Pg' ) {
        # Pg, STRING_AGG:
        # separator mandatory
        # expects text type as argument
        # with DISTINCT the STRING_AGG col and the ORDER BY col must be identical
        if ( $order_by_stmt ) {
            $prepared_aggr .= ",'$sep' $order_by_stmt)";
        }
        else {
            $prepared_aggr .= ",'$sep')";
        }
    }
    elsif ( $sf->{i}{driver} eq 'Firebird' ) {
        $prepared_aggr .= ",'$sep')";
    }
    elsif ( $sf->{i}{driver} =~ /^(?:DB2|Oracle)\z/ ) {
        # No order with distinct
        # DB2 codes: error code -214 - error caused by:
        # DISTINCT is specified in the SELECT clause, and a column name or sort-key-expression in the
        # ORDER BY clause cannot be matched exactly with a column name or expression in the select list.
        if ( $order_by_stmt ) {
            $prepared_aggr .= ",'$sep') WITHIN GROUP ($order_by_stmt)";
        }
        else {
            $prepared_aggr .= ",'$sep')";
        }
    }
    else {
        $prepared_aggr .= ")";
    }
    return $prepared_aggr;
}



1;

__END__
