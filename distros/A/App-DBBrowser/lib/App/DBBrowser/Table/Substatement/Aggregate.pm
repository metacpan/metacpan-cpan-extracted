package # hide from PAUSE
App::DBBrowser::Table::Substatement::Aggregate;

use warnings;
use strict;
use 5.016;

use Term::Choose         qw();
use Term::Form::ReadLine qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub __group_concat {
    my ( $sf ) = @_;
    my $dbms = $sf->{i}{dbms};
    my $group_concat = '';
    if ( $dbms =~ /^(?:SQLite|mysql|MariaDB)\z/ ) {
        $group_concat = "GROUP_CONCAT";
    }
    elsif ( $dbms =~ /^(?:Pg|DuckDB|MSSQL)\z/ ) {
        $group_concat = "STRING_AGG";
    }
    elsif ( $dbms eq 'Firebird' ) {
        $group_concat = "LIST";
    }
    elsif ( $dbms =~ /^(?:DB2|Oracle)\z/ ) {
        $group_concat = "LISTAGG";
    }
    return $group_concat;
}


sub available_aggregate_functions {
    my ( $sf ) = @_;
    my $avail_aggr = [ "COUNT(*)", "COUNT(X)", "SUM(X)", "AVG(X)", "MIN(X)", "MAX(X)" ];
    my $group_concat = $sf->__group_concat();
    if ( $group_concat ) {
        push @$avail_aggr, $group_concat . "(X)";
    }
    return $avail_aggr
}


sub get_prepared_aggr_func {
    my ( $sf, $sql, $clause, $aggr, $r_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $dbms = $sf->{i}{dbms};
    $r_data //= [];
    push @$r_data, [ 'aggr' ];
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
        my $group_concat = $sf->__group_concat();
        $prepared_aggr = $aggr . "(";
        if ( $aggr eq 'COUNT' || ( $aggr eq $group_concat && $dbms ne 'MSSQL' ) ) {
            my ( $all, $distinct ) = ( 'ALL', 'DISTINCT' );
            my $info = $sf->__prepared_aggr_info( $sql, $clause, $prepared_aggr, $r_data );
            # Choose
            my $choice = $tc->choose(
                [ undef, $all, $distinct ],
                { %{$sf->{i}{lyt_h}}, info => $info }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $choice ) {
                return;
            }
            #if ( $choice eq $distinct ) {
            #    $prepared_aggr .= "DISTINCT ";
            #}
            $prepared_aggr .= $choice . " ";
        }

        COLUMN: while ( 1 ) {
            my $info = $sf->__prepared_aggr_info( $sql, $clause, $prepared_aggr, $r_data );
            # Choose
            my $col = $tc->choose(
                [ @pre, @{$sql->{columns}} ],
                { %{$sf->{i}{lyt_h}}, info => $info }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $col ) {
                pop @$r_data;
                return;
            }
            elsif ( $col eq $sf->{i}{menu_addition} ) {
                my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
                # use normal columns within aggregate functions:
                $sql->{used_in_aggregate_function} = 1;
                $r_data->[-1] = [ 'aggr', $prepared_aggr ];
                my $complex_col = $ext->column( $sql, $clause, $r_data );
                delete $sql->{used_in_aggregate_function};
                if ( ! defined $complex_col ) {
                    next COLUMN;
                }
                $col = $complex_col;
            }
            if ( $prepared_aggr =~ /ALL\s\z/ ) {
                $prepared_aggr = $aggr . "(";
            };
            if ( $aggr =~ /^$group_concat\z/i ) {
                my $bu_prepared_aggr = $prepared_aggr;
                $prepared_aggr = $sf->__op_group_concat( $sql, $clause, $col, $prepared_aggr, $r_data );
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
    pop @$r_data;
    return $prepared_aggr;
}


sub __prepared_aggr_info {
    my ( $sf, $sql, $clause, $prepared_aggr, $r_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $r_data->[-1] = [ 'aggr', $prepared_aggr ];
    my $info = $ax->get_sql_info( $sql ) . $ext->nested_func_info( $r_data );
    return $info;
}


sub __op_group_concat {
    my ( $sf, $sql, $clause, $col, $prepared_aggr, $r_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $dbms = $sf->{i}{dbms};
    my $is_distinct = $prepared_aggr =~ /DISTINCT\s\z/;
    if ( $dbms eq 'Pg' ) {
        $prepared_aggr .= $ax->pg_column_to_text( $sql, $col );
    }
    else {
        $prepared_aggr .= $col;
    }
    my $sep = ',';
    my $order_by_stmt;
    if (      $dbms =~ /^(?:mysql|MariaDB|Pg|DuckDB|MSSQL)\z/
         || ( $dbms =~ /^(?:DB2|Oracle)\z/ && ! $is_distinct )
    ) {
        my $read = ':Read';
        if ( $dbms eq 'Pg' && $is_distinct ) {
            $col = $ax->pg_column_to_text( $sql, $col );
        }
        my @choices = ( "ASC", "DESC", $read );
        my $menu = [ undef, @choices ];
        my $info = $sf->__prepared_aggr_info( $sql, $clause, $prepared_aggr, $r_data );
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
                join( ', ', @{$sql->{columns}} ),
                join( ' DESC, ', @{$sql->{columns}} ) . ' DESC',
            ];
            my $info = $sf->__prepared_aggr_info( $sql, $clause, $prepared_aggr, $r_data );
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
            $order_by_stmt = "ORDER BY $col $choice";
        }
    }
    if ( $dbms eq 'SQLite' ) {
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
    elsif ( $dbms =~ /^(?:mysql|MariaDB)\z/ ) {
        if ( $order_by_stmt ) {
            $prepared_aggr .= " $order_by_stmt SEPARATOR '$sep')";
        }
        else {
            $prepared_aggr .= " SEPARATOR '$sep')";
        }
    }
    elsif ( $dbms =~ /^(?:Pg|DuckDB)\z/ ) {
        # Pg, STRING_AGG:
        # - separator mandatory
        # - expects text type as argument
        # - with DISTINCT the STRING_AGG col and the ORDER BY col must be identical
        if ( $order_by_stmt ) {
            $prepared_aggr .= ",'$sep' $order_by_stmt)";
        }
        else {
            $prepared_aggr .= ",'$sep')";
        }
    }
    elsif ( $dbms eq 'Firebird' ) {
        $prepared_aggr .= ",'$sep')";
    }
    elsif ( $dbms =~ /^(?:DB2|Oracle|MSSQL)\z/ ) {
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
