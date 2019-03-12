package # hide from PAUSE
App::DBBrowser::Table::Substatements;

use warnings;
use strict;
use 5.008003;

use Term::Choose       qw( choose );
use Term::Choose::Util qw( choose_a_number );
use Term::Form         qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions;
use App::DBBrowser::Table::Substatements::Operators;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
        # SQLite: GROUP_CONCAT(DISTINCT "Col")  or  GROUP_CONCAT("Col",",");
        aggregate     => [ "AVG(X)", "COUNT(X)", "COUNT(*)", "GROUP_CONCAT(X)", "MAX(X)", "MIN(X)", "SUM(X)" ],
        distinct      => "DISTINCT",
        all           => "ALL",
        asc           => "ASC",
        desc          => "DESC",
        and           => "AND",
        or            => "OR",
    };
    if ( $data->{driver} eq 'Pg' ) {
        $sf->{aggregate}[3] = "STRING_AGG(X)";
    }
    $sf->{i}{expand_signs}     = [ '',  'f()', 'SQ',       '%%' ];
    $sf->{i}{expand_signs_set} = [ '',  'f()', 'SQ', '=N', '%%' ];
    bless $sf, $class;
}


sub select {
    my ( $sf, $stmt_h, $sql ) = @_;
    my $clause = 'select';
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $choices = [];
    my $sign_idx = $sf->{o}{enable}{'expand_' . $clause};
    my $expand_sign = $sf->{i}{expand_signs}[$sign_idx];
    my @pre = ( undef, $sf->{i}{ok}, $expand_sign ? $expand_sign : () );
    my $type;
    if ( @{$sql->{group_by_cols}} || @{$sql->{aggr_cols}} ) {
        $choices = [ @pre, @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}} ];
    }
    else {
        $choices = [ @pre, @{$sql->{cols}} ];
    }
    $sql->{select_cols} = [];
    #$sql->{alias} = { %{$sql->{alias}} };
    my @bu;

    COLUMNS: while ( 1 ) {
        $ax->print_sql( $sql );
        # Choose
        my @idx = $stmt_h->choose(
            $choices, { meta_items => [ 0 .. $#pre - 1 ], no_spacebar => [ $#pre ], index => 1, include_highlighted => 2 }
        );
        if ( ! $idx[0] ) {
            if ( @bu ) {
                ( $sql->{select_cols}, $sql->{alias} ) = @{pop @bu};
                next COLUMNS;
            }
            return;
        }
        push @bu, [ [ @{$sql->{select_cols}} ], { %{$sql->{alias}} } ];
        if ( $choices->[$idx[0]] eq $sf->{i}{ok} ) {
            shift @idx;
            push @{$sql->{select_cols}}, @{$choices}[@idx];
            return 1;
        }
        elsif ( $choices->[$idx[0]] eq $expand_sign ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $ext_col = $ext->extended_col( $sql, $clause );
            if ( ! defined $ext_col ) {
                ( $sql->{select_cols}, $sql->{alias} ) = @{pop @bu};
            }
            else {
                push @{$sql->{select_cols}}, $ext_col;
            }
            next COLUMNS;
        }
        push @{$sql->{select_cols}}, @{$choices}[@idx];
    }
}


sub distinct {
    my ( $sf, $stmt_h, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @pre = ( undef, $sf->{i}{ok} );
    $sql->{distinct_stmt} = '';

    DISTINCT: while ( 1 ) {
        my $choices = [ @pre, $sf->{distinct}, $sf->{all} ];
        $ax->print_sql( $sql );
        # Choose
        my $select_distinct = $stmt_h->choose(
            $choices
        );
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
    my ( $sf, $stmt_h, $sql ) = @_;
    $sql->{aggr_cols} = [];
    $sql->{select_cols} = [];

    AGGREGATE: while ( 1 ) {
        my $ret = $sf->__add_aggregate_substmt( $sql );
        if ( ! $ret ) {
            if ( @{$sql->{aggr_cols}} ) {
                my $aggr = pop @{$sql->{aggr_cols}};
                delete $sql->{alias}{$aggr} if exists $sql->{alias}{$aggr};
                next AGGREGATE;
            }
            return;
        }
        elsif ( $ret eq $sf->{i}{ok} ) {
            return 1;
        }
    }
}

sub __add_aggregate_substmt {
    my ( $sf, $sql ) = @_;
    my $stmt_h = Term::Choose->new( $sf->{i}{lyt_stmt_h} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @pre = ( undef, $sf->{i}{ok} );
    my $i = @{$sql->{aggr_cols}};
    $ax->print_sql( $sql );
    # Choose
    my $aggr = $stmt_h->choose(
        [ @pre, @{$sf->{aggregate}} ]
    );
    if ( ! defined $aggr ) {
        return;
    }
    elsif ( $aggr eq $sf->{i}{ok} ) {
        return $aggr;
    }
    if ( $aggr eq 'COUNT(*)' ) {
        $sql->{aggr_cols}[$i] = $aggr;
    }
    else {
        $aggr =~ s/\(\S\)\z//; #
        $sql->{aggr_cols}[$i] = $aggr . "(";
        if ( $aggr =~ /^(?:COUNT|GROUP_CONCAT|STRING_AGG)\z/ ) {
            $ax->print_sql( $sql );
            # Choose
            my $all_or_distinct = $stmt_h->choose(
                [ undef, $sf->{all}, $sf->{distinct} ]
            );
            if ( ! defined $all_or_distinct ) {
                return;
            }
            if ( $all_or_distinct eq $sf->{distinct} ) {
                $sql->{aggr_cols}[$i] .= $sf->{distinct};
            }
        }
        $ax->print_sql( $sql );
        # Choose
        my $f_col = $stmt_h->choose(
            [ undef, @{$sql->{cols}} ]
        );
        if ( ! defined $f_col ) {
            return;
        }
        if ( $aggr eq 'STRING_AGG' ) {
            # pg: the separator is mandatory in STRING_AGG(DISTINCT, "Col", ',')
            $sql->{aggr_cols}[$i] .= ' ' . $f_col . ", ',')";
        }
        else {
            $sql->{aggr_cols}[$i] .= ' ' . $f_col . ")";
        }
    }
    my $alias = $ax->alias( 'aggregate', $sql->{aggr_cols}[$i] );
    if ( defined $alias && length $alias ) {
        $sql->{alias}{$sql->{aggr_cols}[$i]} = $ax->quote_col_qualified( [ $alias ] );
    }
    return 1;
}


sub set {
    my ( $sf, $stmt_h, $sql ) = @_;
    my $clause = 'set';
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $op = App::DBBrowser::Table::Substatements::Operators->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $trs = Term::Form->new();
    my $col_sep = ' ';
    $sql->{set_args} = [];
    $sql->{set_stmt} = " SET";
    my @bu;
    my @pre = ( undef, $sf->{i}{ok} );

    SET: while ( 1 ) {
        $ax->print_sql( $sql );
        # Choose
        my $col = $stmt_h->choose(
            [ @pre, @{$sql->{cols}} ]
        );
        if ( ! defined $col ) {
            if ( @bu ) {
                ( $sql->{set_args}, $sql->{set_stmt}, $col_sep ) = @{pop @bu};
                next SET;
            }
            return;
        }
        if ( $col eq $sf->{i}{ok} ) {
            if ( $col_sep eq ' ' ) {
                $sql->{set_stmt} = '';
            }
            return 1;
        }
        push @bu, [ [@{$sql->{set_args}}], $sql->{set_stmt}, $col_sep ];
        $sql->{set_stmt} .= $col_sep . $col;
        my $ok = $op->add_operator_with_value( $sql, $clause, $col );
        if ( ! $ok ) {
            ( $sql->{set_args}, $sql->{set_stmt}, $col_sep ) = @{pop @bu};
            next SET;
        }
        $col_sep = ', ';
    }
}


sub where {
    my ( $sf, $stmt_h, $sql ) = @_;
    my $clause = 'where';
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $op = App::DBBrowser::Table::Substatements::Operators->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @cols = @{$sql->{cols}};
    my $AND_OR = '';
    $sql->{where_args} = [];
    $sql->{where_stmt} = " WHERE";
    my $unclosed = 0;
    my $count = 0;
    my @bu;
    my $sign_idx = $sf->{o}{enable}{'expand_' . $clause};
    my $expand_sign = $sf->{i}{expand_signs}[$sign_idx];
    my @pre = ( undef, $sf->{i}{ok}, $sign_idx ? $expand_sign : () );

    WHERE: while ( 1 ) {
        my @choices = ( @cols );
        if ( $sf->{o}{enable}{parentheses} ) {
            unshift @choices, $unclosed ? ')' : '(';
        }
        $ax->print_sql( $sql );
        # Choose
        my $quote_col = $stmt_h->choose(
            [ @pre, @choices ]
        );
        if ( ! defined $quote_col ) {
            if ( @bu ) {
                ( $sql->{where_args}, $sql->{where_stmt}, $AND_OR, $unclosed, $count ) = @{pop @bu};
                next WHERE;
            }
            return;
        }
        if ( $quote_col eq $sf->{i}{ok} ) {
            if ( $count == 0 ) {
                $sql->{where_stmt} = '';
            }
            if ( $unclosed == 1 ) { # close an open parentheses automatically on OK
                $sql->{where_stmt} .= ")";
                $unclosed = 0;
            }
            return 1;
        }
        if ( $quote_col eq $expand_sign ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $ext_col = $ext->extended_col( $sql, $clause );
            if ( ! defined $ext_col ) {
                if ( @bu ) {
                    ( $sql->{where_args}, $sql->{where_stmt}, $AND_OR, $unclosed, $count ) = @{pop @bu};
                }
                next WHERE;
            }
            $quote_col = $ext_col;
        }
        if ( $quote_col eq ')' ) {
            push @bu, [ [@{$sql->{where_args}}], $sql->{where_stmt}, $AND_OR, $unclosed, $count ];
            $sql->{where_stmt} .= ")";
            $unclosed--;
            next WHERE;
        }
        if ( $count > 0 && $sql->{where_stmt} !~ /\(\z/ ) { #
            $ax->print_sql( $sql );
            # Choose
            $AND_OR = $stmt_h->choose(
                [ undef, $sf->{and}, $sf->{or} ]
            );
            if ( ! defined $AND_OR ) {
                next WHERE;
            }
            $AND_OR = ' ' . $AND_OR;
        }
        if ( $quote_col eq '(' ) {
            push @bu, [ [@{$sql->{where_args}}], $sql->{where_stmt}, $AND_OR, $unclosed, $count ];
            $sql->{where_stmt} .= $AND_OR . " (";
            $AND_OR = '';
            $unclosed++;
            next WHERE;
        }
        push @bu, [ [@{$sql->{where_args}}], $sql->{where_stmt}, $AND_OR, $unclosed, $count ];
        $sql->{where_stmt} .= $AND_OR . ' ' . $quote_col;
        my $ok = $op->add_operator_with_value( $sql, $clause, $quote_col );
        if ( ! $ok ) {
            ( $sql->{where_args}, $sql->{where_stmt}, $AND_OR, $unclosed, $count ) = @{pop @bu};
            next WHERE;
        }
        $count++;
    }
}


sub group_by {
    my ( $sf, $stmt_h, $sql ) = @_;
    my $clause = 'group_by';
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $sql->{group_by_stmt} = " GROUP BY";
    $sql->{group_by_cols} = [];
    $sql->{select_cols} = [];
    my $sign_idx = $sf->{o}{enable}{'expand_' . $clause};
    my $expand_sign = $sf->{i}{expand_signs}[$sign_idx];
    my @pre = ( undef, $sf->{i}{ok}, $expand_sign ? $expand_sign : () );
    my $choices = [ @pre, @{$sql->{cols}} ];

    GROUP_BY: while ( 1 ) {
        $sql->{group_by_stmt} = " GROUP BY " . join ', ', @{$sql->{group_by_cols}};
        $ax->print_sql( $sql );
        # Choose
        my @idx = $stmt_h->choose(
            $choices,
            { meta_items => [ 0 .. $#pre - 1 ], no_spacebar => [ $#pre ], index => 1, include_highlighted => 2 }
        );
        if ( ! $idx[0] ) {
            if ( @{$sql->{group_by_cols}} ) {
                pop @{$sql->{group_by_cols}};
                next GROUP_BY;
            }
            $sql->{group_by_stmt} = " GROUP BY " . join ', ', @{$sql->{group_by_cols}};
            return;
        }
        elsif ( $choices->[$idx[0]] eq $sf->{i}{ok} ) {
            shift @idx;
            push @{$sql->{group_by_cols}}, @{$choices}[@idx];
            if ( ! @{$sql->{group_by_cols}} ) {
                $sql->{group_by_stmt} = '';
            }
            else {
                $sql->{group_by_stmt} = " GROUP BY " . join ', ', @{$sql->{group_by_cols}};
            }
            return 1;
        }
        elsif ( $choices->[$idx[0]] eq $expand_sign ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $ext_col = $ext->extended_col( $sql, $clause );
            if ( defined $ext_col ) {
                push @{$sql->{group_by_cols}}, $ext_col;
            }
            next GROUP_BY;
        }
        push @{$sql->{group_by_cols}}, @{$choices}[@idx];
    }
}


sub having {
    my ( $sf, $stmt_h, $sql ) = @_;
    my $clause = 'having';
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $op = App::DBBrowser::Table::Substatements::Operators->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @pre = ( undef, $sf->{i}{ok} );
    my $AND_OR = '';
    $sql->{having_args} = [];
    $sql->{having_stmt} = " HAVING";
    my $unclosed = 0;
    my $count = 0;
    my @bu;

    HAVING: while ( 1 ) {
        my @choices = (
            @{$sf->{aggregate}},
            map( '@' . $_, @{$sql->{aggr_cols}} )
        );
        if ( $sf->{o}{enable}{parentheses} ) {
            unshift @choices, $unclosed ? ')' : '(';
        }
        $ax->print_sql( $sql );
        # Choose
        my $aggr = $stmt_h->choose(
            [ @pre, @choices ]
        );
        if ( ! defined $aggr ) {
            if ( @bu ) {
                ( $sql->{having_args}, $sql->{having_stmt}, $AND_OR, $unclosed, $count ) = @{pop @bu};
                next HAVING;
            }
            return;
        }
        if ( $aggr eq $sf->{i}{ok} ) {
            if ( $count == 0 ) {
                $sql->{having_stmt} = '';
            }
            if ( $unclosed == 1 ) { # close an open parentheses automatically on OK
                $sql->{having_stmt} .= ")";
                $unclosed = 0;
            }
            return 1;
        }
        if ( $aggr eq ')' ) {
            push @bu, [ [@{$sql->{having_args}}], $sql->{having_stmt}, $AND_OR, $unclosed, $count ];
            $sql->{having_stmt} .= ")";
            $unclosed--;
            next HAVING;
        }
        if ( $count > 0 && $sql->{having_stmt} !~ /\(\z/ ) {
            $ax->print_sql( $sql );
            # Choose
            $AND_OR = $stmt_h->choose(
                [ undef, $sf->{and}, $sf->{or} ]
            );
            if ( ! defined $AND_OR ) {
                next HAVING;
            }
            $AND_OR = ' ' . $AND_OR;
        }
        if ( $aggr eq '(' ) {
            push @bu, [ [@{$sql->{having_args}}], $sql->{having_stmt}, $AND_OR, $unclosed, $count ];
            $sql->{having_stmt} .= $AND_OR . " (";
            $AND_OR = '';
            $unclosed++;
            next HAVING;
        }
        push @bu, [ [@{$sql->{having_args}}], $sql->{having_stmt}, $AND_OR, $unclosed, $count ];
        $sql->{having_stmt} .= $AND_OR;
        my $quote_aggr = $op->build_having_col( $sql, $aggr );
        if ( ! defined $quote_aggr ) {
            ( $sql->{having_args}, $sql->{having_stmt}, $AND_OR, $unclosed, $count ) = @{pop @bu};
            next HAVING;
        }
        my $ok = $op->add_operator_with_value( $sql, $clause, $quote_aggr );
        if ( ! $ok ) {
            ( $sql->{having_args}, $sql->{having_stmt}, $AND_OR, $unclosed, $count ) = @{pop @bu};
            next HAVING;
        }
        $count++;
    }
}


sub order_by {
    my ( $sf, $stmt_h, $sql ) = @_;
    my $clause = 'order_by';
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sign_idx = $sf->{o}{enable}{'expand_' . $clause};
    my $expand_sign = $sf->{i}{expand_signs}[$sign_idx];
    my @pre = ( undef, $sf->{i}{ok}, $expand_sign ? $expand_sign : () );
    my @cols;
    if ( @{$sql->{aggr_cols}} || @{$sql->{group_by_cols}} ) {
        @cols = ( @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}} );
    }
    else {
        @cols = @{$sql->{cols}};
    }
    my $col_sep = ' ';
    $sql->{order_by_stmt} = " ORDER BY";
    my @bu;

    ORDER_BY: while ( 1 ) {
        $ax->print_sql( $sql );
        # Choose
        my $col = $stmt_h->choose(
            [ @pre, @cols ]
        );
        if ( ! defined $col ) {
            if ( @bu ) {
                ( $sql->{order_by_stmt}, $col_sep ) = @{pop @bu};
                next ORDER_BY;
            }
            return
        }
        if ( $col eq $sf->{i}{ok} ) {
            if ( $col_sep eq ' ' ) {
                $sql->{order_by_stmt} = '';
            }
            return 1;
        }
        elsif ( $col eq $expand_sign ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $ext_col = $ext->extended_col( $sql, $clause );
            if ( ! defined $ext_col ) {
                if ( @bu ) {
                    ( $sql->{order_by_stmt}, $col_sep ) = @{pop @bu};
                }
                next ORDER_BY;
            }
            $col = $ext_col;
        }
        push @bu, [ $sql->{order_by_stmt}, $col_sep ];
        $sql->{order_by_stmt} .= $col_sep . $col;
        $ax->print_sql( $sql );
        # Choose
        my $direction = $stmt_h->choose(
            [ undef, $sf->{asc}, $sf->{desc} ]
        );
        if ( ! defined $direction ){
            ( $sql->{order_by_stmt}, $col_sep ) = @{pop @bu};
            next ORDER_BY;
        }
        $sql->{order_by_stmt} .= ' ' . $direction;
        $col_sep = ', ';
    }
}


sub limit_offset {
    my ( $sf, $stmt_h, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @pre = ( undef, $sf->{i}{ok} );
    $sql->{limit_stmt}  = '';
    $sql->{offset_stmt} = '';
    my @bu;

    LIMIT: while ( 1 ) {
        my ( $limit, $offset ) = ( 'LIMIT', 'OFFSET' );
        $ax->print_sql( $sql );
        # Choose
        my $choice = $stmt_h->choose(
            [ @pre, $limit, $offset ]
        );
        if ( ! defined $choice ) {
            if ( @bu ) {
                ( $sql->{limit_stmt}, $sql->{offset_stmt} )  = @{pop @bu};
                next LIMIT;
            }
            return;
        }
        if ( $choice eq $sf->{i}{ok} ) {
            return 1;
        }
        push @bu, [ $sql->{limit_stmt}, $sql->{offset_stmt} ];
        my $digits = 7;
        if ( $choice eq $limit ) {
            $sql->{limit_stmt} = " LIMIT";
            $ax->print_sql( $sql );
            # Choose_a_number
            my $limit = choose_a_number( $digits,
                { name => 'LIMIT: ', mouse => $sf->{o}{table}{mouse}, clear_screen => 0 }
            );
            if ( ! defined $limit ) {
                ( $sql->{limit_stmt}, $sql->{offset_stmt} ) = @{pop @bu};
                next LIMIT;
            }
            $sql->{limit_stmt} .=  sprintf ' %d', $limit;
        }
        if ( $choice eq $offset ) {
            if ( ! $sql->{limit_stmt} ) {
                $sql->{limit_stmt} = " LIMIT " . ( $sf->{o}{G}{max_rows} || '9223372036854775807'  ) if $sf->{d}{driver} eq 'SQLite';   # 2 ** 63 - 1
                # MySQL 5.7 Reference Manual - SELECT Syntax - Limit clause: SELECT * FROM tbl LIMIT 95,18446744073709551615;
                $sql->{limit_stmt} = " LIMIT " . ( $sf->{o}{G}{max_rows} || '18446744073709551615' ) if $sf->{d}{driver} eq 'mysql';    # 2 ** 64 - 1
            }
            $sql->{offset_stmt} = " OFFSET";
            $ax->print_sql( $sql );
            # Choose_a_number
            my $offset = choose_a_number( $digits,
                { name => 'OFFSET: ', mouse => $sf->{o}{table}{mouse}, clear_screen => 0 }
            );
            if ( ! defined $offset ) {
                ( $sql->{limit_stmt}, $sql->{offset_stmt} ) = @{pop @bu};
                next LIMIT;
            }
            $sql->{offset_stmt} .= sprintf ' %d', $offset;
        }
    }
}






1;


__END__
