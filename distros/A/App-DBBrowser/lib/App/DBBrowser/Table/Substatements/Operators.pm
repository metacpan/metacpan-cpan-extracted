package # hide from PAUSE
App::DBBrowser::Table::Substatements::Operators;

use warnings;
use strict;
use 5.014;

use List::MoreUtils qw( any uniq );

use Term::Choose         qw();
use Term::Form::ReadLine qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $d
    };
    bless $sf, $class;
}


sub build_having_col {
    my ( $sf, $sql, $clause, $aggr ) = @_;
    my $qt_aggr;
    if ( any { '@' . $_ eq $aggr } @{$sql->{aggr_cols}} ) {
        $qt_aggr = $aggr =~ s/^\@//r;
    }
    elsif ( $aggr eq 'COUNT(*)' ) {
        $qt_aggr = $aggr;
    }
    elsif ( any { $aggr eq $_ } @{$sf->{i}{avail_aggr}} ) {
        my $tc = Term::Choose->new( $sf->{i}{tc_default} );
        my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my @pre = ( undef );
        if ( $sf->{o}{enable}{extended_cols} ) {
            push @pre, $sf->{i}{menu_addition};
        }
        $aggr =~ s/\(\S\)\z//;
        my $bu_having_stmt = $sql->{having_stmt};
        $sql->{having_stmt} .= ' ' . $aggr . "(";
        $qt_aggr          =       $aggr . "(";
        my $info = $ax->get_sql_info( $sql );
        $sql->{having_stmt} = $bu_having_stmt;
        my $qt_col;

        COLUMN: while( 1 ) {
            # Choose
            my $qt_col = $tc->choose(
                [ @pre, @{$sql->{cols}} ],
                { %{$sf->{i}{lyt_h}}, info => $info }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $qt_col ) {
                return;
            }
            elsif ( $qt_col eq $sf->{i}{menu_addition} ) {
                my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
                my $complex_column = $ext->column( $sql, $clause );
                if ( ! defined $complex_column ) {
                    next COLUMN;
                }
                else {
                    $qt_col = $complex_column;
                }
            }
            $qt_aggr .= $qt_col . ")";
            last COLUMN;
        }
    }
    else { # SQ
        $qt_aggr = $aggr;
    }
    return $qt_aggr;
}


sub choose_and_add_operator {
    my ( $sf, $sql, $clause, $qt_col ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $stmt = $clause . '_stmt';
    my @operators = @{$sf->{o}{G}{operators}};
    if ( $sf->{i}{driver} =~ /(?:Firebird|Informix)\z/ ) {
        @operators = uniq map { s/(?<=REGEXP)_i\z//; $_ } @operators;
    }

    OPERATOR: while( 1 ) {
        my $op;
        if ( @operators == 1 ) {
            $op = $operators[0];
        }
        else {
            my @pre = ( undef );
            my $info = $ax->get_sql_info( $sql );
            # Choose
            $op = $tc->choose(
                [ @pre, @operators ],
                { %{$sf->{i}{lyt_h}}, info => $info }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $op ) {
                return;
            }
        }
        $op =~ s/^\s+|\s+\z//g;
        my $bu_stmt = $sql->{$stmt};
        $ax->print_sql_info( $ax->get_sql_info( $sql ) );
        if ( $op =~ /REGEXP(_i)?\z/ ) {
            $sql->{$stmt} =~ s/ (?: (?<=\() | \s ) \Q$qt_col\E \z //x;
            my $do_not_match_regexp = $op =~ /^NOT/ ? 1 : 0;
            my $case_sensitive      = $op =~ /REGEXP_i\z/ ? 0 : 1;
            my $regex_op;
            if ( ! eval {
                $regex_op = $sf->_regexp( $qt_col, $do_not_match_regexp, $case_sensitive );
                1 }
            ) {
                $ax->print_error_message( $@ );
                next OPERATOR;
            }
            $regex_op =~ s/^\s// if $sql->{$stmt} =~ /\(\z/;
            $sql->{$stmt} .= $regex_op;
        }
        elsif ( $op =~ /^(?:ALL|ANY)\z/) {
            my @comb_op = ( "= $op", "<> $op", "> $op", "< $op", ">= $op", "<= $op" );
            my @pre = ( undef );
            my $info = $ax->get_sql_info( $sql );
            # Choose
            $op = $tc->choose(
                [ @pre, @comb_op ],
                { %{$sf->{i}{lyt_h}}, info => $info }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $op ) {
                next OPERATOR;
            }
            $sql->{$stmt} .= ' ' . $op;
        }
        else {
            $sql->{$stmt} .= ' ' . $op;
        }
        $ax->print_sql_info( $ax->get_sql_info( $sql ) );
        return $op;
    }
}


sub read_and_add_value {
    my ( $sf, $sql, $clause, $qt_col, $op ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $stmt = $clause . '_stmt';
    if ( $op =~ /^IS\s(?:NOT\s)?NULL\z/ ) {
        return 1;
    }
    elsif ( $op =~ /^(?:NOT\s)?IN\z/ ) {
        $sql->{$stmt} .= ' (';
        my $prev_value;
        my @bu;

        IN: while ( 1 ) {
            # Readline
            my $value = $ext->value( $sql, $clause, {}, $op );
            if ( ! defined $value ) {
                if ( @bu ) {
                    $sql->{$stmt} = pop @bu;
                    next IN;
                }
                return;
            }
            if ( $value eq "''" ) {
                if ( ! @bu ) {
                    return;
                }
                if ( @bu == 1 && $prev_value =~ /^\s*\((.+)\)\s*\z/ ) {
                    # with one subquery as argument:
                    # remove parenthesis around the subquery
                    # because IN (( sq )) not alowed
                    $sql->{$stmt} = $bu[0] . $1;
                }
                $sql->{$stmt} .= ')';
                return 1;
            }
            $prev_value = $value;
            push @bu, $sql->{$stmt};
            my $col_sep = @bu == 1 ? '' : ',';
            $sql->{$stmt} .= $col_sep . $value;
        }
    }
    elsif ( $op =~ /^(?:NOT\s)?BETWEEN\z/ ) {
        # Readline
        my $value_1 = $ext->value( $sql, $clause, {}, $op );
        if ( ! defined $value_1 ) {
            return;
        }
        $sql->{$stmt} .= ' ' . $value_1 . ' AND';
        # Readline
        my $value_2 = $ext->value( $sql, $clause, {}, $op );
        if ( ! defined $value_2 ) {
            return;
        }
        $sql->{$stmt} .= ' ' . $value_2;
        return 1;
    }
    elsif ( $op =~ /REGEXP(_i)?\z/ ) {
        # Readline
        my $value = $ext->value( $sql, $clause, {}, $op );
        if ( ! defined $value ) {
            return;
        }
        $value = '^$' if ! length $value;
        if ( $sf->{i}{driver} eq 'SQLite' ) {
            $sql->{$stmt} =~ s/ (?<=\sREGEXP\() \? (?=,\Q$qt_col\E,[01]\)\z) /$value/x;
        }
        else {
            $sql->{$stmt} =~ s/\?\z/$value/;
        }
        return 1;
    }
    else {
        # Readline
        my $value = $ext->value( $sql, $clause, {}, $op );
        if ( ! defined $value ) {
            return;
        }
        $sql->{$stmt} .= ' ' . $value;
        return 1;
    }
}


sub _regexp {
    my ( $sf, $col, $do_not_match, $case_sensitive ) = @_;
    my $driver = $sf->{i}{driver};
    if ( $driver eq 'SQLite' ) {
        if ( $do_not_match ) {
            return sprintf " NOT REGEXP(?,%s,%d)", $col, $case_sensitive;
        }
        else {
            return sprintf " REGEXP(?,%s,%d)", $col, $case_sensitive;
        }
    }
    elsif ( $driver =~ /^(?:mysql|MariaDB)\z/ ) {
        if ( $do_not_match ) {
            return " $col NOT REGEXP ?"        if ! $case_sensitive;
            return " $col NOT REGEXP BINARY ?" if   $case_sensitive;
        }
        else {
            return " $col REGEXP ?"        if ! $case_sensitive;
            return " $col REGEXP BINARY ?" if   $case_sensitive;
        }
    }
    elsif ( $driver eq 'Pg' ) {
        if ( $do_not_match ) {
            return " ${col}::text !~* ?" if ! $case_sensitive;
            return " ${col}::text !~ ?"  if   $case_sensitive;
        }
        else {
            return " ${col}::text ~* ?" if ! $case_sensitive;
            return " ${col}::text ~ ?"  if   $case_sensitive;
        }
    }
    elsif ( $driver eq 'Firebird' ) {
        # SIMILAR TO
        # Unlike in some other languages, the pattern must match the entire
        # string in order to succeed — matching a substring is not enough.
        # wildcards: % and _
        if ( $do_not_match ) {
            return " $col NOT SIMILAR TO ? ESCAPE '#'";
        }
        else {
            return " $col SIMILAR TO ? ESCAPE '#'";
        }
    }
    elsif ( $driver =~ /^(?:DB2|Oracle)\z/ ) {
        if ( $do_not_match ) {
            return " NOT REGEXP_LIKE($col,?,'i')" if ! $case_sensitive;
            return " NOT REGEXP_LIKE($col,?,'c')" if   $case_sensitive;
        }
        else {
            return " REGEXP_LIKE($col,?,'i')" if ! $case_sensitive;
            return " REGEXP_LIKE($col,?,'c')" if   $case_sensitive;
        }
    }
    elsif ( $driver eq 'Informix' ) {
        if ( $do_not_match ) {
            return " $col NOT MATCHES ? ";
        }
        else {
            return " $col MATCHES ?";
        }
    }
}




1;


__END__
