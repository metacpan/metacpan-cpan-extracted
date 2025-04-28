package # hide from PAUSE
App::DBBrowser::Table::Extensions::ScalarFunctions::Date;

use warnings;
use strict;
use 5.016;

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub function_current_timestamp {
    my ( $sf ) = @_;
    return "CURRENT_TIMESTAMP";
}


sub function_current_date {
    my ( $sf ) = @_;
    return "CURRENT_DATE";
}


sub function_current_time {
    my ( $sf ) = @_;
    return "CURRENT_TIME";
}


sub function_current {
    my ( $sf ) = @_;
    return "CURRENT";
}


sub function_date_add {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__add_date_subtract_date( $sql, $clause, $func, $cols, $r_data );
}


sub function_date_subtract {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__add_date_subtract_date( $sql, $clause, $func, $cols, $r_data );
}


sub __add_date_subtract_date {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $args_data = [
        { prompt => 'Unit: ', history => [ qw(YEAR MONTH DAY HOUR MINUTE SECOND) ], unquote => 1 },
        { prompt => 'Amount: ', is_numeric => 1 },
    ];
    my ( $unit, $amount ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    return if ! defined $amount || ! defined $unit;
    $unit = uc $unit;
    if ( $driver eq 'SQLite' ) {
        return "DATETIME($col,'-' || $amount || ' $unit')" if $func eq 'DATE_SUBTRACT';
        return "DATETIME($col,$amount || ' $unit')";
    }
    if ( $driver =~ /^(?:mysql|MariaDB)\z/ ) {
        return "DATE_SUB($col,INTERVAL $amount $unit)" if $func eq 'DATE_SUBTRACT';
        return "DATE_ADD($col,INTERVAL $amount $unit)";
    }
    if ( $driver eq 'Pg' ) {
        return "$col - $amount * INTERVAL '1 $unit'" if $func eq 'DATE_SUBTRACT';
        return "$col + $amount * INTERVAL '1 $unit'";
    }
    if ( $driver eq 'DB2' ) {
        return "ADD_${unit}S($col,-$amount)" if $func eq 'DATE_SUBTRACT';
        return "ADD_${unit}S($col,$amount)";
    }
    if ( $driver eq 'Informix' ) {
        return "$col - $amount UNITS $unit" if $func eq 'DATE_SUBTRACT';
        return "$col + $amount UNITS $unit";
    }
    if ( $driver eq 'Oracle' ) {
        if ( $unit eq 'MONTH' ) {
            return "ADD_MONTHS($col,-$amount)" if $func eq 'DATE_SUBTRACT';
            return "ADD_MONTHS($col,$amount)";
        }
        else {
            return "$col - $amount * INTERVAL '1' $unit" if $func eq 'DATE_SUBTRACT';
            return "$col + $amount * INTERVAL '1' $unit";
        }
    }
    else {
        return "DATEADD($unit,-$amount,$col)" if $func eq 'DATE_SUBTRACT';
        return "DATEADD($unit,$amount,$col)";
    }
}


sub function_date_trunc {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $history = [ qw(YEAR QUARTER MONTH WEEK DAY HOUR MINUTE SECOND MILLISECONDS MICROSECONDS DECADE CENTURY MILLENNIUM) ];
    my $args_data = [
        { prompt => 'Field: ', history => $history, unquote => 0 },
    ];
    if ( $driver eq 'Pg' ) {
        push @$args_data, { prompt => 'Time_zone:' };
    }
    my ( $field, $timezone ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( ! defined $field ) {
        return;
    }
    return "DATE_TRUNC($field,$col)"            if ! defined $timezone;
    return "DATE_TRUNC($field,$col,$timezone)";
}


sub function_date_part {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $history;
    if ( $driver eq 'Pg' ) {
        $history = [ qw(YEAR QUARTER MONTH WEEK DAY HOUR MINUTE SECOND MILLISECONDS MICROSECONDS EPOCH JULIAN
                        DOW DOY TIMEZONE TIMEZONE_HOUR TIMEZONE_MINUTE ISODOW ISOYEAR DECADE CENTURY MILLENNIUM) ];
    }
    my $args_data = [
        { prompt => 'Field: ', history => $history, unquote => 0 },
    ];
    my ( $field ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( ! defined $field ) {
        return;
    }
    $field = uc $field;
    return "DATE_PART($field,$col)";
}


sub function_extract {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $history;
    if ( $driver eq 'SQLite' ) {
        $history = [ qw(YEAR QUARTER MONTH WEEK DAY HOUR MINUTE SECOND DAYOFYEAR DAYOFWEEK WEEK_ISO DAYOFWEEK_ISO) ];
    }
    elsif ( $driver =~ /^(?:mysql|MariaDB)\z/ ) {
        $history = [ qw(YEAR QUARTER MONTH WEEK DAY HOUR MINUTE SECOND MICROSECOND YEAR_MONTH DAY_HOUR DAY_MINUTE
                        DAY_SECOND DAY_MICROSECOND HOUR_MINUTE HOUR_SECOND HOUR_MICROSECOND MINUTE_SECOND
                        MINUTE_MICROSECOND SECOND_MICROSECOND) ];
    }
    elsif ( $driver eq 'Pg' ) {
        $history = [ qw(YEAR QUARTER MONTH WEEK DAY HOUR MINUTE SECOND MILLISECONDS MICROSECONDS EPOCH JULIAN
                        DOW DOY TIMEZONE TIMEZONE_HOUR TIMEZONE_MINUTE ISODOW ISOYEAR DECADE CENTURY MILLENNIUM) ];
    }
    elsif ( $driver eq 'Firebird' ) {
        $history = [ qw(YEAR QUARTER MONTH WEEK DAY WEEKDAY YEARDAY HOUR MINUTE SECOND MILLISECOND) ]; # 4.0: TIMEZONE_HOUR TIMEZONE_MINUTE
    }
    elsif ( $driver eq 'Informix' ) {
        $history = [ qw(YEAR QUARTER MONTH DAY HOUR MINUTE SECOND DAYOFWEEK) ];
    }
    elsif ( $driver eq 'DB2' ) {
        $history = [ qw(EPOCH MILLENNIUM CENTURY DECADE YEAR QUARTER MONTH WEEK DAY DOW DOY HOUR MINUTE SECOND
                        MILLISECOND MICROSECOND) ];
    }
    elsif ( $driver eq 'Oracle' ) {
        $history = [ qw(YEAR QUARTER MONTH WEEK DAY HOUR MINUTE SECOND DAYOFWEEK DAYOFYEAR WEEK_ISO YEAR_ISO
                        TIMEZONE_HOUR TIMEZONE_MINUTE TIMEZONE_REGION TIMEZONE_ABBR) ];
    }
    my $args_data = [
        { prompt => 'Field: ', history => $history, unquote => 1 },
    ];
    my ( $field ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( ! defined $field ) {
        return;
    }
    $field = uc $field;
    if ( $driver eq 'SQLite' ) {
        return "CEILING(strftime('%m',$col)/3.00)" if $field eq 'QUARTER';
        my %map = ( YEAR => '%Y', MONTH => '%m', WEEK => '%W', DAY => '%d', HOUR => '%H', MINUTE => '%M', SECOND => '%S',
                    DAYOFYEAR => '%j', DAYOFWEEK => '%w', WEEK_ISO => '%V', DAYOFWEEK_ISO => '%u',
        );
        if ( $map{ $field } ) {
            $field = "'" . $map{ $field } . "'";
        }
        return "strftime($field,$col)";
    }
    elsif ( $driver eq 'Firebird' && $field eq 'QUARTER' ) {
        return "CEILING(EXTRACT(MONTH FROM $col)/3.00)";
    }
    elsif ( $driver eq 'Informix' ) {
        return "EXTEND($col,$field to $field)" if $field =~ /^(?:HOUR|MINUTE|SECOND)\z/;
        return "WEEKDAY($col)"                 if $field eq 'DAYOFWEEK';
        return "$field($col)";
    }
    elsif ( $driver eq 'Oracle' ) {
        return "to_char($col,'Q')"    if $field eq 'QUARTER';
        return "to_char($col,'WW')"   if $field eq 'WEEK';
        return "to_char($col,'IW')"   if $field eq 'WEEK_ISO';
        return "to_char($col,'D')"    if $field eq 'DAYOFWEEK';
        return "to_char($col,'DDD')"  if $field eq 'DAYOFYEAR';
        return "to_char($col,'IYYY')" if $field eq 'YEAR_ISO';
        return "EXTRACT($field FROM $col)";
    }
    else {
        return "EXTRACT($field FROM $col)";
    }
}


sub function_date {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__sqlite_date_functions( $sql, $clause, $func, $cols, $r_data );
}


sub function_time {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__sqlite_date_functions( $sql, $clause, $func, $cols, $r_data );
}

sub function_datetime {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__sqlite_date_functions( $sql, $clause, $func, $cols, $r_data );
}

sub function_julianday {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__sqlite_date_functions( $sql, $clause, $func, $cols, $r_data );
}

sub function_unixepoch {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__sqlite_date_functions( $sql, $clause, $func, $cols, $r_data );
}


sub __sqlite_date_functions {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $modifiers;
    if ( $driver eq 'SQLite' ) {
        $modifiers = $ga->sqlite_modifiers( $sql, $r_data );
    }
    return "$func($col)" if ! length $modifiers;
    return "$func($col,$modifiers)";
}


sub function_week {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $mode;
    if ( $driver =~ /^(?:mysql|MariaDB)\z/ ) {
        my $history = [ 0 .. 7 ];
        my $args_data = [
            { prompt => 'Mode: ', history => $history, is_numeric => 1 },
        ];
        ( $mode ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    }
    return "WEEK($col)"            if ! defined $mode;
    return "WEEK($col,$mode)";
}


sub function_datediff {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my ( $start_date, $end_date ) = $sf->__start_date_end_date( $sql, $clause, $func, $cols, $r_data );
    if ( ! defined $start_date || ! defined $end_date ) {
        return;
    }
    my $args_data = [];
    if ( $driver eq 'Firebird' ) {
        $args_data = [
            { prompt => 'Unit: ', history => [ qw(YEAR MONTH WEEK DAY HOUR MINUTE SECOND MILLISECOND) ], unquote => 1 }
        ];
    }
    else {
        $args_data = [
            { prompt => 'Unit: ', history => [ qw(YEAR MONTH DAY HOUR MINUTE SECOND) ], history_only => 1, unquote => 1 }
        ];
    }
    my ( $unit ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( ! defined $unit ) {
        return;
    }
    $unit = uc $unit;
    if ( $driver eq 'SQLite' ) {
        my $year_diff = "strftime('%Y',$end_date) - strftime('%Y',$start_date)";
        my $day_diff = "JulianDay(DATE($end_date)) - JulianDay(DATE($start_date))";
        my $hour_diff = "($day_diff) * 24 + (strftime('%H',$end_date) - strftime('%H',$start_date))";
        my $minute_diff = "($hour_diff) * 60 + (strftime('%M',$end_date) - strftime('%M',$start_date))";
        return $year_diff                                                                      if $unit eq 'YEAR';
        return "($year_diff) * 12 + (strftime('%m',$end_date) - strftime('%m',$start_date))"   if $unit eq 'MONTH';
        return $day_diff                                                                       if $unit eq 'DAY';
        return $hour_diff                                                                      if $unit eq 'HOUR';
        return $minute_diff                                                                    if $unit eq 'MINUTE';
        return "($minute_diff) * 60 + (strftime('%S',$end_date) - strftime('%S',$start_date))" if $unit eq 'SECOND';
    }
    elsif ( $driver =~ /^(?:mysql|MariaDB|DB2)\z/ ) {
        my $year_diff = "YEAR($end_date) - YEAR($start_date)";
        my $day_diff;
        if ( $driver eq 'DB2' ) {
            $day_diff = "DAYS($end_date) - DAYS($start_date)"
        }
        else {
            $day_diff = "DATEDIFF($end_date,$start_date)";
        }
        my $hour_diff = "($day_diff) * 24 + (HOUR($end_date) - HOUR($start_date))";
        my $minute_diff = "($hour_diff) * 60 + (MINUTE($end_date) - MINUTE($start_date))";
        return $year_diff                                                        if $unit eq 'YEAR';
        return "($year_diff) * 12 + (MONTH($end_date) - MONTH($start_date))"     if $unit eq 'MONTH';
        return $day_diff                                                         if $unit eq 'DAY';
        return $hour_diff                                                        if $unit eq 'HOUR';
        return $minute_diff                                                      if $unit eq 'MINUTE';
        return "($minute_diff) * 60 + (SECOND($end_date) - SECOND($start_date))" if $unit eq 'SECOND';
    }
    elsif ( $driver eq 'Pg' ) {
        my $year_diff = "DATE_PART('YEAR',${end_date}::DATE) - DATE_PART('YEAR',${start_date}::DATE)";
        my $day_diff = "${end_date}::DATE - ${start_date}::DATE";
        my $hour_diff = "($day_diff) * 24 + (DATE_PART('HOUR',$end_date) - DATE_PART('HOUR',$start_date))";
        my $minute_diff = "($hour_diff) * 60 + (DATE_PART('MINUTE',$end_date) - DATE_PART('MINUTE',$start_date))";
        return $year_diff                                                                                                                           if $unit eq 'YEAR';
        return "($year_diff) * 12 + (DATE_PART('MONTH',${end_date}::DATE) - DATE_PART('MONTH',${start_date}::DATE))"                                if $unit eq 'MONTH';
        #return "(DATE_PART('YEAR',$end_date) - DATE_PART('YEAR',$start_date)) * 52 + (DATE_PART('WEEK',$end_date) - DATE_PART('WEEK',$start_date))" if $unit eq 'WEEK';
        return $day_diff                                                                                                                            if $unit eq 'DAY';
        return $hour_diff                                                                                                                           if $unit eq 'HOUR';
        return $minute_diff                                                                                                                         if $unit eq 'MINUTE';
        return "TRUNC(($minute_diff) * 60 + (DATE_PART('SECOND',$end_date) - DATE_PART('SECOND',$start_date)))"                                     if $unit eq 'SECOND';
    }
    elsif ( $driver eq 'Firebird' ) {
        return "DATEDIFF($unit,$start_date,$end_date)";
    }
    #elsif ( $driver eq 'Oracle' ) {
    #    return "TO_DATE($end_date) - TO_DATE($start_date)";
    #    return "TO_TIMESTAMP($end_date) - TO_TIMESTAMP($start_date)";
    #    return "TO_TIMESTAMP_TZ($end_date) - TO_TIMESTAMP_TZ($start_date)";
    #}
}


sub function_timediff {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my ( $start_date, $end_date ) = $sf->__start_date_end_date( $sql, $clause, $func, $cols, $r_data );
    if ( ! defined $start_date || ! defined $end_date ) {
        return;
    }
    return "TIMEDIFF($end_date,$start_date)"
}


sub function_timestampdiff {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my ( $start_date, $end_date ) = $sf->__start_date_end_date( $sql, $clause, $func, $cols, $r_data );
    if ( ! defined $start_date || ! defined $end_date ) {
        return;
    }
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $args_data = [
        { prompt => 'Unit: ', history => [ qw(YEAR MONTH WEEK DAY HOUR MINUTE SECOND MILLISECOND) ], unquote => 1 }
    ];
    my ( $unit ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    return if ! defined $unit;
    return "TIMESTAMPDIFF($unit,$start_date,$end_date)"
}


sub function_months_between {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my ( $start_date, $end_date ) = $sf->__start_date_end_date( $sql, $clause, $func, $cols, $r_data );
    if ( ! defined $start_date || ! defined $end_date ) {
        return;
    }
    return "MONTHS_BETWEEN($end_date,$start_date)";
}


sub function_age {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my ( $start_date, $end_date ) = $sf->__start_date_end_date( $sql, $clause, $func, $cols, $r_data );
    return                               if ! defined $start_date;
    return "AGE($start_date)"            if ! defined $end_date;
    return "AGE($end_date,$start_date)";
}


sub __start_date_end_date {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );

    while ( 1 ) {
        my $prompt = 'Start date:';
        my $start_date = $ga->choose_a_column( $sql, $clause, $cols, $r_data, $prompt );
        if ( ! defined $start_date ) {
            return;
        }
        $prompt = 'End date:';
        my $end_date = $ga->choose_a_column( $sql, $clause, $cols, $r_data, $prompt );
        if ( ! defined $end_date ) {
            return $start_date if $func eq 'AGE'; ##
            if ( $driver eq 'Informix' ) {
                return $start_date, "CURRENT";
            }
            else {
                return $start_date, "CURRENT_TIMESTAMP";
            }
        }
        return $start_date, $end_date;
    }
}


1;
