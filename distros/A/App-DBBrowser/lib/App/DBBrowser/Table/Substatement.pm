package # hide from PAUSE
App::DBBrowser::Table::Substatement;

use warnings;
use strict;
use 5.016;

use List::MoreUtils qw( any uniq );

use Term::Choose         qw();
use Term::Choose::Util   qw();
use Term::Form::ReadLine qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions;
use App::DBBrowser::Table::Substatement::Aggregate;
use App::DBBrowser::Table::Substatement::Condition;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub __avail_cols {
    my ( $sf, $sql, $clause ) = @_;
    my $sa = App::DBBrowser::Table::Substatement::Aggregate->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $avail_aggr = $sa->available_aggregate_functions();
    my $aliases = $sf->{o}{alias}{'use_in_' . $clause} ? $sql->{alias} : {};
    my $cols = [];
    if ( $sql->{aggregate_mode} ) {
        if ( $clause eq 'select' ) {
            $cols = [ @{$sql->{group_by_cols}}, @$avail_aggr ];
        }
        elsif ( $clause eq 'where' ) {
            $cols = [ @{$sql->{columns}} ];
        }
        elsif ( $clause eq 'group_by' ) {
            $cols = [ @{$sql->{columns}} ];
            # Aliases added later to the group_by_stmt and not to the group_by_cols.
        }
        elsif ( $clause eq 'having' || $clause eq 'order_by') {
            $cols = [
                map { length $aliases->{$_} ? $aliases->{$_} : $_ }
                uniq @{$sql->{selected_cols}}, @{$sql->{group_by_cols}}
            ];
            $cols = [ reverse uniq( reverse @$cols, @$avail_aggr ) ];
        }
    }
    else {
        if ( $clause eq 'select' ) {
            $cols = [ @{$sql->{columns}} ];
        }
        elsif ( $clause eq 'where' ) {
            my @selected_cols = grep { ! /\)\s*OVER\s*\(/i } @{$sql->{selected_cols}};
            $cols = [ reverse uniq( reverse @selected_cols, @{$sql->{columns}} ) ];
        }
        elsif ( $clause eq 'group_by' ) {
            $cols = [ @{$sql->{columns}} ];
        }
        elsif ( $clause eq 'having' ) {
            $cols = [ @$avail_aggr ];
        }
        elsif ( $clause eq 'order_by' ) {
            my @selected = map { length $aliases->{$_} ? $aliases->{$_} : $_ } @{$sql->{selected_cols}};
            $cols = [ reverse uniq( reverse @selected, @{$sql->{columns}} ) ];
        }
    }
    return $cols;
}


sub select {
    my ( $sf, $sql ) = @_;
    my $clause = 'select';
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @pre = ( undef, $sf->{i}{ok} );
    if ( $sf->{o}{enable}{extended_cols} ) {
        push @pre, $sf->{i}{menu_addition};
    }
    my $cols = $sf->__avail_cols( $sql, $clause );
    my $menu = [ @pre, @$cols ];

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
            else {
                $sql->{alias} = {};
            }
            return;
        }
        if ( $menu->[$idx[0]] eq $sf->{i}{ok} ) {
            shift @idx;
            if ( @idx ) {
                $sf->__add_chosen_cols( $sql, $clause, [ @{$menu}[@idx] ] );
            }
            if ( ! @{$sql->{selected_cols}} && $sql->{aggregate_mode} ) { ##
                return;
            }
            $sql->{alias} = {
                map { $_ => $sql->{alias}{$_} } grep { length $sql->{alias}{$_} } @{$sql->{selected_cols}}
            };
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
    my $sa = App::DBBrowser::Table::Substatement::Aggregate->new( $sf->{i}, $sf->{o}, $sf->{d} );
    if ( $sql->{aggregate_mode} ) {
        my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $rx_groub_by_cols = join '|', map { quotemeta } @{$sql->{group_by_cols}};

        for my $aggr ( @$chosen_cols ) {
            my $prepared_aggr = $sa->get_prepared_aggr_func( $sql, $clause, $aggr );
            if ( ! length $prepared_aggr ) {
                next;
            }
            if ( $prepared_aggr !~ /^(?:$rx_groub_by_cols)\z/ ) {
                my $alias = $ax->alias( $sql, 'complex_cols_select', $prepared_aggr );
                if ( length $alias ) {
                    $sql->{alias}{$prepared_aggr} = $alias;
                }
            }
            push @{$sql->{selected_cols}}, $prepared_aggr;
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
    my $sc = App::DBBrowser::Table::Substatement::Condition->new( $sf->{i}, $sf->{o}, $sf->{d} );
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
        my $ok = $sc->read_and_add_value( $sql, $clause, $stmt, $col, $op );
        if ( ! $ok ) {
            $sql->{$stmt} = pop @bu;
            next COL;
        }
    }
}


sub where {
    my ( $sf, $sql ) = @_;
    my $clause = 'where';
    my $sc = App::DBBrowser::Table::Substatement::Condition->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $cols = $sf->__avail_cols( $sql, $clause );
    my $ret = $sc->add_condition( $sql, $clause, $cols );
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
    my $cols = $sf->__avail_cols( $sql, $clause );
    my $menu = [ @pre, @$cols ];

    GROUP_BY: while ( 1 ) {
        @{$sql->{selected_cols}} = uniq @{$sql->{group_by_cols}}, @{$sql->{selected_cols}};
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
                my $removed_col = pop @{$sql->{group_by_cols}};
                @{$sql->{selected_cols}} = grep { ! /^\Q$removed_col\E\z/ } @{$sql->{selected_cols}};
                next GROUP_BY;
            }
            if ( ! $bu_aggregate_mode ) {
                $sql->{selected_cols} = [ @$bu_selected_cols ];
                $sql->{order_by_stmt} = $bu_order_by_stmt;
                #$sql->{having_stmt} = '';
                $sql->{aggregate_mode} = 0;
            }
            elsif ( ! @{$sql->{selected_cols}} ) {
                $sql->{aggregate_mode} = 0;
            }
            return;
        }
        if ( $menu->[$idx[0]] eq $sf->{i}{ok} ) {
            shift @idx;
            push @{$sql->{group_by_cols}}, @{$menu}[@idx];
            if ( @{$sql->{group_by_cols}} ) {
                @{$sql->{selected_cols}} = uniq @{$sql->{group_by_cols}}, @{$sql->{selected_cols}};
            }
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
    my $sc = App::DBBrowser::Table::Substatement::Condition->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $cols = $sf->__avail_cols( $sql, $clause );
    my $ret = $sc->add_condition( $sql, $clause, $cols );
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
    my $cols = $sf->__avail_cols( $sql, $clause );

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
            my $sa = App::DBBrowser::Table::Substatement::Aggregate->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $col = $sa->get_prepared_aggr_func( $sql, $clause, $col );
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
    my $bu_limit = $sql->{bu_limit};
    if ( $use_limit ) {
        $sql->{limit_stmt} = "LIMIT";
        $sql->{limit_stmt} .= " " . $bu_limit if length $bu_limit;
    }
    else {
        $sql->{limit_stmt} = "FETCH NEXT";
        $sql->{limit_stmt} .= " " . $bu_limit . " ROWS ONLY" if length $bu_limit;
    }
    my $info = $ax->get_sql_info( $sql );
    # Choose_a_number
    my $limit = $tu->choose_a_number(
        $digits,
        { info => $info, cs_label => 'LIMIT: ', confirm => $sf->{i}{confirm}, back => $sf->{i}{back},
        default_number => $bu_limit }
    );
    if ( ! defined $limit ) {
        $sql->{limit_stmt} = '';
        delete $sql->{bu_limit};
        return;
    }
    if ( $use_limit ) {
        $sql->{limit_stmt} = "LIMIT " . $limit;
    }
    else {
        $sql->{limit_stmt} = "FETCH NEXT " . $limit . " ROWS ONLY";
    }
    $sql->{bu_limit} = $limit;
    return 1;


}


sub offset {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my ( $use_limit, $digits ) = $sf->__limit_and_offset_variables();
    my $bu_offset = $sql->{bu_offset};
    $sql->{offset_stmt} = "OFFSET";
    $sql->{offset_stmt} .= " " . $bu_offset if length $bu_offset;
    my $info = $ax->get_sql_info( $sql );
    # Choose_a_number
    my $offset = $tu->choose_a_number(
        $digits,
        { info => $info, cs_label => 'OFFSET: ', confirm => $sf->{i}{confirm}, back => $sf->{i}{back},
          default_number => $bu_offset }
    );
    if ( ! defined $offset ) {
        $sql->{offset_stmt} = '';
        delete $sql->{bu_offset};
        if ( ! $sql->{bu_limit} ) {
            $sql->{limit_stmt} = '';
        }
        return;
    }
    if ( $use_limit ) {
        $sql->{offset_stmt} = "OFFSET " . $offset;
    }
    else {
        $sql->{offset_stmt} = "OFFSET " . $offset . " ROWS";
    }
    $sql->{bu_offset} = $offset;
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



1;

__END__
