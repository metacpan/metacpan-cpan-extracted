package # hide from PAUSE
App::DBBrowser::Table::Substatements;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '2.006';

use List::MoreUtils   qw( any );

use Term::Choose           qw( choose );
use Term::Choose::LineFold qw(print_columns);
use Term::Choose::Util     qw( choose_a_file choose_a_subset choose_a_number insert_sep term_width );
use Term::Form             qw();

use App::DBBrowser::Auxil;

use if $^O eq 'MSWin32', 'Win32::Console::ANSI'; #


sub new {
    my ( $class, $info, $opt ) = @_;
    my $sf = {
        i => $info,
        o => $opt
    };
    $sf->{i}{aggregate} = [ "AVG(X)", "COUNT(X)", "COUNT(*)", "MAX(X)", "MIN(X)", "SUM(X)" ]; ###
    $sf->{i}{opr_subquery} = [ "IN", "NOT IN", " = ", " != ", " < ", " > ", " >= ", " <= " ];
    # my ( $DISTINCT, $ALL, $ASC, $DESC, $AND, $OR ) = ( "DISTINCT", "ALL", "ASC", "DESC", "AND", "OR" );
    bless $sf, $class;
}


sub __add_aggregate_substmt {
    my ( $sf, $dbh, $sql, $tmp,  $stmt_type, $cols_type ) = @_;
    my $stmt_h = Term::Choose->new( $sf->{i}{lyt_stmt_h} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my @pre = ( undef );
    push @pre, $sf->{i}{ok} if $cols_type eq 'aggr_cols';
    my $i = @{$tmp->{$cols_type}};
    $ax->print_sql( $sql, [ $stmt_type ], $tmp );
    # Choose
    my $aggr = $stmt_h->choose(
        [ @pre, @{$sf->{i}{aggregate}} ]
    );
    if ( ! defined $aggr ) {
        return;
    }
    elsif ( $aggr eq $sf->{i}{ok} ) {
        return $aggr;
    }
    if ( $aggr eq 'COUNT(*)' ) {
        $tmp->{$cols_type}[$i] = $aggr;
    }
    else {
        $aggr =~ s/\(\S\)\z//; #
        $tmp->{$cols_type}[$i] = $aggr . "(";
        if ( $aggr eq 'COUNT' ) {
            my ( $DISTINCT, $ALL ) = ( "DISTINCT", "ALL" ); ##
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            # Choose
            my $all_or_distinct = $stmt_h->choose(
                [ undef, $ALL, $DISTINCT ]
            );
            if ( ! defined $all_or_distinct ) {
                return;
            }
            if ( $all_or_distinct eq $DISTINCT ) {
                $tmp->{$cols_type}[$i] .= $DISTINCT . ' '; #
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
        $tmp->{$cols_type}[$i] .= $f_col . ")";
    }
    my $alias = $ax->__alias( $dbh, $tmp->{$cols_type}[$i] );
    if ( defined $alias && length $alias ) {
        $tmp->{alias}{$tmp->{$cols_type}[$i]} = $ax->quote_col_qualified( $dbh, [ $alias ] );
    }
    return 1;
}



sub columns {
    my ( $sf, $dbh, $stmt_h, $sql, $stmt_type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my $tmp = {
        chosen_cols    => [],
        select_type    => 'chosen_cols',
        select_sq_args => [],
        alias          => { %{$sql->{alias}} },
    };
    my $aggr_func = '&';
    my $sub_query = '(Q';
    my $bu = [];
    my @pre = ( undef, $sf->{i}{ok} );
    push @pre, $aggr_func if $sf->{o}{G}{expert_aggregate};
    push @pre, $sub_query if $sf->{o}{G}{expert_subqueries};

    COLUMNS: while ( 1 ) {
        my $choices = [ @pre, @{$sql->{cols}} ];
        $ax->print_sql( $sql, [ $stmt_type ], $tmp );
        # Choose
        my $col = $stmt_h->choose(
            $choices
        );
        if ( ! defined $col ) {
            if ( @$bu ) {
                ( $tmp->{chosen_cols}, $tmp->{select_sq_args}, $tmp->{alias} ) = @{pop @$bu};
                next COLUMNS;
            }
            return;
        }
        elsif ( $col eq $sf->{i}{ok} ) {
            $tmp->{select_type}      = '*' if ! @{$tmp->{chosen_cols}};
            $tmp->{orig_chosen_cols} = [];
            $tmp->{modified_cols}    = [];
            return $tmp;
        }
        push @$bu, [ [ @{$tmp->{chosen_cols}} ], [ @{$tmp->{select_sq_args}} ], { %{$tmp->{alias}} } ];
        if ( $col eq $sub_query ) {
            my $idx = $sf->__choose_hist_idx();
            if ( ! defined $idx ) {
                ( $tmp->{chosen_cols}, $tmp->{select_sq_args}, $tmp->{alias} ) = @{pop @$bu};
                next COLUMNS;
            }
            my $subquery = "(" . $sf->{i}{stmt_history}[$idx][0] . ")"; #
            my $values   = $sf->{i}{stmt_history}[$idx][1];
            push @{$tmp->{chosen_cols}}, $subquery ;
            push @{$tmp->{select_sq_args}}, @$values; #
            my $filled = $subquery;
            for my $val ( @$values ) {
                $filled =~ s/\?/$val/;
            }
            my $alias = $ax->__alias( $dbh, $filled );
            if ( defined $alias && length $alias ) {
                $tmp->{alias}{$filled} = $ax->quote_col_qualified( $dbh, [ $alias ] );
            }
            next COLUMNS;
        }
        elsif ( $col eq $aggr_func ) {
            my $ret = $sf->__add_aggregate_substmt( $dbh, $sql, $tmp, $stmt_type, 'chosen_cols' );
            if ( ! $ret ) {
                ( $tmp->{chosen_cols}, $tmp->{select_sq_args}, $tmp->{alias} ) = @{pop @$bu};
                next COLUMNS;
            }
        }
        else {
            push @{$tmp->{chosen_cols}}, $col;
        }
    }
}

sub distinc {
    my ( $sf, $stmt_h, $sql, $stmt_type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my ( $DISTINCT, $ALL ) = ( "DISTINCT", "ALL" );
    my @pre = ( undef, $sf->{i}{ok} );
    my $tmp = { distinct_stmt => '' };

    DISTINCT: while ( 1 ) {
        my $choices = [ @pre, $DISTINCT, $ALL ];
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
    my ( $sf, $dbh, $stmt_h, $sql, $stmt_type ) = @_;
    my $group_by_cols = $sql->{group_by_cols};
    my $tmp = {
        aggr_cols   => [],
        select_type => 'aggr_and_group_by_cols',
    };

    AGGREGATE: while ( 1 ) {
        my $ret = $sf->__add_aggregate_substmt( $dbh, $sql, $tmp, $stmt_type, 'aggr_cols' );
        if ( ! $ret ) {
            if ( @{$tmp->{aggr_cols}} ) {
                my $aggr = pop @{$tmp->{aggr_cols}};
                delete $tmp->{alias}{$aggr} if exists $tmp->{alias}{$aggr};
                next AGGREGATE;
            }
            return;
        }
        elsif ( $ret eq $sf->{i}{ok} ) {
            if ( ! @{$tmp->{aggr_cols}} && ! @$group_by_cols ) {
                $tmp->{select_type} = '*';
            }
            $tmp->{orig_aggr_cols} = [];
            return $tmp;
        }
    }
}

sub set {
    my ( $sf, $stmt_h, $sql, $stmt_type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
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
            [ @pre, @{$sql->{cols}} ],
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
        $tmp->{set_stmt} .= $col_sep . $col . ' =';
        $ax->print_sql( $sql, [ $stmt_type ], $tmp );
        # Readline
        my $value = $trs->readline( $col . ': ' );
        if ( ! defined $value ) {
            if ( @$bu ) {
                ( $tmp->{set_args}, $tmp->{set_stmt}, $col_sep ) = @{pop @$bu};
                next SET;
            }
            return;
        }
        $tmp->{set_stmt} .= ' ' . '?';
        push @{$tmp->{set_args}}, $value;
        $col_sep = ', ';
    }
}

sub where {
    my ( $sf, $stmt_h, $sql, $stmt_type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
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
    push @pre, $sq_col if $sf->{o}{G}{expert_subqueries};

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
        if ( defined $quote_col && $quote_col eq $sq_col ) {
            my $idx = $sf->__choose_hist_idx();
            if ( ! defined $idx ) {
                $quote_col = undef;
                next WHERE; ####
            }
            else {
                $quote_col = "(" . $sf->{i}{stmt_history}[$idx][0] . ")"; #
                push @{$tmp->{where_args}}, @{$sf->{i}{stmt_history}[$idx][1]}; #
            }
        }
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
            return $tmp;
        }
        if ( $quote_col eq ')' ) {
            push @$bu, [ [@{$tmp->{where_args}}], $tmp->{where_stmt}, $AND_OR, $unclosed, $count ];
            $tmp->{where_stmt} .= ")";
            $unclosed--;
            next WHERE;
        }
        if ( $count > 0 && $tmp->{where_stmt} !~ /\(\z/ ) { #
            my ( $AND, $OR ) = ( "AND", "OR" );
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            # Choose
            $AND_OR = $stmt_h->choose(
                [ undef, $AND, $OR ]
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
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my @pre = ( undef, $sf->{i}{ok} );
    my $tmp = {
        group_by_stmt => " GROUP BY",
        group_by_cols => [],
        select_type   => 'aggr_and_group_by_cols',
    };

    GROUP_BY: while ( 1 ) {
        $ax->print_sql( $sql, [ $stmt_type ], $tmp );
        # Choose
        my $col = $stmt_h->choose(
            [ @pre, @{$sql->{cols}} ],
            { no_spacebar => [ 0 .. $#pre ] }
        );
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
                if ( ! @{$tmp->{aggr_cols}} ) {
                    $tmp->{select_type} = '*';
                }
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
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
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
        my @choices = ( @{$sf->{i}{aggregate}}, map( '@' . $_, @$aggr_cols ) ); #
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
            return $tmp;
        }
        if ( $aggr eq ')' ) {
            push @$bu, [ [@{$tmp->{having_args}}], $tmp->{having_stmt}, $AND_OR, $unclosed, $count ];
            $tmp->{having_stmt} .= ")";
            $unclosed--;
            next HAVING;
        }
        if ( $count > 0 && $tmp->{having_stmt} !~ /\(\z/ ) {
            my ( $AND, $OR ) = ( "AND", "OR" );
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            # Choose
            $AND_OR = $stmt_h->choose(
                [ undef, $AND, $OR ]
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
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my @pre = ( undef, $sf->{i}{ok} );
    my @cols;
    if ( $sql->{select_type} eq '*' || $sql->{select_type} eq 'chosen_cols' ) {
        @cols = ( @{$sql->{cols}}, @{$sql->{modified_cols}} );
    }
    else {
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
        my ( $ASC, $DESC ) = ( "ASC", "DESC" );
        $ax->print_sql( $sql, [ $stmt_type ], $tmp );
        # Choose
        my $direction = $stmt_h->choose(
            [ undef, $ASC, $DESC ]
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
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
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
                $tmp->{limit_stmt} = " LIMIT " . ( $sf->{o}{G}{max_rows} || '9223372036854775807'  ) if $sf->{i}{driver} eq 'SQLite';   # 2 ** 63 - 1
                # MySQL 5.7 Reference Manual - SELECT Syntax - Limit clause: SELECT * FROM tbl LIMIT 95,18446744073709551615;
                $tmp->{limit_stmt} = " LIMIT " . ( $sf->{o}{G}{max_rows} || '18446744073709551615' ) if $sf->{i}{driver} eq 'mysql';    # 2 ** 64 - 1
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


sub __choose_hist_idx {
    my ( $sf ) = @_;
    my @choices;
    for my $e ( @{$sf->{i}{stmt_history}} ) {
        my $stmt = $e->[0];
        for my $val ( @{$e->[1]} ) {
            $stmt =~ s/\?/$val/;
        }
        push @choices, $stmt;
    }
    my @pre = ( undef );
    HIST: while ( 1 ) {
        my $idx = choose( [ @pre, @choices ], { layout => 3, index => 1, undef => 'BACK' } ); ##
        if ( ! $idx ) {
            return;
        }
        $idx -= @pre;
        if ( print_columns( $choices[$idx] ) > term_width() ) {
            my $ok = choose(
                [ undef, 'Confirm' ],
                { prompt => $choices[$idx], undef => '<<' }
            );
            if ( ! $ok ) {
                next HIST;
            }
        }
        return $idx;
    }
}


sub __set_operator_sql {
    my ( $sf, $sql, $tmp, $clause, $quote_col, $stmt_type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my $stmt_h = Term::Choose->new( $sf->{i}{lyt_stmt_h} );
    my $trs = Term::Form->new();
    my $stmt = $clause . '_stmt';
    my $args = $clause . '_args';
    my $op_query = '=(Q';
    my @pre = ( undef );
    push @pre, $op_query if $sf->{o}{G}{expert_subqueries};

    OPERATOR: while( 1 ) {
        my $hist = 0;
        $ax->print_sql( $sql, [ $stmt_type ], $tmp );
        # Choose
        my $operator = $stmt_h->choose( [ @pre, @{$sf->{o}{G}{operators}} ] );
        if ( ! defined $operator ) {
            return;
        }
        elsif ( $operator eq $op_query ) {
            $hist = 1;
            $operator = $stmt_h->choose( [ undef, @{$sf->{i}{opr_subquery}} ] );
            if ( ! defined $operator ) {
                return;
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
            my $quote_col = $stmt_h->choose( $sql->{cols}, { prompt => "$operator:" } );
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
                    my $obj_db = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
                    my @el = map { "'$_'" } grep { length $_ } $arg =~ /^(%?)(col)(%?)\z/g;
                    my $qt_arg = $obj_db->concatenate( \@el );
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
            # Readline
            my $value = $trs->readline( 'Pattern: ' );
            if ( ! defined $value ) {
                $tmp->{$stmt} = $bu_stmt;
                next OPERATOR;
            }
            $value = '^$' if ! length $value;
            $tmp->{$stmt} =~ s/\s\Q$quote_col\E\z//;
            my $do_not_match_regexp = $operator =~ /^NOT/       ? 1 : 0;
            my $case_sensitive      = $operator =~ /REGEXP_i\z/ ? 0 : 1;
            if ( ! eval {
                my $obj_db = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
                $tmp->{$stmt} .= $obj_db->regexp( $quote_col, $do_not_match_regexp, $case_sensitive );
                push @{$tmp->{$args}}, $value;
                1 }
            ) {
                $ax->print_error_message( $@, $operator );
                $tmp->{$stmt} = $bu_stmt;
                next OPERATOR;
            }
        }
        elsif ( $operator =~ /^IS\s(?:NOT\s)?NULL\z/ ) {
            $tmp->{$stmt} .= ' ' . $operator;
        }
        elsif ( $operator =~ /^(?:NOT\s)?IN\z/ ) {
            $tmp->{$stmt} .= ' ' . $operator;
            if ( $hist ) {
                my $idx = $sf->__choose_hist_idx();
                if ( ! defined $idx ) {
                    $tmp->{$stmt} = $bu_stmt;
                    next OPERATOR;
                }
                $tmp->{$stmt} .= "(" . $sf->{i}{stmt_history}[$idx][0] . ")"; #
                push @{$tmp->{$args}}, @{$sf->{i}{stmt_history}[$idx][1]};     #
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
                my $idx = $sf->__choose_hist_idx();
                if ( ! defined $idx ) {
                    $tmp->{$stmt} = $bu_stmt;
                    next OPERATOR;
                }
                $tmp->{$stmt} .= " (" . $sf->{i}{stmt_history}[$idx][0] . ")"; #
                push @{$tmp->{$args}}, @{$sf->{i}{stmt_history}[$idx][1]};     #
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
