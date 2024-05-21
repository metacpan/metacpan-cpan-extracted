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


sub add_operator_and_value {
    my ( $sf, $sql, $clause, $stmt, $qt_col ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @operators = @{$sf->{o}{G}{operators}};
    if ( $sf->{i}{driver} eq 'SQLite' ) {
        @operators = grep { ! /^(?:ANY|ALL)\z/ } @operators;
    }
    elsif ( $sf->{i}{driver} =~ /(?:Firebird|Informix)\z/ ) {
        @operators = uniq map { s/(?<=REGEXP)_i\z//; $_ } @operators;
    }
    elsif ( $sf->{i}{driver} eq 'ODBC' ) {
        @operators = grep { ! /REGEXP/ } @operators;
    }
    my $bu_stmt = $sql->{$stmt};

    OPERATOR: while( 1 ) {
        my $operator;
        if ( @operators == 1 ) {
            $operator = $operators[0];
        }
        else {
            my @pre = ( undef );
            my $info = $ax->get_sql_info( $sql );
            # Choose
            $operator = $tc->choose(
                [ @pre, @operators ],
                { %{$sf->{i}{lyt_h}}, info => $info }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $operator ) {
                $sql->{$stmt} = $bu_stmt;
                return;
            }
        }
        $operator =~ s/^\s+|\s+\z//g;
        $ax->print_sql_info( $ax->get_sql_info( $sql ) );
        if ( $operator =~ /REGEXP(_i)?\z/ ) {
            my $do_not_match_regexp = $operator =~ /^NOT/ ? 1 : 0;
            my $case_sensitive = $operator =~ /REGEXP_i\z/ ? 0 : 1;
            my $regex_op = $sf->_regexp( $qt_col, $do_not_match_regexp, $case_sensitive );
            if ( ! $regex_op ) {
                next OPERATOR if @operators > 1;
                return;
            }
            $sql->{$stmt} =~ s/ (?: (?<=\() | \s ) \Q$qt_col\E \z //x;
            if ( $sql->{$stmt} =~ /\(\z/ ) {
                $regex_op =~ s/^\s//;
            }
            $sql->{$stmt} .= $regex_op;
        }
        elsif ( $operator =~ /^(?:ALL|ANY)\z/) {
            my $not_equal = ( any { $_ =~ /^\s?!=\s?\z/ } @operators ) ? "!=" : "<>";
            my @comb_op = ( "= $operator", "$not_equal $operator", "> $operator", "< $operator", ">= $operator", "<= $operator" );
            my @pre = ( undef );
            my $info = $ax->get_sql_info( $sql );
            # Choose
            $operator = $tc->choose(
                [ @pre, @comb_op ],
                { %{$sf->{i}{lyt_h}}, info => $info }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $operator ) {
                next OPERATOR if @operators > 1;
                return;
            }
            $sql->{$stmt} .= ' ' . $operator;
        }
        else {
            $sql->{$stmt} .= ' ' . $operator;
        }
        $ax->print_sql_info( $ax->get_sql_info( $sql ) );
        my $ok = $sf->read_and_add_value( $sql, $clause, $stmt, $qt_col, $operator );
        if ( $ok ) {
            return 1;
        }
        else {
            $sql->{$stmt} = $bu_stmt;
            next OPERATOR if @operators > 1;
            return;
        }
    }
}


sub read_and_add_value {
    my ( $sf, $sql, $clause, $stmt, $qt_col, $operator ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $is_numeric = $ax->column_type_is_numeric( $sql, $qt_col );
    if ( $operator =~ /^IS\s(?:NOT\s)?NULL\z/ ) {
        return 1;
    }
    elsif ( $operator =~ /^(?:NOT\s)?IN\z/ ) {
        my $bu_stmt = $sql->{$stmt};
        $sql->{$stmt} .= ' (';
        my @args;

        IN: while ( 1 ) {
            # Readline
            my $value = $ext->value( $sql, $clause, {}, $operator, { is_numeric => $is_numeric } );
            if ( ! defined $value ) {
                if ( ! @args ) {
                    $sql->{$stmt} = $bu_stmt;
                    return;
                }
                pop @args;
                $sql->{$stmt} = $bu_stmt . ' ('  . join ',', @args;
                next IN;
            }
            if ( ! length $value || $value eq "''" ) {
                if ( ! @args ) {
                    $sql->{$stmt} = $bu_stmt;
                    return;
                }
                if ( @args == 1 && $args[0] =~ /^\s*\((.+)\)\s*\z/ ) {
                    # if the only argument is a subquery:
                    # remove the parenthesis around the subquery
                    # because "IN ((subquery))" is not alowed
                    $sql->{$stmt} = $bu_stmt . ' (' . $1;
                }
                $sql->{$stmt} .= ')';
                return 1;
            }
            push @args, $value;
            $sql->{$stmt} = $bu_stmt . ' ('  . join ',', @args;
        }
    }
    elsif ( $operator =~ /^(?:NOT\s)?BETWEEN\z/ ) {
        # Readline
        my $value_1 = $ext->value( $sql, $clause, {}, $operator, { is_numeric => $is_numeric } );
        if ( ! defined $value_1 ) {
            return;
        }
        my $bu_stmt = $sql->{$stmt};
        $sql->{$stmt} .= ' ' . $value_1 . ' AND';
        # Readline
        my $value_2 = $ext->value( $sql, $clause, {}, $operator, { is_numeric => $is_numeric } );
        if ( ! defined $value_2 ) {
            $sql->{$stmt} = $bu_stmt;
            return;
        }
        $sql->{$stmt} .= ' ' . $value_2;
        return 1;
    }
    elsif ( $operator =~ /REGEXP(_i)?\z/ ) {
        # Readline
        my $value = $ext->value( $sql, $clause, {}, $operator, { is_numeric => 0 } );
        if ( ! defined $value ) {
            return;
        }
        $value = '^$' if ! length $value;
        if ( $sf->{i}{driver} eq 'SQLite' ) {
            $sql->{$stmt} =~ s/ (?<=\sREGEXP\() \? (?=,\Q$qt_col\E,[01]\)\z) /$value/x;
        }
        elsif ( $sf->{i}{driver} eq 'Firebird' ) {
            $sql->{$stmt} =~ s/ \? (?=\sESCAPE\s'\#'\z) /$value/x;
        }
        elsif ( $sf->{i}{driver} =~ /^(?:DB2|Oracle)\z/ ) {
            $sql->{$stmt} =~ s/ \?  (?=,'[ci]'\)\z) /$value/x;
        }
        else {
            $sql->{$stmt} =~ s/\?\z/$value/;
        }
        return 1;
    }
    else {
        # Readline
        my $value = $ext->value( $sql, $clause, {}, $operator, { is_numeric => $is_numeric } );
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
        # Wildcard characters: *, ?, [...], [^...]
        # \ removes the special significance of the next character
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
