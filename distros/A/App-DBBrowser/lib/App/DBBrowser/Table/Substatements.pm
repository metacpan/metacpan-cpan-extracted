package # hide from PAUSE
App::DBBrowser::Table::Substatements;

use warnings;
use strict;
use 5.008003;

use List::MoreUtils   qw( any );

use Term::Choose       qw( choose );
use Term::Choose::Util qw( choose_a_number );
use Term::Form         qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Subqueries;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
        aggregate    => [ "AVG(X)", "COUNT(X)", "COUNT(*)", "MAX(X)", "MIN(X)", "SUM(X)" ],
        opr_subquery => [ "IN", "NOT IN", " = ", " != ", " < ", " > ", " >= ", " <= " ],
        distinct => "DISTINCT",
        all     => "ALL",
        asc     => "ASC",
        desc    => "DESC",
        and     => "AND",
        or      => "OR",
    };
    bless $sf, $class;
}


sub __add_aggregate_substmt {
    my ( $sf, $sql, $tmp,  $stmt_type ) = @_;
    my $stmt_h = Term::Choose->new( $sf->{i}{lyt_stmt_h} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @pre = ( undef, $sf->{i}{ok} );
    my $i = @{$tmp->{aggr_cols}};
    $ax->print_sql( $sql, [ $stmt_type ], $tmp );
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
        $tmp->{aggr_cols}[$i] = $aggr;
    }
    else {
        $aggr =~ s/\(\S\)\z//; #
        $tmp->{aggr_cols}[$i] = $aggr . "(";
        if ( $aggr eq 'COUNT' ) {
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            # Choose
            my $all_or_distinct = $stmt_h->choose(
                [ undef, $sf->{all}, $sf->{distinct} ]
            );
            if ( ! defined $all_or_distinct ) {
                return;
            }
            if ( $all_or_distinct eq $sf->{distinct} ) {
                $tmp->{aggr_cols}[$i] .= $sf->{distinct} . ' '; #
            }
        }
        $ax->print_sql( $sql, [ $stmt_type ], $tmp );
        # Choose
        my $f_col = $stmt_h->choose(
            [ undef, @{$sql->{cols}} ]
        );
        if ( ! defined $f_col ) {
            return;
        }
        $tmp->{aggr_cols}[$i] .= $f_col . ")";
    }
    my $alias = $ax->alias( $tmp->{aggr_cols}[$i] );
    if ( defined $alias && length $alias ) {
        $tmp->{alias}{$tmp->{aggr_cols}[$i]} = $ax->quote_col_qualified( [ $alias ] );
    }
    return 1;
}


sub columns {
    my ( $sf, $stmt_h, $sql, $stmt_type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tmp = {
        chosen_cols => [],
        alias       => { %{$sql->{alias}} },
    };
    my $sq_col = '(Q';
    my $bu = [];
    my @pre = ( undef, $sf->{i}{ok} );
    push @pre, $sq_col if $sf->{o}{G}{subqueries_select};

    COLUMNS: while ( 1 ) {
        my $choices = [ @pre, @{$sql->{cols}} ];
        $ax->print_sql( $sql, [ $stmt_type ], $tmp );
        # Choose
        my @cols = $stmt_h->choose(
            $choices, { meta_items => [ 0 .. $#pre - 1 ], no_spacebar => [ $#pre ], include_highlighted => 2 }
        );
        if ( ! defined $cols[0] ) {
            if ( @$bu ) {
                ( $tmp->{chosen_cols}, $tmp->{alias} ) = @{pop @$bu};
                next COLUMNS;
            }
            return;
        }
        elsif ( $cols[0] eq $sf->{i}{ok} ) {
            shift @cols;
            push @{$tmp->{chosen_cols}}, @cols;
            $tmp->{orig_chosen_cols} = []; # keys of $tmp overwrite keys of $sql in Table.pm:
            $tmp->{modified_cols}    = []; #     $sql->{$_} = $tmp->{$_} for keys;
            return $tmp;
        }
        push @$bu, [ [ @{$tmp->{chosen_cols}} ], { %{$tmp->{alias}} } ];
        if ( $cols[0] eq $sq_col ) {
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $subquery = $sq->choose_subquery( $sql, $tmp, $stmt_type );
            if ( ! defined $subquery ) {
                ( $tmp->{chosen_cols}, $tmp->{alias} ) = @{pop @$bu};
                next COLUMNS;
            }
            $subquery = "(" . $subquery . ")";
            push @{$tmp->{chosen_cols}}, $subquery;
            my $alias = $ax->alias( $subquery );
            if ( defined $alias && length $alias ) {
                $tmp->{alias}{$subquery} = $ax->quote_col_qualified( [ $alias ] );
            }
            next COLUMNS;
        }
        else {
            push @{$tmp->{chosen_cols}}, @cols;
        }
    }
}


sub distinct {
    my ( $sf, $stmt_h, $sql, $stmt_type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @pre = ( undef, $sf->{i}{ok} );
    my $tmp = { distinct_stmt => '' };

    DISTINCT: while ( 1 ) {
        my $choices = [ @pre, $sf->{distinct}, $sf->{all} ];
        $ax->print_sql( $sql, [ $stmt_type ], $tmp );
        # Choose
        my $select_distinct = $stmt_h->choose(
            $choices
        );
        if ( ! defined $select_distinct ) {
            if ( $tmp->{distinct_stmt} ) {
                $tmp->{distinct_stmt} = '';
                next DISTINCT;
            }
            return;
        }
        elsif ( $select_distinct eq $sf->{i}{ok} ) {
            return $tmp;
        }
        $tmp->{distinct_stmt} = ' ' . $select_distinct;
    }
}


sub aggregate {
    my ( $sf, $stmt_h, $sql, $stmt_type ) = @_;
    my $tmp = {
        aggr_cols => [],
    };

    AGGREGATE: while ( 1 ) {
        my $ret = $sf->__add_aggregate_substmt( $sql, $tmp, $stmt_type );
        if ( ! $ret ) {
            if ( @{$tmp->{aggr_cols}} ) {
                my $aggr = pop @{$tmp->{aggr_cols}};
                delete $tmp->{alias}{$aggr} if exists $tmp->{alias}{$aggr};
                next AGGREGATE;
            }
            return;
        }
        elsif ( $ret eq $sf->{i}{ok} ) {
            $tmp->{orig_aggr_cols} = [];
            return $tmp;
        }
    }
}


sub set {
    my ( $sf, $stmt_h, $sql, $stmt_type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $trs = Term::Form->new();
    my $col_sep = ' ';
    my $tmp = {
        set_args => [],
        set_stmt => " SET",
    };
    my $bu = [];
    my @pre = ( undef, $sf->{i}{ok} );

    SET: while ( 1 ) {
        $ax->print_sql( $sql, [ $stmt_type ], $tmp );
        # Choose
        my $col = $stmt_h->choose(
            [ @pre, @{$sql->{cols}} ]
        );
        if ( ! defined $col ) {
            if ( @$bu ) {
                ( $tmp->{set_args}, $tmp->{set_stmt}, $col_sep ) = @{pop @$bu};
                next SET;
            }
            return;
        }
        if ( $col eq $sf->{i}{ok} ) {
            if ( $col_sep eq ' ' ) {
                $tmp->{set_stmt} = '';
            }
            return $tmp;
        }
        push @$bu, [ [@{$tmp->{set_args}}], $tmp->{set_stmt}, $col_sep ];
        $tmp->{set_stmt} .= $col_sep . $col;
        my $ok = $sf->__set_operator_sql( $sql, $tmp, 'set', $col, $stmt_type );
        if ( ! $ok ) {
            ( $tmp->{set_args}, $tmp->{set_stmt}, $col_sep ) = @{pop @$bu};
            next SET;
        }
        $col_sep = ', ';
    }
}


sub where {
    my ( $sf, $stmt_h, $sql, $stmt_type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @cols = ( @{$sql->{cols}}, @{$sql->{modified_cols}} );
    my $AND_OR = ' ';
    my $tmp = {
        where_args => [],
        where_stmt => " WHERE",
    };
    my $unclosed = 0;
    my $count = 0;
    my $bu = [];
    my $sq_col = '(Q';
    my @pre = ( undef, $sf->{i}{ok} );
    push @pre, $sq_col if $sf->{o}{G}{subqueries_w_h};

    WHERE: while ( 1 ) {
        my @choices = ( @cols );
        if ( $sf->{o}{G}{parentheses} == 1 ) {
            unshift @choices, $unclosed ? ')' : '(';
        }
        $ax->print_sql( $sql, [ $stmt_type ], $tmp );
        # Choose
        my $quote_col = $stmt_h->choose(
            [ @pre, @choices ]
        );
        if ( ! defined $quote_col ) {
            if ( @$bu ) {
                ( $tmp->{where_args}, $tmp->{where_stmt}, $AND_OR, $unclosed, $count ) = @{pop @$bu};
                next WHERE;
            }
            return;
        }
        if ( $quote_col eq $sf->{i}{ok} ) {
            if ( $count == 0 ) {
                $tmp->{where_stmt} = '';
            }
            if ( $unclosed == 1 ) { # close an open parentheses automatically on OK
                $tmp->{where_stmt} .= ")";
                $unclosed = 0;
            }
            return $tmp;
        }
        if ( $quote_col eq $sq_col ) {
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );  # sub
            my $subquery = $sq->choose_subquery( $sql, $tmp, $stmt_type );
            if ( ! defined $subquery ) {
                if ( @$bu ) {
                    ( $tmp->{where_args}, $tmp->{where_stmt}, $AND_OR, $unclosed, $count ) = @{pop @$bu};
                    next WHERE;
                }
                return;
            }
            $quote_col = "(" . $subquery . ")";
        }
        if ( $quote_col eq ')' ) {
            push @$bu, [ [@{$tmp->{where_args}}], $tmp->{where_stmt}, $AND_OR, $unclosed, $count ];
            $tmp->{where_stmt} .= ")";
            $unclosed--;
            next WHERE;
        }
        if ( $count > 0 && $tmp->{where_stmt} !~ /\(\z/ ) { #
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            # Choose
            $AND_OR = $stmt_h->choose(
                [ undef, $sf->{and}, $sf->{or} ]
            );
            if ( ! defined $AND_OR ) {
                next WHERE;
            }
            $AND_OR = ' ' . $AND_OR . ' ';
        }
        if ( $quote_col eq '(' ) {
            push @$bu, [ [@{$tmp->{where_args}}], $tmp->{where_stmt}, $AND_OR, $unclosed, $count ];
            $tmp->{where_stmt} .= $AND_OR . "(";
            $AND_OR = '';
            $unclosed++;
            next WHERE;
        }
        push @$bu, [ [@{$tmp->{where_args}}], $tmp->{where_stmt}, $AND_OR, $unclosed, $count ];
        $tmp->{where_stmt} .= $AND_OR . $quote_col;
        my $ok = $sf->__set_operator_sql( $sql, $tmp, 'where', $quote_col, $stmt_type );
        if ( ! $ok ) {
            ( $tmp->{where_args}, $tmp->{where_stmt}, $AND_OR, $unclosed, $count ) = @{pop @$bu};
            next WHERE;
        }
        $count++;
    }
}


sub group_by {
    my ( $sf, $stmt_h, $sql, $stmt_type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @pre = ( undef, $sf->{i}{ok} );
    my $tmp = {
        group_by_stmt => " GROUP BY",
        group_by_cols => [],
    };

    GROUP_BY: while ( 1 ) {
        $ax->print_sql( $sql, [ $stmt_type ], $tmp );
        # Choose
        my $col = $stmt_h->choose( [ @pre, @{$sql->{cols}} ] );
        if ( ! defined $col ) {
            if ( @{$tmp->{group_by_cols}} ) {
                pop @{$tmp->{group_by_cols}};
                $tmp->{group_by_stmt} = " GROUP BY " . join ', ', @{$tmp->{group_by_cols}};
                next GROUP_BY;
            }
            return;
        }
        if ( $col eq $sf->{i}{ok} ) {
            if ( ! @{$tmp->{group_by_cols}} ) {
                $tmp->{group_by_stmt} = '';
            }
            $tmp->{orig_group_by_cols} = [];
            return $tmp;
        }
        push @{$tmp->{group_by_cols}}, $col;
        $tmp->{group_by_stmt} = " GROUP BY " . join ', ', @{$tmp->{group_by_cols}};
    }
}


sub having {
    my ( $sf, $stmt_h, $sql, $stmt_type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $aggr_cols = $sql->{aggr_cols};
    my @pre = ( undef, $sf->{i}{ok} );
    my $AND_OR = ' ';
    my $tmp = {
        having_args => [],
        having_stmt => " HAVING",
    };
    my $unclosed = 0;
    my $count = 0;
    my $bu = [];

    HAVING: while ( 1 ) {
        my @choices = ( @{$sf->{aggregate}}, map( '@' . $_, @$aggr_cols ) ); #
        if ( $sf->{o}{G}{parentheses} == 1 ) {
            unshift @choices, $unclosed ? ')' : '(';
        }
        $ax->print_sql( $sql, [ $stmt_type ], $tmp );
        # Choose
        my $aggr = $stmt_h->choose(
            [ @pre, @choices ]
        );
        if ( ! defined $aggr ) {
            if ( @$bu ) {
                ( $tmp->{having_args}, $tmp->{having_stmt}, $AND_OR, $unclosed, $count ) = @{pop @$bu};
                next HAVING;
            }
            return;
        }
        if ( $aggr eq $sf->{i}{ok} ) {
            if ( $count == 0 ) {
                $tmp->{having_stmt} = '';
            }
            if ( $unclosed == 1 ) { # close an open parentheses automatically on OK
                $tmp->{having_stmt} .= ")";
                $unclosed = 0;
            }
            return $tmp;
        }
        if ( $aggr eq ')' ) {
            push @$bu, [ [@{$tmp->{having_args}}], $tmp->{having_stmt}, $AND_OR, $unclosed, $count ];
            $tmp->{having_stmt} .= ")";
            $unclosed--;
            next HAVING;
        }
        if ( $count > 0 && $tmp->{having_stmt} !~ /\(\z/ ) {
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            # Choose
            $AND_OR = $stmt_h->choose(
                [ undef, $sf->{and}, $sf->{or} ]
            );
            if ( ! defined $AND_OR ) {
                next HAVING;
            }
            $AND_OR = ' ' . $AND_OR . ' ';
        }
        if ( $aggr eq '(' ) {
            push @$bu, [ [@{$tmp->{having_args}}], $tmp->{having_stmt}, $AND_OR, $unclosed, $count ];
            $tmp->{having_stmt} .= $AND_OR . "(";
            $AND_OR = '';
            $unclosed++;
            next HAVING;
        }
        push @$bu, [ [@{$tmp->{having_args}}], $tmp->{having_stmt}, $AND_OR, $unclosed, $count ];
        my $bu_AND_OR = $AND_OR;
        my ( $quote_col, $quote_aggr);
        if ( ( any { '@' . $_ eq $aggr } @$aggr_cols ) ) { #
            ( $quote_aggr = $aggr ) =~ s/^\@//;
            $tmp->{having_stmt} .= $AND_OR . $quote_aggr;
        }
        elsif ( $aggr eq 'COUNT(*)' ) {
            $quote_col = '*';
            $quote_aggr = $aggr;
            $tmp->{having_stmt} .= $AND_OR . $quote_aggr;
        }
        else {
            $aggr =~ s/\(\S\)\z//;
            $tmp->{having_stmt} .= $AND_OR . $aggr . "(";
            $quote_aggr          =           $aggr . "(";
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            # Choose
            $quote_col = $stmt_h->choose(
                [ undef, @{$sql->{cols}} ]
            );
            if ( ! defined $quote_col ) {
                ( $tmp->{having_args}, $tmp->{having_stmt}, $AND_OR, $unclosed, $count ) = @{pop @$bu};
                next HAVING;
            }
            $tmp->{having_stmt} .= $quote_col . ")";
            $quote_aggr         .= $quote_col . ")";
        }
        my $ok = $sf->__set_operator_sql( $sql, $tmp, 'having', $quote_aggr, $stmt_type );
        if ( ! $ok ) {
            ( $tmp->{having_args}, $tmp->{having_stmt}, $AND_OR, $unclosed, $count ) = @{pop @$bu};
            next HAVING;
        }
        $count++;
    }
}


sub order_by {
    my ( $sf, $stmt_h, $sql, $stmt_type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @pre = ( undef, $sf->{i}{ok} );
    my @cols;
    if ( @{$sql->{aggr_cols}} || @{$sql->{group_by_cols}} ) {
        @cols = ( @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}} );
        for my $stmt_type ( qw/group_by_cols aggr_cols/ ) {
            # offer also the unmodified columns:
            next if ! @{$sql->{'orig_' . $stmt_type}};
            for my $i ( 0 .. $#{$sql->{$stmt_type}} ) {
                if ( $sql->{'orig_' . $stmt_type}[$i] ne $sql->{$stmt_type}[$i] ) {
                    push @cols, $sql->{'orig_' . $stmt_type}[$i];
                }
            }
        }
    }
    else {
        @cols = ( @{$sql->{cols}}, @{$sql->{modified_cols}} );
    }
    my $col_sep = ' ';
    my $tmp = { order_by_stmt => " ORDER BY" };
    my $bu = [];

    ORDER_BY: while ( 1 ) {
        $ax->print_sql( $sql, [ $stmt_type ], $tmp );
        # Choose
        my $col = $stmt_h->choose(
            [ @pre, @cols ]
        );
        if ( ! defined $col ) {
            if ( @$bu ) {
                ( $tmp->{order_by_stmt}, $col_sep ) = @{pop @$bu};
                next ORDER_BY;
            }
            return
        }
        if ( $col eq $sf->{i}{ok} ) {
            if ( $col_sep eq ' ' ) {
                $tmp->{order_by_stmt} = '';
            }
            return $tmp;
        }
        push @$bu, [ $tmp->{order_by_stmt}, $col_sep ];
        $tmp->{order_by_stmt} .= $col_sep . $col;
        $ax->print_sql( $sql, [ $stmt_type ], $tmp );
        # Choose
        my $direction = $stmt_h->choose(
            [ undef, $sf->{asc}, $sf->{desc} ]
        );
        if ( ! defined $direction ){
            ( $tmp->{order_by_stmt}, $col_sep ) = @{pop @$bu}; #
            next ORDER_BY;
        }
        $tmp->{order_by_stmt} .= ' ' . $direction;
        $col_sep = ', ';
    }
}


sub limit_offset {
    my ( $sf, $stmt_h, $sql, $stmt_type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @pre = ( undef, $sf->{i}{ok} );
    my $tmp = {
        limit_stmt  => '',
        offset_stmt => '',
    };
    my $bu = [];

    LIMIT: while ( 1 ) {
        my ( $limit, $offset ) = ( 'LIMIT', 'OFFSET' );
        $ax->print_sql( $sql, [ $stmt_type ], $tmp );
        # Choose
        my $choice = $stmt_h->choose(
            [ @pre, $limit, $offset ]
        );
        if ( ! defined $choice ) {
            if ( @$bu ) {
                ( $tmp->{limit_stmt}, $tmp->{offset_stmt} )  = @{pop @$bu};
                next LIMIT;
            }
            return;
        }
        if ( $choice eq $sf->{i}{ok} ) {
            return $tmp;
        }
        push @$bu, [ $tmp->{limit_stmt}, $tmp->{offset_stmt} ];
        my $digits = 7;
        if ( $choice eq $limit ) {
            $tmp->{limit_stmt} = " LIMIT";
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            # Choose_a_number
            my $limit = choose_a_number( $digits,
                { name => 'LIMIT: ', mouse => $sf->{o}{table}{mouse}, clear_screen => 0 }
            );
            if ( ! defined $limit ) {
                ( $tmp->{limit_stmt}, $tmp->{offset_stmt} ) = @{pop @$bu};
                next LIMIT;
            }
            $tmp->{limit_stmt} .=  sprintf ' %d', $limit;
        }
        if ( $choice eq $offset ) {
            if ( ! $tmp->{limit_stmt} ) {
                $tmp->{limit_stmt} = " LIMIT " . ( $sf->{o}{G}{max_rows} || '9223372036854775807'  ) if $sf->{d}{driver} eq 'SQLite';   # 2 ** 63 - 1
                # MySQL 5.7 Reference Manual - SELECT Syntax - Limit clause: SELECT * FROM tbl LIMIT 95,18446744073709551615;
                $tmp->{limit_stmt} = " LIMIT " . ( $sf->{o}{G}{max_rows} || '18446744073709551615' ) if $sf->{d}{driver} eq 'mysql';    # 2 ** 64 - 1
            }
            $tmp->{offset_stmt} = " OFFSET";
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            # Choose_a_number
            my $offset = choose_a_number( $digits,
                { name => 'OFFSET: ', mouse => $sf->{o}{table}{mouse}, clear_screen => 0 }
            );
            if ( ! defined $offset ) {
                ( $tmp->{limit_stmt}, $tmp->{offset_stmt} ) = @{pop @$bu}; #
                next LIMIT;
            }
            $tmp->{offset_stmt} .= sprintf ' %d', $offset;
        }
    }
}


sub __set_operator_sql {
    my ( $sf, $sql, $tmp, $clause, $quote_col, $stmt_type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $stmt_h = Term::Choose->new( $sf->{i}{lyt_stmt_h} );
    my $trs = Term::Form->new();
    my $stmt = $clause . '_stmt';
    my $args = $clause . '_args';
    my $op_query = '=(Q';
    my @pre = ( undef );
    my @operators;
    my @opr_subquery;
    if ( $clause eq 'set' ) {
        @operators    = ( ' = ' );
        @opr_subquery = ( ' = ' );
        unshift @operators, $op_query if $sf->{o}{G}{subqueries_set};
    }
    else {
        @operators    = @{$sf->{o}{G}{operators}};
        @opr_subquery = @{$sf->{opr_subquery}};
        unshift @operators, $op_query if $sf->{o}{G}{subqueries_w_h};
    }

    OPERATOR: while( 1 ) {
        my $hist = 0;
        my $operator;
        if ( @operators == 1 ) {
            $operator = $operators[0];
        }
        else {
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            # Choose
            $operator = $stmt_h->choose( [ @pre, @operators ] );
            if ( ! defined $operator ) {
                return;
            }
            elsif ( $operator eq $op_query ) {
                $hist = 1;
                if ( @opr_subquery == 1 ) {
                    $operator = $opr_subquery[0];
                }
                else {
                    $operator = $stmt_h->choose( [ undef, @opr_subquery ] );
                    if ( ! defined $operator ) {
                        return;
                    }
                }
            }
        }
        my $bu_stmt = $tmp->{$stmt};
        if ( $operator =~ /\s%?col%?\z/ ) {
            my $arg;
            if ( $operator =~ /^(.+)\s(%?col%?)\z/ ) {
                $operator = $1;
                $arg = $2;
            }
            $operator =~ s/^\s+//;
            $tmp->{$stmt} .= ' ' . $operator;
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            # Choose
            #my $quote_col = $stmt_h->choose( $sql->{cols}, { prompt => "$operator:" } );
            my $quote_col = $stmt_h->choose( $sql->{cols}, { prompt => 'Col:' } );
            if ( ! defined $quote_col ) {
                #$tmp->{$stmt} = '';
                $tmp->{$stmt} = $bu_stmt;
                next OPERATOR;
            }
            if ( $arg !~ /%/ ) {
                $tmp->{$stmt} .= ' ' . $quote_col;
            }
            else {
                if ( ! eval {
                    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
                    my @el = map { "'$_'" } grep { length $_ } $arg =~ /^(%?)(col)(%?)\z/g;
                    my $qt_arg = $plui->concatenate( \@el );
                    $qt_arg =~ s/'col'/$quote_col/;
                    $tmp->{$stmt} .= ' ' . $qt_arg;
                    1 }
                ) {
                    $ax->print_error_message( $@, $operator . ' ' . $arg );
                    $tmp->{$stmt} = $bu_stmt;
                    next OPERATOR;
                }
            }
        }
        elsif ( $operator =~ /REGEXP(_i)?\z/ ) {
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            $tmp->{$stmt} =~ s/ (?: (?<=\() | \s ) \Q$quote_col\E\z//x;
            my $do_not_match_regexp = $operator =~ /^NOT/       ? 1 : 0;
            my $case_sensitive      = $operator =~ /REGEXP_i\z/ ? 0 : 1;
            if ( ! eval {
                my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
                my $regex_op = $plui->regexp( $quote_col, $do_not_match_regexp, $case_sensitive );
                $regex_op =~ s/^\s// if $tmp->{$stmt} =~ /\(\z/;
                $tmp->{$stmt} .= $regex_op;
                push @{$tmp->{$args}}, '...';
                1 }
            ) {
                $ax->print_error_message( $@, $operator );
                $tmp->{$stmt} = $bu_stmt;
                next OPERATOR;
            }
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            # Readline
            my $value = $trs->readline( 'Pattern: ' );
            if ( ! defined $value ) {
                $tmp->{$stmt} = $bu_stmt;
                next OPERATOR;
            }
            $value = '^$' if ! length $value;
            pop @{$tmp->{$args}};
            push @{$tmp->{$args}}, $value;
        }
        elsif ( $operator =~ /^IS\s(?:NOT\s)?NULL\z/ ) {
            $tmp->{$stmt} .= ' ' . $operator;
        }
        elsif ( $operator =~ /^(?:NOT\s)?IN\z/ ) {
            $tmp->{$stmt} .= ' ' . $operator;
            if ( $hist ) {
                my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );  # sub
                my $subquery = $sq->choose_subquery( $sql, $tmp, $stmt_type );
                if ( ! defined $subquery ) {
                    $tmp->{$stmt} = $bu_stmt;
                    next OPERATOR;
                }
                $tmp->{$stmt} .= " (" . $subquery . ")";
            }
            else {
                my $col_sep = '';
                $tmp->{$stmt} .= '(';

                IN: while ( 1 ) {
                    $ax->print_sql( $sql, [ $stmt_type ], $tmp );
                    # Readline
                    my $value = $trs->readline( 'Value: ' );
                    if ( ! defined $value ) {
                        $tmp->{$stmt} = $bu_stmt;
                        next OPERATOR;
                    }
                    if ( $value eq '' ) {
                        if ( $col_sep eq '' ) {
                            $tmp->{$stmt} = $bu_stmt;
                            next OPERATOR;
                        }
                        $tmp->{$stmt} .= ')';
                        last IN;
                    }
                    $tmp->{$stmt} .= $col_sep . '?';
                    push @{$tmp->{$args}}, $value;
                    $col_sep = ',';
                }
            }
        }
        elsif ( $operator =~ /^(?:NOT\s)?BETWEEN\z/ ) {
            $tmp->{$stmt} .= ' ' . $operator;
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            # Readline
            my $value_1 = $trs->readline( 'Value 1: ' );
            if ( ! defined $value_1 ) {
                $tmp->{$stmt} = $bu_stmt;
                next OPERATOR;
            }
            $tmp->{$stmt} .= ' ' . '?' .      ' AND';
            push @{$tmp->{$args}}, $value_1;
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            # Readline
            my $value_2 = $trs->readline( 'Value 2: ' );
            if ( ! defined $value_2 ) {
                $tmp->{$stmt} = $bu_stmt;
                next OPERATOR;
            }
            $tmp->{$stmt} .= ' ' . '?';
            push @{$tmp->{$args}}, $value_2;
        }
        else {
            $operator =~ s/^\s+|\s+\z//g;
            $tmp->{$stmt} .= ' ' . $operator;
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            if ( $hist ) {
                my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );  # sub
                my $subquery = $sq->choose_subquery( $sql, $tmp, $stmt_type );
                if ( ! defined $subquery ) {
                    $tmp->{$stmt} = $bu_stmt;
                    next OPERATOR;
                }
                $tmp->{$stmt} .= " (" . $subquery . ")";
            }
            else {
                my $prompt = $operator =~ /^(?:NOT\s)?LIKE\z/ ? 'Pattern: ' : 'Value: '; #
                # Readline
                my $value = $trs->readline( $prompt );
                if ( ! defined $value ) {
                    $tmp->{$stmt} = $bu_stmt;
                    next OPERATOR;
                }
                $tmp->{$stmt} .= ' ' . '?';
                push @{$tmp->{$args}}, $value;
            }
        }
        last OPERATOR; #
    }
    return 1; #
}



1;


__END__
