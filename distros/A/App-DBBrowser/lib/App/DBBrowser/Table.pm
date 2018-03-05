package # hide from PAUSE
App::DBBrowser::Table;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '2.003';

use Clone           qw( clone );
use List::MoreUtils qw( any first_index );

use Term::Choose       qw( choose );
use Term::Choose::Util qw( choose_a_number insert_sep );
use Term::Form         qw();

use if $^O eq 'MSWin32', 'Win32::Console::ANSI';

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;
use App::DBBrowser::Table::Functions;
#use App::DBBrowser::Table::Insert;  # "require"-d


sub new {
    my ( $class, $info, $opt ) = @_;
    bless { i => $info, o => $opt }, $class;
}


sub on_table {
    my ( $sf, $sql, $dbh ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my $stmt_h = Term::Choose->new( $sf->{i}{lyt_stmt_h} );
    my $sub_stmts = {
        Select => [ qw( print_tbl columns aggregate distinct where group_by having order_by limit functions lock ) ],
        Delete => [ qw( commit     where functions ) ],
        Update => [ qw( commit set where functions ) ],
    };
    my $lk = [ '  Lk0', '  Lk1' ];
    my %cu = (
        commit          => '  CONFIRM Stmt',
        hidden          => 'Customize:',
        print_tbl       => 'Print TABLE',
        columns         => '- SELECT',
        set             => '- SET',
        aggregate       => '- AGGREGATE',
        distinct        => '- DISTINCT',
        where           => '- WHERE',
        group_by        => '- GROUP BY',
        having          => '- HAVING',
        order_by        => '- ORDER BY',
        limit           => '- LIMIT',
        lock            => $lk->[$sf->{i}{lock}],
        functions       => '  Func',
    );
    my @aggregate = ( "AVG(X)", "COUNT(X)", "COUNT(*)", "MAX(X)", "MIN(X)", "SUM(X)" );
    my ( $DISTINCT, $ALL, $ASC, $DESC, $AND, $OR ) = ( "DISTINCT", "ALL", "ASC", "DESC", "AND", "OR" );
    if ( $sf->{i}{lock} == 0 ) {
        $ax->reset_sql( $sql );
    }
    my $stmt_type = 'Select';
    my $backup_sql;
    my $old_idx = 1;
    my @pre = ( undef, $sf->{i}{ok} );

    CUSTOMIZE: while ( 1 ) {
        $backup_sql = clone( $sql ) if $stmt_type eq 'Select';
        my $choices = [ $cu{hidden}, undef, @cu{@{$sub_stmts->{$stmt_type}}} ];
        $ax->print_sql( $sql, [ $stmt_type ] );
        # Choose
        $ENV{TC_RESET_AUTO_UP} = 0;
        my $idx = choose(
            $choices,
            { %{$sf->{i}{lyt_stmt_v}}, prompt => '', index => 1, default => $old_idx,
            undef => $stmt_type ne 'Select' ? $sf->{i}{_back} : $sf->{i}{back} }
        );
        if ( ! defined $idx || ! defined $choices->[$idx] ) {
            if ( $stmt_type eq 'Select'  ) {
                last CUSTOMIZE;
            }
            elsif( $stmt_type eq 'Delete' || $stmt_type eq 'Update' ) {
                if ( $sql->{where_stmt} || $sql->{set_stmt} ) {
                    $ax->reset_sql( $sql );
                }
                else {
                    $stmt_type = 'Select';
                    $old_idx = 1;
                    #$sql = clone $backup_sql;
                    $sql = $backup_sql;
                }
                next CUSTOMIZE;
            }
            else { die $stmt_type }
        }
        my $custom = $choices->[$idx];
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 1;
                next CUSTOMIZE;
            }
            else {
                $old_idx = $idx;
            }
        }
        delete $ENV{TC_RESET_AUTO_UP};
         if ( $custom eq $cu{'lock'} ) {
            $sf->{i}{lock} = ! $sf->{i}{lock};
            $cu{lock} = $lk->[ $sf->{i}{lock} ];
            if ( ! $sf->{i}{lock} ) {
                $ax->reset_sql( $sql );
            }
        }
        elsif ( $custom eq $cu{'columns'} ) {
            if ( ! ( $sql->{select_type} eq '*' || $sql->{select_type} eq 'chosen_cols' ) ) {
                $ax->reset_sql( $sql );
            }
            my $prev_chosen_cols = $sql->{chosen_cols};
            my $prev_select_type = $sql->{select_type};
            $sql->{chosen_cols} = [];
            $sql->{select_type} = 'chosen_cols';

            COLUMNS: while ( 1 ) {
                my $choices = [ @pre, @{$sql->{cols}} ];
                $ax->print_sql( $sql, [ $stmt_type ] );
                # Choose
                my @chosen_cols = $stmt_h->choose(
                    $choices,
                    { no_spacebar => [ 0 .. $#pre ] }
                );
                if ( ! @chosen_cols || ! defined $chosen_cols[0] ) {
                    if ( @{$sql->{chosen_cols}} ) {
                        pop @{$sql->{chosen_cols}};
                        next COLUMNS;
                    }
                    $sql->{chosen_cols} = $prev_chosen_cols;
                    $sql->{select_type} = $prev_select_type;
                    last COLUMNS;
                }
                if ( $chosen_cols[0] eq $sf->{i}{ok} ) {
                    shift @chosen_cols;
                    for my $col ( @chosen_cols ) {
                        push @{$sql->{chosen_cols}}, $col;
                    }
                    if ( ! @{$sql->{chosen_cols}} ) {
                        $sql->{select_type} = '*';
                    }
                    delete $sql->{orig_cols}{chosen_cols};
                    $sql->{modified_cols} = [];
                    last COLUMNS;
                }
                for my $col ( @chosen_cols ) {
                    push @{$sql->{chosen_cols}}, $col;
                }
            }
        }
        elsif ( $custom eq $cu{'distinct'} ) {
            my $prev_distinct_stmt = $sql->{distinct_stmt};
            $sql->{distinct_stmt} = '';

            DISTINCT: while ( 1 ) {
                my $choices = [ @pre, $DISTINCT, $ALL ];
                $ax->print_sql( $sql, [ $stmt_type ] );
                # Choose
                my $select_distinct = $stmt_h->choose(
                    $choices
                );
                if ( ! defined $select_distinct ) {
                    if ( $sql->{distinct_stmt} ) {
                        $sql->{distinct_stmt} = '';
                        next DISTINCT;
                    }
                    $sql->{distinct_stmt} = $prev_distinct_stmt;
                    last DISTINCT;
                }
                elsif ( $select_distinct eq $sf->{i}{ok} ) {
                    last DISTINCT;
                }
                $sql->{distinct_stmt} = ' ' . $select_distinct;
            }
        }
        elsif ( $custom eq $cu{'aggregate'} ) {
            if ( $sql->{select_type} eq '*' || $sql->{select_type} eq 'chosen_cols' ) {
                $ax->reset_sql( $sql );
            }
            my $prev_aggr_cols   = $sql->{aggr_cols};
            my $prev_select_type = $sql->{select_type};
            $sql->{aggr_cols} = [];
            $sql->{select_type} = 'aggr_and_group_by_cols';

            AGGREGATE: while ( 1 ) {
                $ax->print_sql( $sql, [ $stmt_type ] );
                # Choose
                my $aggr = $stmt_h->choose(
                    [ @pre, @aggregate ]
                );
                if ( ! defined $aggr ) {
                    if ( @{$sql->{aggr_cols}} ) {
                        pop @{$sql->{aggr_cols}};
                        next AGGREGATE;
                    }
                    $sql->{aggr_cols}   = $prev_aggr_cols;
                    $sql->{select_type} = $prev_select_type;
                    last AGGREGATE;
                }
                if ( $aggr eq $sf->{i}{ok} ) {
                    if ( ! @{$sql->{aggr_cols}} && ! @{$sql->{group_by_cols}} ) {
                        $sql->{select_type} = '*';
                    }
                    delete $sql->{orig_cols}{aggr_cols};
                    last AGGREGATE;
                }
                my $i = @{$sql->{aggr_cols}};
                if ( $aggr eq 'COUNT(*)' ) {
                    $sql->{aggr_cols}[$i] = $aggr;
                }
                else {
                    $aggr =~ s/\(\S\)\z//; #
                    $sql->{aggr_cols}[$i] = $aggr . "(";
                    if ( $aggr eq 'COUNT' ) {
                        $ax->print_sql( $sql, [ $stmt_type ] );
                        # Choose
                        my $all_or_distinct = $stmt_h->choose(
                            [ undef, $ALL, $DISTINCT ]
                        );
                        if ( ! defined $all_or_distinct ) {
                            pop @{$sql->{aggr_cols}};
                            next AGGREGATE;
                        }
                        if ( $all_or_distinct eq $DISTINCT ) {
                            $sql->{aggr_cols}[$i] .= $DISTINCT . ' ';
                        }
                    }
                    $ax->print_sql( $sql, [ $stmt_type ] );
                    # Choose
                    my $quote_col = $stmt_h->choose(
                        [ undef, @{$sql->{cols}} ]
                    );
                    if ( ! defined $quote_col ) {
                        pop @{$sql->{aggr_cols}};
                        next AGGREGATE;
                    }
                    $sql->{aggr_cols}[$i] .= $quote_col . ")";
                }
            }
        }
        elsif ( $custom eq $cu{'set'} ) {
            my $trs = Term::Form->new();
            my $prev_set_args = $sql->{set_args};
            my $prev_set_stmt = $sql->{set_stmt};
            my $col_sep = ' ';
            $sql->{set_args} = [];
            $sql->{set_stmt} = " SET";
            my $bu = [];

            SET: while ( 1 ) {
                $ax->print_sql( $sql, [ $stmt_type ] );
                # Choose
                my $col = $stmt_h->choose(
                    [ @pre, @{$sql->{cols}} ],
                );
                if ( ! defined $col ) {
                    if ( @$bu ) {
                        ( $sql->{set_args}, $sql->{set_stmt}, $col_sep ) = @{pop @$bu};
                        next SET;
                    }
                    $sql->{set_args} = $prev_set_args;
                    $sql->{set_stmt} = $prev_set_stmt;
                    last SET;
                }
                if ( $col eq $sf->{i}{ok} ) {
                    if ( $col_sep eq ' ' ) {
                        $sql->{set_stmt} = '';
                    }
                    last SET;
                }
                push @$bu, [ [@{$sql->{set_args}}], $sql->{set_stmt}, $col_sep ];
                $sql->{set_stmt} .= $col_sep . $col . ' =';
                $ax->print_sql( $sql, [ $stmt_type ] );
                # Readline
                my $value = $trs->readline( $col . ': ' );
                if ( ! defined $value ) {
                    if ( @$bu ) {
                        ( $sql->{set_args}, $sql->{set_stmt}, $col_sep ) = @{pop @$bu};
                        next SET;
                    }
                    $sql->{set_args} = $prev_set_args;
                    $sql->{set_stmt} = $prev_set_stmt;
                    last SET;
                }
                $sql->{set_stmt} .= ' ' . '?';
                push @{$sql->{set_args}}, $value;
                $col_sep = ', ';
            }
        }
        elsif ( $custom eq $cu{'where'} ) {
            my @cols = ( @{$sql->{cols}}, @{$sql->{modified_cols}} );
            my $AND_OR = ' ';
            my $prev_where_args = $sql->{where_args};
            my $prev_where_stmt = $sql->{where_stmt};
            $sql->{where_args} = [];
            $sql->{where_stmt} = " WHERE";
            my $unclosed = 0;
            my $count = 0;
            my $bu = [];

            WHERE: while ( 1 ) {
                my @choices = @cols;
                if ( $sf->{o}{G}{parentheses_w} == 1 ) {
                    unshift @choices, $unclosed ? ')' : '(';
                }
                $ax->print_sql( $sql, [ $stmt_type ] );
                # Choose
                my $quote_col = $stmt_h->choose(
                    [ @pre, @choices ]
                );
                if ( ! defined $quote_col ) {
                    if ( @$bu ) {
                        ( $sql->{where_args}, $sql->{where_stmt}, $AND_OR, $unclosed, $count ) = @{pop @$bu};
                        next WHERE;
                    }
                    # use of "restore $backup_sql" would be wrong in Delete and Update
                    $sql->{where_args} = $prev_where_args;
                    $sql->{where_stmt} = $prev_where_stmt;
                    last WHERE;
                }
                if ( $quote_col eq $sf->{i}{ok} ) {
                    if ( $count == 0 ) {
                        $sql->{where_stmt} = '';
                    }
                    last WHERE;
                }
                if ( $quote_col eq ')' ) {
                    push @$bu, [ [@{$sql->{where_args}}], $sql->{where_stmt}, $AND_OR, $unclosed, $count ];
                    $sql->{where_stmt} .= ")";
                    $unclosed--;
                    next WHERE;
                }
                if ( $count > 0 && $sql->{where_stmt} !~ /\(\z/ ) { #
                    $ax->print_sql( $sql, [ $stmt_type ] );
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
                    push @$bu, [ [@{$sql->{where_args}}], $sql->{where_stmt}, $AND_OR, $unclosed, $count ];
                    $sql->{where_stmt} .= $AND_OR . "(";
                    $AND_OR = '';
                    $unclosed++;
                    next WHERE;
                }
                push @$bu, [ [@{$sql->{where_args}}], $sql->{where_stmt}, $AND_OR, $unclosed, $count ];
                $sql->{where_stmt} .= $AND_OR . $quote_col;
                my $ok = $sf->__set_operator_sql( $sql, 'where', $quote_col, $stmt_type );
                if ( ! $ok ) {
                    ( $sql->{where_args}, $sql->{where_stmt}, $AND_OR, $unclosed, $count ) = @{pop @$bu};
                    next WHERE;
                }
                $count++;
            }
        }
        elsif ( $custom eq $cu{'group_by'} ) {
            if ( $sql->{select_type} eq '*' || $sql->{select_type} eq 'chosen_cols' ) {
                $ax->reset_sql( $sql );
            }
            my $prev_select_type   = $sql->{select_type};
            my $prev_group_by_stmt = $sql->{group_by_stmt};
            my $prev_group_by_cols = $sql->{group_by_cols};
            $sql->{group_by_stmt} = " GROUP BY";
            $sql->{group_by_cols} = [];
            $sql->{select_type} = 'aggr_and_group_by_cols';

            GROUP_BY: while ( 1 ) {
                $ax->print_sql( $sql, [ $stmt_type ] );
                # Choose
                my $col = $stmt_h->choose(
                    [ @pre, @{$sql->{cols}} ],
                    { no_spacebar => [ 0 .. $#pre ] }
                );
                if ( ! defined $col ) {
                    if ( @{$sql->{group_by_cols}} ) {
                        pop @{$sql->{group_by_cols}};
                        $sql->{group_by_stmt} = " GROUP BY " . join ', ', @{$sql->{group_by_cols}};
                        next GROUP_BY;
                    }
                    $sql->{group_by_stmt} = $prev_group_by_stmt;
                    $sql->{group_by_cols} = $prev_group_by_cols;
                    $sql->{select_type}   = $prev_select_type;
                    last GROUP_BY;
                }
                if ( $col eq $sf->{i}{ok} ) {
                    if ( ! @{$sql->{group_by_cols}} ) {
                        $sql->{group_by_stmt} = '';
                        if ( ! @{$sql->{aggr_cols}} ) {
                            $sql->{select_type} = '*';
                            #$sql->{group_by_stmt} = $prev_group_by_stmt; ###
                            #$sql->{group_by_cols} = $prev_group_by_cols; ###
                            #$sql->{select_type}   = $prev_select_type;   ###
                            last GROUP_BY;
                        }
                    }
                    delete $sql->{orig_cols}{group_by_cols}; #
                    last GROUP_BY;
                }
                push @{$sql->{group_by_cols}}, $col;
                $sql->{group_by_stmt} = " GROUP BY " . join ', ', @{$sql->{group_by_cols}};
            }
        }
        elsif ( $custom eq $cu{'having'} ) {
            my $AND_OR = ' ';
            my $prev_having_args = $sql->{having_args};
            my $prev_having_stmt = $sql->{having_stmt};
            $sql->{having_args} = [];
            $sql->{having_stmt} = " HAVING";
            my $unclosed = 0;
            my $count = 0;
            my $bu = [];

            HAVING: while ( 1 ) {
                my @choices = ( @aggregate, map( '@' . $_, @{$sql->{aggr_cols}} ) ); #
                if ( $sf->{o}{G}{parentheses_h} == 1 ) {
                    unshift @choices, $unclosed ? ')' : '(';
                }
                $ax->print_sql( $sql, [ $stmt_type ] );
                # Choose
                my $aggr = $stmt_h->choose(
                    [ @pre, @choices ]
                );
                if ( ! defined $aggr ) {
                    if ( @$bu ) {
                        ( $sql->{having_args}, $sql->{having_stmt}, $AND_OR, $unclosed, $count ) = @{pop @$bu};
                        next HAVING;
                    }
                    $sql->{having_args} = $prev_having_args;
                    $sql->{having_stmt} = $prev_having_stmt;
                    last HAVING;
                }
                if ( $aggr eq $sf->{i}{ok} ) {
                    if ( $count == 0 ) {
                        $sql->{having_stmt} = '';
                    }
                    last HAVING;
                }
                if ( $aggr eq ')' ) {
                    push @$bu, [ [@{$sql->{having_args}}], $sql->{having_stmt}, $AND_OR, $unclosed, $count ];
                    $sql->{having_stmt} .= ")";
                    $unclosed--;
                    next HAVING;
                }
                if ( $count > 0 && $sql->{having_stmt} !~ /\(\z/ ) {
                    $ax->print_sql( $sql, [ $stmt_type ] );
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
                    push @$bu, [ [@{$sql->{having_args}}], $sql->{having_stmt}, $AND_OR, $unclosed, $count ];
                    $sql->{having_stmt} .= $AND_OR . "(";
                    $AND_OR = '';
                    $unclosed++;
                    next HAVING;
                }
                push @$bu, [ [@{$sql->{having_args}}], $sql->{having_stmt}, $AND_OR, $unclosed, $count ];
                my $bu_AND_OR = $AND_OR;
                my ( $quote_col, $quote_aggr);
                if ( ( any { '@' . $_ eq $aggr } @{$sql->{aggr_cols}} ) ) { #
                    ( $quote_aggr = $aggr ) =~ s/^\@//;
                    $sql->{having_stmt} .= $AND_OR . $quote_aggr;
                }
                elsif ( $aggr eq 'COUNT(*)' ) {
                    $quote_col = '*';
                    $quote_aggr = $aggr;
                    $sql->{having_stmt} .= $AND_OR . $quote_aggr;
                }
                else {
                    $aggr =~ s/\(\S\)\z//;
                    $sql->{having_stmt} .= $AND_OR . $aggr . "(";
                    $quote_aggr          =           $aggr . "(";
                    $ax->print_sql( $sql, [ $stmt_type ] );
                    # Choose
                    $quote_col = $stmt_h->choose(
                        [ undef, @{$sql->{cols}} ]
                    );
                    if ( ! defined $quote_col ) {
                        ( $sql->{having_args}, $sql->{having_stmt}, $AND_OR, $unclosed, $count ) = @{pop @$bu};
                        next HAVING;
                    }
                    $sql->{having_stmt} .= $quote_col . ")";
                    $quote_aggr         .= $quote_col . ")";
                }
                my $ok = $sf->__set_operator_sql( $sql, 'having', $quote_aggr, $stmt_type );
                if ( ! $ok ) {
                    ( $sql->{having_args}, $sql->{having_stmt}, $AND_OR, $unclosed, $count ) = @{pop @$bu};
                    next HAVING;
                }
                $count++;
            }
        }
        elsif ( $custom eq $cu{'order_by'} ) {
            my @cols;
            if ( $sql->{select_type} eq '*' || $sql->{select_type} eq 'chosen_cols' ) {
                @cols = ( @{$sql->{cols}}, @{$sql->{modified_cols}} );
            }
            else {
                @cols = ( @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}} );
                for my $stmt_type ( qw/group_by_cols aggr_cols/ ) {
                    # offer also the unmodified columns:
                    for my $i ( 0 .. $#{$sql->{$stmt_type}} ) {
                        next if ! exists $sql->{orig_cols}{$stmt_type};
                        if ( $sql->{orig_cols}{$stmt_type}[$i] ne $sql->{$stmt_type}[$i] ) {
                            push @cols, $sql->{orig_cols}{$stmt_type}[$i];
                        }
                    }
                }
            }
            my $col_sep = ' ';
            my $prev_order_by_stmt = $sql->{order_by_stmt};
            $sql->{order_by_stmt} = " ORDER BY";
            my $bu = [];

            ORDER_BY: while ( 1 ) {
                $ax->print_sql( $sql, [ $stmt_type ] );
                # Choose
                my $col = $stmt_h->choose(
                    [ @pre, @cols ]
                );
                if ( ! defined $col ) {
                    if ( @$bu ) {
                        ( $sql->{order_by_stmt}, $col_sep ) = @{pop @$bu};
                        next ORDER_BY;
                    }
                    $sql->{order_by_stmt} = $prev_order_by_stmt;
                    last ORDER_BY;
                }
                if ( $col eq $sf->{i}{ok} ) {
                    if ( $col_sep eq ' ' ) {
                        $sql->{order_by_stmt} = '';
                    }
                    last ORDER_BY;
                }
                push @$bu, [ $sql->{order_by_stmt}, $col_sep ];
                $sql->{order_by_stmt} .= $col_sep . $col;
                $ax->print_sql( $sql, [ $stmt_type ] );
                # Choose
                my $direction = $stmt_h->choose(
                    [ undef, $ASC, $DESC ]
                );
                if ( ! defined $direction ){
                    ( $sql->{order_by_stmt}, $col_sep ) = @{pop @$bu}; #
                    next ORDER_BY;
                }
                $sql->{order_by_stmt} .= ' ' . $direction;
                $col_sep = ', ';
            }
        }
        elsif ( $custom eq $cu{'limit'} ) {
            my $prev_limit_stmt  = $sql->{limit_stmt};
            my $prev_offset_stmt = $sql->{offset_stmt};
            $sql->{limit_stmt}  = '';
            $sql->{offset_stmt} = '';
            my $bu = [];

            LIMIT: while ( 1 ) {
                my ( $limit, $offset ) = ( 'LIMIT', 'OFFSET' );
                $ax->print_sql( $sql, [ $stmt_type ] );
                # Choose
                my $choice = $stmt_h->choose(
                    [ @pre, $limit, $offset ]
                );
                if ( ! defined $choice ) {
                    if ( @$bu ) {
                        ( $sql->{limit_stmt}, $sql->{offset_stmt} )  = @{pop @$bu};
                        next LIMIT;
                    }
                    $sql->{limit_stmt}  = $prev_limit_stmt;
                    $sql->{offset_stmt} = $prev_offset_stmt;
                    last LIMIT;
                }
                if ( $choice eq $sf->{i}{ok} ) {
                    last LIMIT;
                }
                push @$bu, [ $sql->{limit_stmt}, $sql->{offset_stmt} ];
                my $digits = 7;
                if ( $choice eq $limit ) {
                    $sql->{limit_stmt} = " LIMIT";
                    $ax->print_sql( $sql, [ $stmt_type ] );
                    # Choose_a_number
                    my $limit = choose_a_number( $digits,
                        { name => 'LIMIT: ', mouse => $sf->{o}{table}{mouse}, clear_screen => 0 }
                    );
                    if ( ! defined $limit ) {
                        ( $sql->{limit_stmt}, $sql->{offset_stmt} ) = @{pop @$bu};
                        next LIMIT;
                    }
                    $sql->{limit_stmt} .=  sprintf ' %d', $limit;
                }
                if ( $choice eq $offset ) {
                    if ( ! $sql->{limit_stmt} ) {
                        $sql->{limit_stmt} = " LIMIT " . ( $sf->{o}{G}{max_rows} || '9223372036854775807'  ) if $sf->{i}{driver} eq 'SQLite';   # 2 ** 63 - 1
                        # MySQL 5.7 Reference Manual - SELECT Syntax - Limit clause: SELECT * FROM tbl LIMIT 95,18446744073709551615;
                        $sql->{limit_stmt} = " LIMIT " . ( $sf->{o}{G}{max_rows} || '18446744073709551615' ) if $sf->{i}{driver} eq 'mysql';    # 2 ** 64 - 1
                    }
                    $sql->{offset_stmt} = " OFFSET";
                    $ax->print_sql( $sql, [ $stmt_type ] );
                    # Choose_a_number
                    my $offset = choose_a_number( $digits,
                        { name => 'OFFSET: ', mouse => $sf->{o}{table}{mouse}, clear_screen => 0 }
                    );
                    if ( ! defined $offset ) {
                        ( $sql->{limit_stmt}, $sql->{offset_stmt} ) = @{pop @$bu}; #
                        next LIMIT;
                    }
                    $sql->{offset_stmt} .= sprintf ' %d', $offset;
                }
            }
        }
        elsif ( $custom eq $cu{'hidden'} ) { # [insert/update/delete]
            $stmt_type = $sf->__table_write_access( $sql, $stmt_type );
            if ( $stmt_type eq 'Insert' ) {
                require App::DBBrowser::Table::Insert;
                my $tbl_in = App::DBBrowser::Table::Insert->new( $sf->{i}, $sf->{o} );
                my $ok = $tbl_in->build_insert_stmt( $sql, [ $stmt_type ], $dbh );
                if ( $ok ) {
                    $ok = $sf->commit_sql( $sql, [ $stmt_type ], $dbh );
                }
                $stmt_type = 'Select';
                #$sql = clone $backup_sql;
                $sql = $backup_sql;
                next CUSTOMIZE;
            }
            $old_idx = 1;
        }
        elsif ( $custom eq $cu{'functions'} ) {
            my $nh = App::DBBrowser::Table::Functions->new( $sf->{i}, $sf->{o} );
            $nh->col_function( $dbh, $sql, $backup_sql, $stmt_type ); #
        }
        elsif ( $custom eq $cu{'print_tbl'} ) {
            my $cols_sql = " ";
            if ( $sql->{select_type} eq '*' ) {
                if ( $sf->{i}{multi_tbl} eq 'join' ) {          # ?
                    $cols_sql .= join( ', ', @{$sql->{cols}} ); #
                }                                               #
                else {
                    $cols_sql .= "*";
                }
            }
            elsif ( $sql->{select_type} eq 'chosen_cols' ) {
                $cols_sql .= join( ', ', @{$sql->{chosen_cols}} );
            }
            elsif ( @{$sql->{aggr_cols}} || @{$sql->{group_by_cols}} ) {
                $cols_sql .= join( ', ', @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}} );
            }
            #else {
            #    $cols_sql .= "*";
            #}
            my $select .= "SELECT" . $sql->{distinct_stmt} . $cols_sql;
            $select .= " FROM " . $sql->{table};
            $select .= $sql->{where_stmt};
            $select .= $sql->{group_by_stmt};
            $select .= $sql->{having_stmt};
            $select .= $sql->{order_by_stmt};
            $select .= $sql->{limit_stmt};
            $select .= $sql->{offset_stmt};
            if ( $sf->{o}{G}{max_rows} && ! $sql->{limit_stmt} ) {
                $select .= sprintf " LIMIT %d", $sf->{o}{G}{max_rows};
                $sf->{o}{table}{max_rows} = $sf->{o}{G}{max_rows};
            }
            else {
                $sf->{o}{table}{max_rows} = 0;
            }
            my @arguments = ( @{$sql->{where_args}}, @{$sql->{having_args}} );
            local $| = 1;
            print $sf->{i}{clear_screen};
            print 'Database : ...' . "\n" if $sf->{o}{table}{progress_bar};
            my $sth = $dbh->prepare( $select );
            $sth->execute( @arguments );
            my $col_names = $sth->{NAME}; # not quoted
            my $all_arrayref = $sth->fetchall_arrayref;
            unshift @$all_arrayref, $col_names;
            print $sf->{i}{clear_screen};
            # return $sql explicitly since after a `$sql = clone( $backup )` $sql refers to a different hash.
            return $all_arrayref, $sql;
        }
        elsif ( $custom eq $cu{'commit'} ) {
            my $ok = $sf->commit_sql( $sql, [ $stmt_type ], $dbh );
            $stmt_type = 'Select';
            $old_idx = 1;
            #$sql = clone $backup_sql;
            $sql = $backup_sql;
            next CUSTOMIZE;
        }
        else {
            die "$custom: no such value in the hash \%cu";
        }
    }
    return;
}


sub commit_sql {
    my ( $sf, $sql, $stmt_typeS, $dbh ) = @_;
    my $ax  = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my $stmt_v = Term::Choose->new( $sf->{i}{lyt_stmt_v} );
    local $| = 1;
    print $sf->{i}{clear_screen};
    print 'Transaction ...' . "\n" if $sf->{o}{table}{progress_bar};
    my $transaction;
    eval { $transaction = $dbh->begin_work } or do { $dbh->{AutoCommit} = 1; $transaction = 0 };
    my $rows_to_execute = [];
    my $stmt;
    my $stmt_type = $stmt_typeS->[-1];
    if ( $stmt_type eq 'Insert' ) {
        if ( ! @{$sql->{insert_into_args}} ) {
            return 1; #
        }
        $stmt  = "INSERT INTO";
        $stmt .= ' ' . $sql->{table};
        $stmt .= " ( " . join( ', ', @{$sql->{insert_into_cols}} ) . " )";
        $stmt .= " VALUES( " . join( ', ', ( '?' ) x @{$sql->{insert_into_cols}} ) . " )";
        $rows_to_execute = $sql->{insert_into_args};
    }
    else {
        my %map_stmt_types = (
            Update => "UPDATE",
            Delete => "DELETE",
        );
        $stmt  = $map_stmt_types{$stmt_type};
        $stmt .= " FROM"               if $map_stmt_types{$stmt_type} eq "DELETE";
        $stmt .= ' ' . $sql->{table};
        $stmt .= $sql->{set_stmt}      if $sql->{set_stmt};
        $stmt .= $sql->{where_stmt}    if $sql->{where_stmt};
        $rows_to_execute->[0] = [ @{$sql->{set_args}}, @{$sql->{where_args}} ];
    }
    if ( $transaction ) {
        my $rolled_back;
        if ( ! eval {
            my $sth = $dbh->prepare( $stmt );
            for my $values ( @$rows_to_execute ) {
                $sth->execute( @$values );
            }
            my $row_count   = $stmt_type eq 'Insert' ? @$rows_to_execute : $sth->rows;
            my $commit_ok = sprintf qq(  %s %d "%s"), 'COMMIT', $row_count, $stmt_type; # show count of affected rows
            $ax->print_sql( $sql, $stmt_typeS );
            # Choose
            my $choice = $stmt_v->choose(
                [ undef,  $commit_ok ]
            );
            if ( ! defined $choice || $choice ne $commit_ok ) {
                $dbh->rollback;
                $rolled_back = 1;
            }
            else {;
                $dbh->commit;
            }
            1 }
        ) {
            $ax->print_error_message( "$@Rolling back ...\n", 'Commit' );
            $dbh->rollback;
            $rolled_back = 1;
        }
        if ( $rolled_back ) {
            return;
        }
        return 1;
    }
    else {
        my $row_count;
        if ( $stmt_type eq 'Insert' ) {
            $row_count = @$rows_to_execute;
        }
        else {
            my $count_stmt;
            $count_stmt .= "SELECT COUNT(*) FROM " . $sql->{table};
            $count_stmt .= $sql->{where_stmt};
            ( $row_count ) = $dbh->selectrow_array( $count_stmt, undef, @{$sql->{where_args}} );
        }
        my $commit_ok = sprintf qq(  %s %d "%s"), 'EXECUTE', $row_count, $stmt_type;
        $ax->print_sql( $sql, $stmt_typeS ); #
        # Choose
        my $choice = $stmt_v->choose(
            [ undef,  $commit_ok ],
            { prompt => '' }
        );
        if ( ! defined $choice || $choice ne $commit_ok ) {
            return;
        }
        if ( ! eval {
            my $sth = $dbh->prepare( $stmt );
            for my $values ( @$rows_to_execute ) {
                $sth->execute( @$values );
            }
            1 }
        ) {
            $ax->print_error_message( $@, 'Commit' );
            return;
        }
        return 1;
    }
}


sub __set_operator_sql {
    my ( $sf, $sql, $clause, $quote_col, $stmt_type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my $stmt_h = Term::Choose->new( $sf->{i}{lyt_stmt_h} );
    my $stmt = $clause . '_stmt';
    my $args = $clause . '_args';

    OPERATOR: while( 1 ) {
        $ax->print_sql( $sql, [ $stmt_type ] );
        # Choose
        my $operator = $stmt_h->choose( [ undef, @{$sf->{o}{G}{operators}} ] );
        if ( ! defined $operator ) {
            return;
        }
        $operator =~ s/^\s+|\s+\z//g;
        if ( $operator !~ /\s%?col%?\z/ ) {
            if ( $operator !~ /REGEXP(_i)?\z/ ) {
                $sql->{$stmt} .= ' ' . $operator;
            }
            my $trs = Term::Form->new();
            if ( $operator =~ /^IS\s(?:NOT\s)?NULL\z/ ) {
                # do nothing
            }
            elsif ( $operator =~ /^(?:NOT\s)?IN\z/ ) {
                my $col_sep = '';
                $sql->{$stmt} .= '(';

                IN: while ( 1 ) {
                    $ax->print_sql( $sql, [ $stmt_type ] );
                    # Readline
                    my $value = $trs->readline( 'Value: ' );
                    if ( ! defined $value ) {
                        next OPERATOR;
                    }
                    if ( $value eq '' ) {
                        if ( $col_sep eq ' ' ) {
                            next OPERATOR;
                        }
                        $sql->{$stmt} .= ')';
                        last IN;
                    }
                    $sql->{$stmt} .= $col_sep . '?';
                    push @{$sql->{$args}}, $value;
                    $col_sep = ',';
                }
            }
            elsif ( $operator =~ /^(?:NOT\s)?BETWEEN\z/ ) {
                $ax->print_sql( $sql, [ $stmt_type ] );
                # Readline
                my $value_1 = $trs->readline( 'Value: ' );
                if ( ! defined $value_1 ) {
                    next OPERATOR;
                }
                $sql->{$stmt} .= ' ' . '?' .      ' AND';
                push @{$sql->{$args}}, $value_1;
                $ax->print_sql( $sql, [ $stmt_type ] );
                # Readline
                my $value_2 = $trs->readline( 'Value: ' );
                if ( ! defined $value_2 ) {
                    next OPERATOR;
                }
                $sql->{$stmt} .= ' ' . '?';
                push @{$sql->{$args}}, $value_2;
            }
            elsif ( $operator =~ /REGEXP(_i)?\z/ ) {
                $ax->print_sql( $sql, [ $stmt_type ] );
                # Readline
                my $value = $trs->readline( 'Pattern: ' );
                if ( ! defined $value ) {
                    next OPERATOR;
                }
                $value = '^$' if ! length $value;
                $sql->{$stmt} =~ s/\s\Q$quote_col\E\z//;
                my $do_not_match_regexp = $operator =~ /^NOT/       ? 1 : 0;
                my $case_sensitive      = $operator =~ /REGEXP_i\z/ ? 0 : 1;
                if ( ! eval {
                    my $obj_db = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
                    $sql->{$stmt} .= $obj_db->regexp( $quote_col, $do_not_match_regexp, $case_sensitive );
                    push @{$sql->{$args}}, $value;
                    1 }
                ) {
                    $ax->print_error_message( $@, $operator );
                    next OPERATOR;
                }
            }
            else {
                $ax->print_sql( $sql, [ $stmt_type ] );
                my $prompt = $operator =~ /LIKE\z/ ? 'Pattern: ' : 'Value: ';
                # Readline
                my $value = $trs->readline( $prompt );
                if ( ! defined $value ) {
                    next OPERATOR;
                }
                $sql->{$stmt} .= ' ' . '?';
                push @{$sql->{$args}}, $value;
            }
        }
        elsif ( $operator =~ /\s%?col%?\z/ ) {
            my $arg;
            if ( $operator =~ /^(.+)\s(%?col%?)\z/ ) {
                $operator = $1;
                $arg = $2;
            }
            $operator =~ s/^\s+|\s+\z//g;
            $sql->{$stmt} .= ' ' . $operator;
            $ax->print_sql( $sql, [ $stmt_type ] );
            # Choose
            my $quote_col = $stmt_h->choose( $sql->{cols}, { prompt => "$operator:" } );
            if ( ! defined $quote_col ) {
                $sql->{$stmt} = '';
                next OPERATOR;
            }
            if ( $arg !~ /%/ ) {
                $sql->{$stmt} .= ' ' . $quote_col;
            }
            else {
                if ( ! eval {
                    my $obj_db = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
                    my @el = map { "'$_'" } grep { length $_ } $arg =~ /^(%?)(col)(%?)\z/g;
                    my $qt_arg = $obj_db->concatenate( \@el );
                    $qt_arg =~ s/'col'/$quote_col/;
                    $sql->{$stmt} .= ' ' . $qt_arg;
                    1 }
                ) {
                    $ax->print_error_message( $@, $operator . ' ' . $arg );
                    next OPERATOR;
                }
            }
        }
        last OPERATOR; #
    }
    return 1; #
}


sub __table_write_access {
    my ( $sf, $sql, $stmt_type ) = @_;
    my @stmt_types;
    if ( ! $sf->{i}{multi_tbl} ) {
        @stmt_types = ( 'Insert', 'Update', 'Delete' );
    }
    elsif ( $sf->{i}{multi_tbl} eq 'join' && $sf->{i}{driver} eq 'mysql' ) {
        @stmt_types = ( 'Update' );
    }
    else {
        @stmt_types = ();
    }
    if ( ! @stmt_types ) {
        return $stmt_type; #
    }
    # Choose
    my $type_choice = choose(
        [ undef, map( "- $_", @stmt_types ) ],
        { %{$sf->{i}{lyt_3}}, prompt => 'Choose SQL type:' }
    );
    if ( defined $type_choice ) {
        ( $stmt_type = $type_choice ) =~ s/^-\ //;
        my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
        $ax->reset_sql( $sql );
    }
    return $stmt_type;
}


1;


__END__
