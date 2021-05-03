package # hide from PAUSE
App::DBBrowser::Table::Substatements::Operators;

use warnings;
use strict;
use 5.010001;

use List::MoreUtils qw( any );

use Term::Choose qw();
use Term::Form   qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
    };
    bless $sf, $class;
}


sub build_having_col {
    my ( $sf, $sql, $aggr ) = @_;
    my $quote_aggr;
    if ( any { '@' . $_ eq $aggr } @{$sql->{aggr_cols}} ) {
        ( $quote_aggr = $aggr ) =~ s/^\@//;
        $sql->{having_stmt} .= ' ' . $quote_aggr;
    }
    elsif ( $aggr eq 'COUNT(*)' ) {
        $quote_aggr = $aggr;
        $sql->{having_stmt} .= ' ' . $quote_aggr;
    }
    else {
        $aggr =~ s/\(\S\)\z//;
        $sql->{having_stmt} .= ' ' . $aggr . "(";
        $quote_aggr          =       $aggr . "(";
        my $tc = Term::Choose->new( $sf->{i}{tc_default} );
        my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my @pre = ( undef );
        $ax->print_sql( $sql );
        # Choose
        my $quote_col = $tc->choose(
            [ @pre, @{$sql->{cols}} ],
            { %{$sf->{i}{lyt_h}} }
        );
        if ( ! defined $quote_col ) {
            return;
        }
        $sql->{having_stmt} .= $quote_col . ")";
        $quote_aggr         .= $quote_col . ")";
    }
    return $quote_aggr;
}


sub choose_and_add_operator {
    my ( $sf, $sql, $clause, $quote_col ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $stmt = $clause . '_stmt';
    my $args = $clause . '_args';
    my $menu_addition;
    my @operators_default;
    my @operators_limited;
    my $i = $sf->{o}{enable}{'expand_' . $clause};
    if ( $clause eq 'set' ) {
        $menu_addition = $sf->{i}{menu_additions_set}[$i];
        @operators_default = ( " = " );
        @operators_limited = ( " = " );
    }
    else {
        $menu_addition = '=' . $sf->{i}{menu_additions}[$i];
        @operators_default = @{$sf->{o}{G}{operators}};
        @operators_limited = ( " = ", " != ", " < ", " > ", " >= ", " <= ", "IN", "NOT IN" );
    }
    if ( $i ) {
        unshift @operators_default, $menu_addition;
    }

    OPERATOR: while( 1 ) {
        my $is_complex_value;
        my $op;
        if ( @operators_default == 1 ) {
            $op = $operators_default[0];
        }
        else {
            my @pre = ( undef );
            $ax->print_sql( $sql );
            # Choose
            $op = $tc->choose(
                [ @pre, @operators_default ],
                { %{$sf->{i}{lyt_h}} }
            );
            if ( ! defined $op ) {
                return;
            }
        }
        if ( $op eq $menu_addition ) {
            if ( @operators_limited == 1 ) {
                $op = $operators_limited[0];
            }
            else {
                my @pre = ( undef );
                $ax->print_sql( $sql );
                # Choose
                $op = $tc->choose(
                    [ @pre, @operators_limited ],
                    { %{$sf->{i}{lyt_h}}, prompt => 'First select the operator:' }
                );
                if ( ! defined $op ) {
                    next OPERATOR;
                }
            }
            $is_complex_value = 1;
        }
        else {
            $is_complex_value = 0;
        }
        $op =~ s/^\s+|\s+\z//g;
        my $bu_stmt = $sql->{$stmt};
        my $ok = $sf->__add_operator( $sql, $clause, $quote_col, $op );
        if ( ! $ok ) {
            $sql->{$stmt} = $bu_stmt;
            next OPERATOR;
        }
        return $op, $is_complex_value;
    }
}


sub __add_operator {
    my ( $sf, $sql, $clause, $quote_col, $op ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $stmt = $clause . '_stmt';
    my $args = $clause . '_args';
    my $ok;
    if ( $op =~ /^(.+)\s(%?col%?)\z/ ) {
        $op = $1;
        my $arg = $2;
        $sql->{$stmt} .= ' ' . $op;
        $ax->print_sql( $sql );
        my $quote_col;
        if ( $stmt eq 'having_stmt' ) {
            my @pre = ( undef, $sf->{i}{ok} );
            my @choices = ( @{$sf->{aggregate}}, map( '@' . $_,  @{$sql->{aggr_cols}} ) );
            # Choose
            my $aggr = $tc->choose(
                [ @pre, @choices ],
                { %{$sf->{i}{lyt_h}} }
            );
            if ( ! defined $aggr ) {
                return;
            }
            if ( $aggr eq $sf->{i}{ok} ) {
            }
            my $backup_tmp = $sql->{$stmt};
            $quote_col =  $sf->build_having_col( $sql, $aggr );
            $sql->{$stmt} = $backup_tmp;
        }
        else {
            # Choose
            $quote_col = $tc->choose(
                $sql->{cols},
                { %{$sf->{i}{lyt_h}}, prompt => 'Col:' }
            );
        }
        if ( ! defined $quote_col ) {
            return;
        }
        if ( $arg !~ /%/ ) {
            $sql->{$stmt} .= ' ' . $quote_col;
        }
        else {
            if ( ! eval {
                my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
                my @el = map { "'$_'" } grep { length $_ } $arg =~ /^(%?)(col)(%?)\z/g;
                my $qt_arg = $plui->concatenate( \@el );
                $qt_arg =~ s/'col'/$quote_col/;
                $sql->{$stmt} .= ' ' . $qt_arg;
                1 }
            ) {
                $ax->print_error_message( $@ );
                return;
            }
        }
    }
    elsif ( $op =~ /REGEXP(_i)?\z/ ) {
        $ax->print_sql( $sql );
        $sql->{$stmt} =~ s/ (?: (?<=\() | \s ) \Q$quote_col\E \z //x;
        my $do_not_match_regexp = $op =~ /^NOT/       ? 1 : 0;
        my $case_sensitive      = $op =~ /REGEXP_i\z/ ? 0 : 1;
        my $regex_op;
        if ( ! eval {
            my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
            $regex_op = $plui->regexp( $quote_col, $do_not_match_regexp, $case_sensitive );
            1 }
        ) {
            $ax->print_error_message( $@ );
            return;
        }
        $regex_op =~ s/^\s// if $sql->{$stmt} =~ /\(\z/;
        $sql->{$stmt} .= $regex_op;
    }
    else {
        $sql->{$stmt} .= ' ' . $op;
    }
    $ax->print_sql( $sql );
    return 1;
}


sub read_and_add_value {
    my ( $sf, $sql, $clause, $op, $is_complex_value ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $stmt = $clause . '_stmt';
    my $args = $clause . '_args';
    if ( $is_complex_value ) {
        my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $complex_value = $ext->complex_unit( $sql, $clause );
        if ( ! defined $complex_value ) {
            return;
        }
        if ( $op =~ /^(?:NOT\s)?IN\z/ ) {
            while ( $complex_value =~ /^\s*\((.+)\)\s*\z/ ) {
                $complex_value = $1;
            }
            $sql->{$stmt} .= '(' . $complex_value . ')';
        }
        #elsif ( $op =~ /REGEXP(_i)?\z/ ) {
        #    $sql->{$stmt} =~ s/\?[^\?]*\z/$complex_value/;
        #}
        else {
            $sql->{$stmt} .= ' ' . $complex_value;
        }
        return 1;
    }
    else {
        if ( $op =~ /^IS\s(?:NOT\s)?NULL\z/ ) {
            return 1;
        }
        elsif ( $op =~ /\s%?col%?\z/ ) {
            return 1;
        }
        elsif ( $op =~ /^(?:NOT\s)?IN\z/ ) {
            my $col_sep = '';
            $sql->{$stmt} .= '(';

            IN: while ( 1 ) {
                $ax->print_sql( $sql );
                # Readline
                my $value = $tf->readline( 'Value: ' );
                if ( ! defined $value ) {
                    return;
                }
                if ( $value eq '' ) {
                    if ( $col_sep eq '' ) {
                        return;
                    }
                    $sql->{$stmt} .= ')';
                    return 1;
                }
                $sql->{$stmt} .= $col_sep . '?';
                push @{$sql->{$args}}, $value;
                $col_sep = ',';
            }
        }
        elsif ( $op =~ /^(?:NOT\s)?BETWEEN\z/ ) {
            $ax->print_sql( $sql );
            # Readline
            my $value_1 = $tf->readline( 'Value 1: ' );
            if ( ! defined $value_1 ) {
                return;
            }
            $sql->{$stmt} .= ' ' . '?' . ' AND';
            push @{$sql->{$args}}, $value_1;
            $ax->print_sql( $sql );
            # Readline
            my $value_2 = $tf->readline( 'Value 2: ' );
            if ( ! defined $value_2 ) {
                return;
            }
            $sql->{$stmt} .= ' ' . '?';
            push @{$sql->{$args}}, $value_2;
            return 1;
        }
        elsif ( $op =~ /REGEXP(_i)?\z/ ) {
            push @{$sql->{$args}}, '...';
            $ax->print_sql( $sql );
            # Readline
            my $value = $tf->readline( 'Pattern: ' );
            if ( ! defined $value ) {
                return;
            }
            $value = '^$' if ! length $value;
            pop @{$sql->{$args}};
            push @{$sql->{$args}}, $value;
            return 1;
        }
        else {
            $ax->print_sql( $sql );
            my $prompt = $op =~ /^(?:NOT\s)?LIKE\z/ ? 'Pattern: ' : 'Value: '; #
            # Readline
            my $value = $tf->readline( $prompt );
            if ( ! defined $value ) {
                return;
            }
            $sql->{$stmt} .= ' ' . '?';
            push @{$sql->{$args}}, $value;
            return 1;
        }
    }
}





1;


__END__
