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
    my $avail_aggr = [ "AVG(X)", "COUNT(X)", "COUNT(*)", "MAX(X)", "MIN(X)", "SUM(X)" ];
    if ( $group_concat ) {
        push @$avail_aggr, $group_concat;
#        $group_concat =~ s/\(\X\)\z//;
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
        $menu = [ @pre, @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}} ];
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
            #if ( $sql->{aggregate_mode} ) { ##
            #    $ax->reset_sql( $sql );
            #    $sql->{aggregate_mode} = 0;
            #}
            return;
        }
        if ( $menu->[$idx[0]] eq $sf->{i}{ok} ) {
            shift @idx;
            if ( @idx ) {
                push @{$sql->{selected_cols}}, @{$menu}[@idx];
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
                my $qt_alias = $ax->alias( $sql, 'complex_cols_select', $complex_col );
                if ( length $qt_alias ) {
                    $sql->{alias}{$complex_col} = $qt_alias;
                }
                push @{$sql->{selected_cols}}, $complex_col;
            }
        }
        else {
            push @{$sql->{selected_cols}}, @{$menu}[@idx];
        }
    }
}


sub distinct {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @pre = ( undef, $sf->{i}{ok} );

    DISTINCT: while ( 1 ) {
        my $menu = [ @pre, "ALL", "DISTINCT" ];
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


sub aggregate {
    my ( $sf, $sql ) = @_;
    my $clause = 'aggregate';
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $bu_selected_cols = [ @{$sql->{selected_cols}} ];
    $sql->{selected_cols} = [];
    my $bu_aggregate_mode = $sql->{aggregate_mode} // 0;
    $sql->{aggregate_mode} = 1;

    AGGREGATE: while ( 1 ) {
        my @pre = ( undef, $sf->{i}{ok} );
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $aggr = $tc->choose(
            [ @pre, @{$sf->{i}{avail_aggr}} ],
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $aggr ) {
            if ( @{$sql->{aggr_cols}} ) {
                my $aggr = pop @{$sql->{aggr_cols}};
                $bu_selected_cols = [ grep { ! /\b\Q$aggr\E(?:\W|\z)/ } @$bu_selected_cols ]; ##
                delete $sql->{alias}{$aggr};
                next AGGREGATE;
            }
            if ( ! @{$sql->{group_by_cols}} ) {
                $sql->{aggregate_mode} = 0;
                $sql->{having_stmt} = '' if $sql->{having_stmt};
            }
            if ( $sql->{aggregate_mode} == $bu_aggregate_mode ) {
                $sql->{selected_cols} = [ @$bu_selected_cols ];
            }
            else {
                $sql->{order_by_stmt} = '';
            }
            return;
        }
        if ( $aggr eq $sf->{i}{ok} ) {
            if ( ! @{$sql->{aggr_cols}} && ! @{$sql->{group_by_cols}} ) {
                $sql->{aggregate_mode} = 0;
                $sql->{having_stmt} = '' if $sql->{having_stmt};
            }
            if ( $sql->{aggregate_mode} == $bu_aggregate_mode ) {
                $sql->{selected_cols} = [ @$bu_selected_cols ];
            }
            else {
                $sql->{order_by_stmt} = '';
            }
            return 1;
        }
        my $prepared_aggr = $sf->get_prepared_aggr_func( $sql, $clause, $aggr );
        if ( ! defined $prepared_aggr ) {
            next AGGREGATE;
        }
        push @{$sql->{aggr_cols}}, $prepared_aggr;
        my $qt_alias = $ax->alias( $sql, 'complex_cols_select', $prepared_aggr );
        if ( length $qt_alias ) {
            $sql->{alias}{$prepared_aggr} = $qt_alias;
        }
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
        my $qt_col = $tc->choose(
            [ @pre, @{$sql->{columns}} ],
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $qt_col ) {
            if ( @bu ) {
                $sql->{$stmt} = pop @bu;
                next COL;
            }
            $sql->{$stmt} = '';
            return;
        }
        if ( $qt_col eq $sf->{i}{ok} ) {
            if ( ! @bu ) {
                $sql->{$stmt} = '';
            }
            return 1;
        }
        push @bu, $sql->{$stmt};
        my $op = '=';
        if ( @bu == 1 ) {
            $sql->{$stmt} .= ' ' . $qt_col . ' ' . $op;
        }
        else {
            $sql->{$stmt} .= ', ' . $qt_col . ' ' . $op;
        }
        my $ok = $so->read_and_add_value( $sql, $clause, $stmt, $qt_col, $op );
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
    $sql->{selected_cols} = [];
    my $bu_aggregate_mode = $sql->{aggregate_mode} // 0;
    $sql->{aggregate_mode} = 1;
    my @pre = ( undef, $sf->{i}{ok} );
    if ( $sf->{o}{enable}{extended_cols} ) {
        push @pre, $sf->{i}{menu_addition};
    }
    my $menu = [ @pre, @{$sql->{columns}} ];
    my $aliases = $sf->{o}{alias}{use_in_group_by} ? $sql->{alias} : {};

    GROUP_BY: while ( 1 ) {
        $sql->{group_by_stmt} = "GROUP BY " . join ', ', map { length $aliases->{$_} ? $aliases->{$_} : $_ } @{$sql->{group_by_cols}};
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
            if ( ! @{$sql->{aggr_cols}} ) {
                $sql->{aggregate_mode} = 0;
                $sql->{having_stmt} = '' if $sql->{having_stmt};
            }
            if ( $sql->{aggregate_mode} == $bu_aggregate_mode ) {
                $sql->{selected_cols} = [ @$bu_selected_cols ];
            }
            else {
                $sql->{order_by_stmt} = '';
            }
            $sql->{group_by_stmt} = '';
            return;
        }
        if ( $menu->[$idx[0]] eq $sf->{i}{ok} ) {
            shift @idx;
            push @{$sql->{group_by_cols}}, @{$menu}[@idx];
            if ( ! @{$sql->{aggr_cols}} && ! @{$sql->{group_by_cols}} ) {
                $sql->{aggregate_mode} = 0;
                $sql->{having_stmt} = '' if $sql->{having_stmt};
            }
            if ( $sql->{aggregate_mode} == $bu_aggregate_mode ) {
                $sql->{selected_cols} = [ @$bu_selected_cols ];
            }
            else {
                $sql->{order_by_stmt} = '';
            }
            if ( @{$sql->{group_by_cols}} ) {
                $sql->{group_by_stmt} = "GROUP BY " . join ', ', map { length $aliases->{$_} ? $aliases->{$_} : $_ } @{$sql->{group_by_cols}};
            }
            else {
                $sql->{group_by_stmt} = '';
            }
            return 1;
        }
        elsif ( $menu->[$idx[0]] eq $sf->{i}{menu_addition} ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_col = $ext->column( $sql, $clause );
            if ( defined $complex_col ) {
                my $qt_alias = $ax->alias( $sql, 'complex_cols_select', $complex_col );
                # this alias is used in select
                if ( length $qt_alias ) {
                    $sql->{alias}{$complex_col} = $qt_alias;
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
    my $aliases = $sf->{o}{alias}{use_in_having} ? $sql->{alias} : {};
    my $cols = [ uniq(
            map( length $aliases->{$_} ? $aliases->{$_} : $_, @{$sql->{aggr_cols}} ),
            @{$sf->{i}{avail_aggr}}
        )
    ];
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
    my $aliases = $sf->{o}{alias}{use_in_order_by} ? $sql->{alias} : {};
    my @cols;
    if ( $sql->{aggregate_mode} ) {
        @cols = uniq(
            map( length $aliases->{$_} ? $aliases->{$_} : $_, @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}} ),
            @{$sf->{i}{avail_aggr}}
        );
    }
    else {
        @cols = uniq(
            map( length $aliases->{$_} ? $aliases->{$_} : $_, @{$sql->{selected_cols}} ),
            @{$sql->{columns}}
        );
    }
    my @bu = @{$sql->{bu_order_by}//[]};
    $sql->{order_by_stmt} = pop ( @bu ) // "ORDER BY";

    ORDER_BY: while ( 1 ) {
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $qt_col = $tc->choose(
            [ @pre, @cols ],
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $qt_col ) {
            if ( @bu ) {
                $sql->{order_by_stmt} = pop @bu;
                next ORDER_BY;
            }
            $sql->{bu_order_by} = [];
            $sql->{order_by_stmt} = '';
            return
        }
        if ( $qt_col eq $sf->{i}{ok} ) {
            if ( ! @bu ) {
                $sql->{order_by_stmt} = '';
            }
            else {
                push @bu, $sql->{order_by_stmt};
            }
            $sql->{bu_order_by} = [ @bu ]; ##
            return 1;
        }
        elsif ( $qt_col eq $sf->{i}{menu_addition} ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_col = $ext->column( $sql, $clause );
            if ( ! defined $complex_col ) {
                #if ( @bu ) {
                #    $sql->{order_by_stmt} = pop @bu;
                #}
                next ORDER_BY;
            }
            $qt_col = $complex_col;
        }
        elsif ( $sql->{aggregate_mode} ) {
            $qt_col = $sf->get_prepared_aggr_func( $sql, $clause, $qt_col );
        }
        push @bu, $sql->{order_by_stmt};
        $sql->{order_by_stmt} .= ( @bu == 1 ? ' ' : ', ' ) . $qt_col;
        $info = $ax->get_sql_info( $sql );
        # Choose
        my $direction = $tc->choose(
            [ undef, "ASC", "DESC" ],
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $direction ){
            $sql->{order_by_stmt} = pop @bu;
            next ORDER_BY;
        }
        else {
            $sql->{order_by_stmt} .= ' ' . $direction;
        }
    }
}


sub limit_offset {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $driver = $sf->{i}{driver};
    my $use_limit = $driver =~ /^(?:SQLite|mysql|MariaDB|Pg|Informix)\z/ ? 1 : 0;
    my @pre = ( undef, $sf->{i}{ok} );
    my ( $limit, $offset ) = ( 'LIMIT', 'OFFSET' );
    my @bu;
    if ( @{$sql->{bu_limit_offset}//[]} ) {
        @bu = @{$sql->{bu_limit_offset}};
    }
    else {
        @bu = ( ['',''] );
    }
    ( $sql->{limit_stmt}, $sql->{offset_stmt} ) = @{pop @bu};

    LIMIT: while ( 1 ) {
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $choice = $tc->choose(
            [ @pre, $limit, $offset ],
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $choice ) {
            if ( @bu ) {
                ( $sql->{limit_stmt}, $sql->{offset_stmt} )  = @{pop @bu};
                next LIMIT;
            }
            delete $sql->{bu_limit_offset};
            return;
        }
        if ( $choice eq $sf->{i}{ok} ) {
            push @bu, [ $sql->{limit_stmt}, $sql->{offset_stmt} ];
            $sql->{bu_limit_offset} = [ @bu ];
            return 1;
        }
        push @bu, [ $sql->{limit_stmt}, $sql->{offset_stmt} ];
        my $digits = 7;
        if ( $choice eq $limit ) {
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
                { info => $info, cs_label => $limit . ': ', confirm => $sf->{i}{confirm}, back => $sf->{i}{back} }
            );
            if ( ! defined $limit ) {
                ( $sql->{limit_stmt}, $sql->{offset_stmt} ) = @{pop @bu};
                next LIMIT;
            }
            if ( $use_limit ) {
                $sql->{limit_stmt} = "LIMIT " . $limit;
            }
            else {
                $sql->{limit_stmt} = "FETCH NEXT " . $limit . " ROWS ONLY";
            }
        }
        elsif ( $choice eq $offset ) {
            $sql->{offset_stmt} = "OFFSET";
            my $info = $ax->get_sql_info( $sql );
            # Choose_a_number
            my $offset = $tu->choose_a_number(
                $digits,
                { info => $info, cs_label => $offset . ': ', confirm => $sf->{i}{confirm}, back => $sf->{i}{back} }
            );
            if ( ! defined $offset ) {
                ( $sql->{limit_stmt}, $sql->{offset_stmt} ) = @{pop @bu};
                next LIMIT;
            }
            if ( $use_limit ) {
                $sql->{offset_stmt} = "OFFSET " . $offset;
            }
            else {
                $sql->{offset_stmt} = "OFFSET " . $offset . " ROWS";
            }
            # Informix: no offset
            if ( ! $sql->{limit_stmt} ) {
                # SQLite/mysql/MariaDB: no offset without limit
                $sql->{limit_stmt} = "LIMIT " . '9223372036854775807'  if $driver eq 'SQLite';   # 2 ** 63 - 1
                $sql->{limit_stmt} = "LIMIT " . '18446744073709551615' if $driver =~ /^(?:mysql|MariaDB)\z/;    # 2 ** 64 - 1
                # MySQL 8.0 Reference Manual - SQL Statements/Data Manipulation Statements/Select Statement/Limit clause:
                #    SELECT * FROM tbl LIMIT 95,18446744073709551615;   -> all rows from the 95th to the last
            }
        }
    }
}


sub add_condition {
    my ( $sf, $sql, $clause, $cols ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $so = App::DBBrowser::Table::Substatements::Operators->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $AND_OR = '';
    my @bu;
    my $stmt;
    if ( $clause =~ s/_(\s*when)\z//i ) {
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
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $qt_col = $tc->choose(
            [ @pre, @$cols ],
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $qt_col ) {
            if ( @bu ) {
                $sql->{$stmt} = pop @bu;
                next COL;
            }
            $sql->{'bu_' . $stmt} = [];
            $sql->{$stmt} = '';
            return;
        }
        if ( $qt_col eq $sf->{i}{ok} ) {
            if ( ! @bu ) {
                $sql->{$stmt} = '';
            }
            push @bu, $sql->{$stmt};
            $sql->{'bu_' . $stmt} = [ @bu ];
            return 1;
        }
        if ( $qt_col eq $sf->{i}{menu_addition} ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_col = $ext->column( $sql, $clause, {}, { add_parentheses => 1 } );
            if ( ! defined $complex_col ) {
                next COL;
            }
            $qt_col = $complex_col;
        }
        push @bu, $sql->{$stmt};

        if ( $qt_col eq ')' ) {
            $sql->{$stmt} .= ")";
            next COL;
        }
        if ( @bu > 1 && $sql->{$stmt} !~ /\(\z/ ) {
            my $info = $ax->get_sql_info( $sql );
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
        if ( $qt_col eq '(' ) {
            $sql->{$stmt} .= $AND_OR . " (";
            $AND_OR = '';
            next COL;
        }
        if ( $clause eq 'having' ) {
            $qt_col = $sf->get_prepared_aggr_func( $sql, $clause, $qt_col );
            if ( ! defined $qt_col ) {
                $sql->{$stmt} = pop @bu;
                next COL;
            }
        }
        if ( $sql->{$stmt} =~ /\(\z/ ) { ##
            $sql->{$stmt} .= $qt_col;
        }
        else {
            $sql->{$stmt} .= $AND_OR . ' ' . $qt_col;
        }
        my $ok = $so->add_operator_and_value( $sql, $clause, $stmt, $qt_col );
        if ( ! $ok ) {
            $sql->{$stmt} = pop @bu;
            next COL;
        }
    }
}


sub get_prepared_aggr_func {
    my ( $sf, $sql, $clause, $aggr ) = @_;
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
            $sf->__update_tmp_sql( $sql, $tmp_sql, $clause, $prepared_aggr );
            my $info = $ax->get_sql_info( $tmp_sql );
            # Choose
            my $qt_col = $tc->choose(
                [ @pre, @{$tmp_sql->{columns}} ],
                { %{$sf->{i}{lyt_h}}, info => $info }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $qt_col ) {
                return;
            }
            elsif ( $qt_col eq $sf->{i}{menu_addition} ) {
                my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
                my $complex_col = $ext->column( $tmp_sql, $clause );
                if ( ! defined $complex_col ) {
                    next COLUMN;
                }
                $qt_col = $complex_col;
            }
            if ( $aggr =~ /^COUNT\z/i ) {
                $sf->__update_tmp_sql( $sql, $tmp_sql, $clause, $prepared_aggr . $qt_col );
                my $is_distinct = $sf->__is_distinct( $tmp_sql );
                if ( ! defined $is_distinct ) {
                    next COLUMN;
                }
                if ( $is_distinct ) {
                    $prepared_aggr .= "DISTINCT $qt_col)";
                }
                else {
                    $prepared_aggr .= "$qt_col)";
                }
            }
            elsif ( $aggr =~ /^$sf->{i}{group_concat}\z/ ) {
                my $bu_prepared_aggr = $prepared_aggr;
                $prepared_aggr = $sf->__opt_goup_concat( $sql, $tmp_sql, $clause, $aggr, $qt_col, $prepared_aggr );
                if ( ! defined $prepared_aggr ) {
                    $prepared_aggr = $bu_prepared_aggr;
                    next COLUMN;
                }
            }
            else {
                $prepared_aggr .= "$qt_col)";
            }
            last COLUMN;
        }

    }
    return $prepared_aggr;
}


sub __is_distinct {
    my ( $sf, $tmp_sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my ( $all, $distinct ) = ( 'ALL', 'DISTINCT' );
    my $info = $ax->get_sql_info( $tmp_sql );
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


sub __update_tmp_sql {
    my ( $sf, $sql, $tmp_sql, $clause, $prepared_aggr ) = @_;
    if ( $clause eq 'aggregate' ) {
        if ( @{$tmp_sql->{aggr_cols}} > @{$sql->{aggr_cols}} ) {
            pop @{$tmp_sql->{aggr_cols}};
        }
        push @{$tmp_sql->{aggr_cols}}, $prepared_aggr;
    }
    else {
        # having, order_by
        $tmp_sql->{$clause . '_stmt'} = $sql->{$clause . '_stmt'} . " " . $prepared_aggr;
    }
}


sub __opt_goup_concat {
    my ( $sf, $sql, $tmp_sql, $clause, $aggr, $qt_col, $prepared_aggr ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $sf->__update_tmp_sql( $sql, $tmp_sql, $clause, $prepared_aggr . $qt_col );
    my $is_distinct = $sf->__is_distinct( $tmp_sql );
    if ( ! defined $is_distinct ) {
        return;
    }
    if ( $is_distinct ) {
        $prepared_aggr .= "DISTINCT ";
    }
    $prepared_aggr .= $qt_col;
    if ( $sf->{i}{driver} eq 'Pg' && ! $ax->is_char_datatype( $tmp_sql, $qt_col ) ) {
        $prepared_aggr .= "::text" ;
    }
    my $sep = ',';
    my $order_by_stmt; # ##
    $sf->__update_tmp_sql( $sql, $tmp_sql, $clause, $prepared_aggr );
    if (      $sf->{i}{driver} =~ /^(?:mysql|MariaDB|Pg)\z/
         || ( $sf->{i}{driver} =~ /^(?:DB2|Oracle)\z/ && ! $is_distinct )
    ) {
        my ( $no_ordering, $read ) = ( 'Default', ':Read' );
        my $cast = '';
        if ( $sf->{i}{driver} eq 'Pg' && ! $ax->is_char_datatype( $sql, $qt_col ) && $is_distinct ) {
            $cast = '::text';
        }
        my @choices = (
            $no_ordering,
            "${qt_col}${cast} ASC",
            "${qt_col}${cast} DESC",
            $read,
        );
        my $menu = [ undef, @choices ];
        my $info = $ax->get_sql_info( $tmp_sql );
        # Choose
        my $choice = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $info, undef => '<<', prompt => 'Order:' }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $choice ) {
            return;
        }
        if ( $choice eq $read ) {
            my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
            my $history = [
                join( ', ', @{$tmp_sql->{columns}} ),
                join( ' DESC, ', @{$tmp_sql->{columns}} ) . ' DESC',
            ];
            my $info = $ax->get_sql_info( $tmp_sql );
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
        elsif ( $choice ne $no_ordering ) {
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
