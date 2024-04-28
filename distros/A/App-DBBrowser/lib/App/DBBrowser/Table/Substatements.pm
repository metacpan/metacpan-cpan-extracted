package # hide from PAUSE
App::DBBrowser::Table::Substatements;

use warnings;
use strict;
use 5.014;

use List::MoreUtils qw( any );

use Term::Choose       qw();
use Term::Choose::Util qw();

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
                my $deleted_col = pop @{$sql->{selected_cols}};
                if ( exists $sql->{alias}{$deleted_col} ) {
                    delete $sql->{alias}{$deleted_col};
                }
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
                my $alias = $ax->alias( $sql, 'select_complex_col', $complex_col );
                if ( length $alias ) {
                    $sql->{alias}{$complex_col} = $ax->quote_alias( $alias );
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
        my $alias = $ax->alias( $sql, 'select_complex_col', $prepared_aggr );
        if ( length $alias ) {
            $sql->{alias}{$prepared_aggr} = $ax->quote_alias( $alias );
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
        my $col_sep = @bu == 1 ? ' ' : ', ';
        my $op = '=';
        $sql->{$stmt} .= $col_sep . $qt_col . ' ' . $op;
        my $ok = $so->read_and_add_value( $sql, $clause, $stmt, $qt_col, $op );
        if ( !  $ok ) {
            $sql->{$stmt} = pop @bu;
            next COL;
        }
    }
}


sub where {
    my ( $sf, $sql ) = @_;
    my $clause = 'where';
    my $substmt_type = "WHERE";
    my $items = [ @{$sql->{columns}} ];
    my $ret = $sf->__add_condition( $sql, $clause, $substmt_type, $items );
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

    GROUP_BY: while ( 1 ) {
        $sql->{group_by_stmt} = "GROUP BY " . join ', ', @{$sql->{group_by_cols}};
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
                $sql->{group_by_stmt} = "GROUP BY " . join ', ', @{$sql->{group_by_cols}};
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
                my $alias = $ax->alias( $sql, 'select_complex_col', $complex_col );
                # this alias is used in select
                if ( length $alias ) {
                    $sql->{alias}{$complex_col} = $ax->quote_alias( $alias );
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
    my $substmt_type = "HAVING";
    my $items = [ map( '@' . $_, @{$sql->{aggr_cols}} ), @{$sf->{i}{avail_aggr}} ];
    my $ret = $sf->__add_condition( $sql, $clause, $substmt_type, $items );
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
    my @tmp_cols;
    if ( $sql->{aggregate_mode} ) {
        @tmp_cols = ( @{$sql->{group_by_cols}}, map( '@' . $_, @{$sql->{aggr_cols}} ), @{$sf->{i}{avail_aggr}} );
    }
    else {
        @tmp_cols = @{$sql->{columns}};
    }
    my ( @cols, @aliases );
    my %count;
    for my $col ( @tmp_cols, @{$sql->{selected_cols}}) {
        next if ++$count{$col} > 1;
        if ( length $sql->{alias}{$col} ) {
            push @aliases, $sql->{alias}{$col};
        }
        else {
            push @cols, $col;
        }
    }
    if ( @aliases ) {
        push @cols, @aliases;
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
            my $complex_column = $ext->column( $sql, $clause );
            if ( ! defined $complex_column ) {
                #if ( @bu ) {
                #    $sql->{order_by_stmt} = pop @bu;
                #}
                next ORDER_BY;
            }
            $qt_col = $complex_column;
        }
        elsif ( $sql->{aggregate_mode} ) {
            $qt_col = $sf->get_prepared_aggr_func( $sql, $clause, $qt_col );
        }
        push @bu, $sql->{order_by_stmt};
        $sql->{order_by_stmt} .= ( @bu == 1 ? ' ' : ', ' ) . $qt_col;
        $info = $ax->get_sql_info( $sql ); # ???
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
        $sql->{order_by_stmt} .= ' ' . $direction;
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


sub __add_condition {
    my ( $sf, $sql, $clause, $substmt_type, $items ) = @_;
    # when-clause: $clause != $substmt_type
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $so = App::DBBrowser::Table::Substatements::Operators->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $AND_OR = '';
    my @bu;
    my $stmt;
    if ( $substmt_type =~ /^\s*(WHEN)\z/i ) {
        $stmt = lc( $1 ) . '_stmt';
        $sql->{$stmt} = $substmt_type . " ";
    }
    else {
        $stmt = lc( $substmt_type ) . '_stmt';
        @bu = @{$sql->{'bu_' . $stmt}//[]};
        $sql->{$stmt} = pop ( @bu ) // $substmt_type;
    }
    my @pre = ( undef, $sf->{i}{ok} );
    if ( $sf->{o}{enable}{extended_cols} ) {
        push @pre, $sf->{i}{menu_addition};
    }

    COL: while ( 1 ) {
        my @choices = ( @$items );
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $qt_col = $tc->choose(
            [ @pre, @choices ],
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
            my $complex_column = $ext->column( $sql, $clause, {}, { add_parentheses => 1 } );
            if ( ! defined $complex_column ) {
                next COL;
            }
            $qt_col = $complex_column;
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
        if ( $sql->{$stmt} =~ /\(\z/ ) {
            $sql->{$stmt} .= $qt_col;
        }
        else {
            $sql->{$stmt} .= $AND_OR . ' ' . $qt_col;
        }

        OPERATOR: while ( 1 ) {
            my $bu_op = $sql->{$stmt};
            my $operator = $so->choose_and_add_operator( $sql, $clause, $stmt, $qt_col );
            if ( ! defined $operator ) {
                $sql->{$stmt} = pop @bu;
                next COL;
            }
            my $ok = $so->read_and_add_value( $sql, $clause, $stmt, $qt_col, $operator );
            if ( ! $ok ) {
                $sql->{$stmt} = $bu_op;
                next OPERATOR;
            }
            last OPERATOR;
        }
    }
}


sub get_prepared_aggr_func {
    my ( $sf, $sql, $clause, $aggr ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $rx_aggr_requires_col = join '|', map { quotemeta } grep { /\(X\)\z/ } @{$sf->{i}{avail_aggr}};
    my $prepared_aggr;
    if ( $aggr !~ /^(?:$rx_aggr_requires_col)\z/ ) {
        if ( any { '@' . $_ eq $aggr } @{$sql->{aggr_cols}} ) {
            $aggr =~ s/^\@//;
        }
        $prepared_aggr = $aggr;
    }
    else {
        my $tmp_sql = $ax->clone_data( $sql );
        $aggr =~ s/\(X\)\z//;
        $prepared_aggr = $aggr . "(";
        if ( $clause eq 'aggregate' ) {
            push @{$tmp_sql->{aggr_cols}}, $prepared_aggr;
        }
        else {
            # having, order_by
            $tmp_sql->{$clause . '_stmt'} = $sql->{$clause . '_stmt'} . " " . $prepared_aggr;
        }
        my $is_distinct;
        if ( $aggr =~ /^(?:COUNT|$sf->{i}{group_concat})\z/ ) {
            my $info = $ax->get_sql_info( $tmp_sql );
            my ( $ALL, $DISTINCT ) = ( "ALL", "DISTINCT" );
            # Choose
            my $all_or_distinct = $tc->choose(
                [ undef, $ALL, $DISTINCT ],
                { %{$sf->{i}{lyt_h}}, info => $info }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $all_or_distinct ) {
                return;
            }
            if ( $all_or_distinct eq $DISTINCT ) {
                $prepared_aggr .= $DISTINCT . " ";
                $is_distinct = 1;
            }
        }
        my @pre = ( undef );
        if ( $sf->{o}{enable}{extended_cols} ) {
            push @pre, $sf->{i}{menu_addition};
        }
        my $qt_col;

        COLUMN: while ( 1 ) {
            if ( $clause eq 'aggregate' ) {
                pop @{$tmp_sql->{aggr_cols}};
                push @{$tmp_sql->{aggr_cols}}, $prepared_aggr;
            }
            else {
                $tmp_sql->{$clause . '_stmt'} = $sql->{$clause . '_stmt'} . " " . $prepared_aggr;
            }
            my $info = $ax->get_sql_info( $tmp_sql );
            # Choose
            $qt_col = $tc->choose(
                [ @pre, @{$tmp_sql->{columns}} ],
                { %{$sf->{i}{lyt_h}}, info => $info }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $qt_col ) {
                return;
            }
            elsif ( $qt_col eq $sf->{i}{menu_addition} ) {
                my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
                my $complex_column = $ext->column( $tmp_sql, $clause );
                if ( ! defined $complex_column ) {
                    next COLUMN;
                }
                $qt_col = $complex_column;
            }
            last COLUMN;
        }
        if ( $aggr =~ /^$sf->{i}{group_concat}\z/ ) {
            if ( $sf->{i}{driver} eq 'Pg' ) {
                # Pg, STRING_AGG: separator mandatory
                $prepared_aggr .= "${qt_col}::text,',')";
            }
            elsif ( $sf->{i}{driver} =~ /^(?:DB2|Oracle)\z/ ) {
                # DB2, LISTAGG: no default separator
                $prepared_aggr .= "$qt_col,',')";
            }
            else {
                # https://sqlite.org/forum/info/221c2926f5e6f155
                # SQLite: GROUP_CONCAT with DISTINCT and custom seperator does not work
                $prepared_aggr .= "$qt_col)";
            }
            #my $sep = ',';
            #if ( $sf->{i}{driver} eq 'SQLite' ) {
            #    if ( $is_distinct ) {
            #        # https://sqlite.org/forum/info/221c2926f5e6f155
            #        # SQLite: GROUP_CONCAT with DISTINCT and custom seperator does not work
            #        # default separator is ','
            #        $prepared_aggr .= "$qt_col)";
            #    }
            #    else {
            #        $prepared_aggr .= "$qt_col,'$sep')";
            #    }
            #}
            #elsif ( $sf->{i}{driver} =~ /^(?:mysql|MariaDB)\z/ ) {
            #    $prepared_aggr .= "$qt_col ORDER BY $qt_col SEPARATOR '$sep')";
            #}
            #elsif ( $sf->{i}{driver} eq 'Pg' ) {
            #    # Pg, STRING_AGG:
            #    # separator mandatory
            #    # expects text type as argument
            #    # with DISTINCT the STRING_AGG col and the ORDER BY col must be identical
            #    $prepared_aggr .= "${qt_col}::text,'$sep' ORDER BY ${qt_col}::text)";
            #}
            #elsif ( $sf->{i}{driver} eq 'Firebird' ) {
            #    $prepared_aggr .= "$qt_col,'$sep')";
            #}
            #elsif ( $sf->{i}{driver} =~ /^(?:DB2|Oracle)\z/ ) {
            #    if ( $is_distinct ) {
            #        # DB2 codes: error code -214 - error caused by:
            #        # DISTINCT is specified in the SELECT clause, and a column name or sort-key-expression in the
            #        # ORDER BY clause cannot be matched exactly with a column name or expression in the select list.
            #        $prepared_aggr .= "$qt_col,'$sep')";
            #    }
            #    else {
            #        $prepared_aggr .= "$qt_col,'$sep') WITHIN GROUP (ORDER BY $qt_col)";
            #    }
            #}
            #else {
            #    return;
            #}
        }
        else {
            $prepared_aggr .= "$qt_col)";
        }
    }
    return $prepared_aggr;
}




1;


__END__
