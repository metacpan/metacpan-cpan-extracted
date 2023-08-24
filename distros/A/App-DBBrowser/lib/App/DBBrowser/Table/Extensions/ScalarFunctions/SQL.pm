package # hide from PAUSE
App::DBBrowser::Table::Extensions::ScalarFunctions::SQL;

use warnings;
use strict;
use 5.014;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub function_with_no_col {
    my ( $sf, $func ) = @_;
    my $driver = $sf->{i}{driver};
    $func = uc( $func );
    if ( $func =~ /^NOW\z/i ) {
        return "strftime('%Y-%m-%d %H-%M-%S','now')" if $driver eq 'SQLite';
        return "timestamp 'NOW'"                     if $driver eq 'Firebird';
        return "CURRENT"                             if $driver eq 'Informix'; # "CURRENT YEAR TO SECOND"
        return "NOW()"                               if $driver =~ /^(?:mysql|MariaDB|Pg)\z/;
        return "CURRENT_TIMESTAMP"; # ansi 2003
        # "CURRENT_TIMESTAMP(9)"
    }
    else {
        return "$func()"; # none
    }
}


sub function_with_col {
    my ( $sf, $func, $col ) = @_;
    my $driver = $sf->{i}{driver};
    $func = uc( $func );
    if ( $func =~ /^LTRIM\z/i ) {
        return "LTRIM($col)"              if $driver =~ /^(?:SQLite|mysql|MariaDB|Pg|DB2|Informix|Oracle)\z/;
        return "TRIM(LEADING FROM $col)"; # ansi 2003
    }
    elsif ( $func =~ /^RTRIM\z/i ) {
        return "RTRIM($col)"              if $driver =~ /^(?:SQLite|mysql|MariaDB|Pg|DB2|Informix|Oracle)\z/;
        return "TRIM(TRAILING FROM $col)"; # ansi 2003
    }
    elsif ( $func =~ /^OCTET_LENGTH\z/i ) {
        return "LENGTHB($col)"            if $driver eq 'Oracle';
        return "OCTET_LENGTH($col)"; # ansi 2003
    }
    elsif ( $func =~ /^CHAR_LENGTH\z/i ) {
        return "LENGTH($col)"             if $driver =~ /^(?:SQLite|Oracle)\z/;
        return "CHAR_LENGTH($col)"; # ansi 2003
    }
    else {
        return "$func($col)";
    }
}


sub function_with_col_and_arg {
    my ( $sf, $func, $col, $arg ) = @_;
    my $driver = $sf->{i}{driver};
    $func = uc( $func );
    if ( $func =~ /^CAST\z/i ) {
        return "CAST($col AS $arg)"; # ansi 2003
    }
    elsif ( $func =~ /^EXTRACT\z/i ) {
        if ( $driver eq 'SQLite' ) {
            my %map = ( YEAR => '%Y', MONTH => '%m', WEEK => '%W', DAY => '%d', HOUR => '%H', MINUTE => '%M', SECOND => '%S',
                        DAY_OF_YEAR => '%j', DAY_OF_WEEK => '%w',
            );
            if ( $map{ uc( $arg ) } ) {
                $arg = "'" . $map{ uc( $arg ) } . "'";
            }
            return "strftime($arg,$col)";
        }
        elsif ( $arg eq 'WEEK' ) {
            return "to_char($col,'WI')" if $driver eq 'Oracle'; # WW
            return "EXTRACT($arg FROM $col)";
        }
        elsif ( $arg eq 'day_of_week' ) {
            # SQLite: '%w': 0 = Sunday

            # mysql: WEEKDAY:   0 = Monday
            # mysql: DAYOFWEEK: 1 = Sunday

            # Firebird: EXTRACT(WEEKDAY ...): 0 = Sunday

            # Pg: ISODOW: 1 = Monday
            # Pg: DOW:    0 = Sunday

            # DB2: DAYOFWEEK_ISO: 1 = Monday
            # DB2: DAYOFWEEK:     1 = Sunday

            # Informix: WEEKDAY:  0 = Sunday

            # Oracle: to_char($col,'D'): 1 = Sunday

            return "DAYOFWEEK($col)"            if $driver =~ /^(?:mysql|MariaDB)\z/;
            return "EXTRACT(DOW FROM $col)"     if $driver eq 'Pg';
            return "EXTRACT(WEEKDAY FROM $col)" if $driver eq 'Firebird';
            return "DAYOFWEEK($col)"            if $driver eq 'DB2';
            return "WEEKDAY($col)"              if $driver eq 'Informix';
            return "to_char($col,'D')"          if $driver eq 'Oracle';
        }
        elsif ( $arg eq 'day_of_year' ) {
            return "DAYOFYEAR($col)"            if $driver =~ /^(?:mysql|MariaDB)\z/;
            return "EXTRACT(DOY FROM $col)"     if $driver eq 'Pg';
            return "EXTRACT(YEARDAY FROM $col)" if $driver eq 'Firebird';
            return "DAYOFYEAR($col)"            if $driver eq 'DB2';
            return "to_char($col,'DDD')"        if $driver eq 'Oracle';
        }
        else {
            return "EXTRACT($arg FROM $col)"; # ansi 2003
        }
    }
    elsif ( $func =~ /^ROUND\z/i ) {
        if ( length $arg ) {
            return "ROUND($col,$arg)";
        }
        else {
            return "ROUND($col)";
        }
    }
    elsif ( $func =~ /^TRUNCATE\z/i ) {
        if ( $driver =~ /^(?:Pg|Firebird|Informix|Oracle)\z/ ) {
            return "TRUNC($col,$arg)" if length $arg;
            return "TRUNC($col)";
        }
        else {
            return "TRUNCATE($col,$arg)" if length $arg;
            return "TRUNCATE($col)";
        }
    }
    elsif ( $func =~ /^POSITION\z/i ) {
        my $substring = $sf->{d}{dbh}->quote( $arg );
        return "INSTR($col,$substring)" if $driver =~ /^(?:SQLite|Informix|Oracle)\z/;
        return "POSITION($substring IN $col)"; # ansi 2003
        # DB2, Informix, Oracle: INSTR(string, substring, start, count)
        # Firebird: position(substring, string, start)
    }
    #elsif ( $func =~ /^LEFT\z/i ) {
    #    return "SUBSTR($col,1,$arg)" if $driver eq 'SQLite';
    #    return "LEFT($col,$arg)";
    #}
    #elsif ( $func =~ /^RIGHT\z/i ) {
    #    return "SUBSTR($col,-$arg)" if $driver eq 'SQLite';
    #    return "RIGHT($col,$arg)";
    #}
    else {
        return "$func($col,$arg)";
    }
}


sub function_with_col_and_2args {
    my ( $sf, $func, $col, $arg1, $arg2 ) = @_;
    my $driver = $sf->{i}{driver};
    if ( $func =~ /^REPLACE\z/i ) {
        my $string_to_replace =  $sf->{d}{dbh}->quote( $arg1 );
        my $replacement_string = $sf->{d}{dbh}->quote( $arg2 );
        return "REPLACE($col,$string_to_replace,$replacement_string)";
    }
    elsif ( $func =~ /^SUBSTR\z/i ) {
        my $startpos = $arg1;
        my $length = $arg2;
        if ( $driver =~ /^(?:SQLite|mysql|MariaDB|Oracle)\z/ ) {
            return "SUBSTR($col,$startpos,$length)" if length $length;
            return "SUBSTR($col,$startpos)";
        }
        else {
            return "SUBSTRING($col FROM $startpos FOR $length)" if length $length; # ansi 2003
            return "SUBSTRING($col FROM $startpos)";
        }
    }
    elsif ( $func =~ /^LPAD\z/i ) {
        my $length = $arg1;
        my $fill = $arg2;
        if ( $sf->{i}{driver} eq 'SQLite' ) {
            $fill = ' ' if ! length $fill;
            $fill = $sf->{d}{dbh}->quote( $fill x $length );
            return "SUBSTR($fill||$col,-$length,$length)";
        }
        else {
            return "LPAD($col,$length)" if ! length $fill;
            $fill = $sf->{d}{dbh}->quote( $fill );
            return "LPAD($col,$length,$fill)";
        }
    }
    elsif ( $func =~ /^RPAD\z/i ) {
        my $length = $arg1;
        my $fill = $arg2;
        if ( $sf->{i}{driver} eq 'SQLite' ) {
            $fill = ' ' if ! length $fill;
            $fill = $sf->{d}{dbh}->quote( $fill x $length );
            return "SUBSTR($col||$fill,1,$length)";
        }
        else {
            return "RPAD($col,$length)" if ! length $fill;
            $fill = $sf->{d}{dbh}->quote( $fill );
            return "RPAD($col,$length,$fill)";
        }
    }
    else {
        return "$func($col,$arg1,$arg2)"; # none
    }
}


sub concatenate {
    my ( $sf, $cols, $sep ) = @_;
    my $arg;
    if ( defined $sep && length $sep ) {
        my $qt_sep = $sf->{d}{dbh}->quote( $sep );
        for ( @$cols ) {
            push @$arg, $_, $qt_sep;
        }
        pop @$arg;
    }
    else {
        $arg = $cols
    }
    return "CONCAT(" . join( ',', @$arg ) . ")"  if $sf->{i}{driver} =~ /^(?:mysql|MariaDB)\z/;
    return join( " || ", @$arg );  # ansi 2003
}


sub coalesce {
    my ( $sf, $cols ) = @_;
    return "COALESCE(" . join( ',', @$cols ) . ")"

}


sub epoch_to_date {
    my ( $sf, $col, $interval ) = @_;
    my $driver = $sf->{i}{driver};
    return "DATE($col/$interval,'unixepoch','localtime')"                                  if $driver eq 'SQLite';
    return "FROM_UNIXTIME($col/$interval,'%Y-%m-%d')"                                      if $driver =~ /^(?:mysql|MariaDB)\z/;
    return "TO_TIMESTAMP(${col}::bigint/$interval)::date"                                  if $driver eq 'Pg';
    return "DATEADD(CAST($col AS BIGINT)/$interval SECOND TO DATE '1970-01-01')"           if $driver eq 'Firebird';
    return "TIMESTAMP('1970-01-01') + ($col/$interval) SECONDS"                            if $driver eq 'DB2';
    return "TO_CHAR(DBINFO('utc_to_datetime',$col/$interval),'%Y-%m-%d')"                  if $driver eq 'Informix';
    return "TO_DATE('1970-01-01','YYYY-MM-DD') + NUMTODSINTERVAL($col/$interval,'SECOND')" if $driver eq 'Oracle';
}


sub epoch_to_datetime {
    my ( $sf, $col, $interval ) = @_;
    my $driver = $sf->{i}{driver};
    if ( $driver eq 'SQLite' ) {
        if ( $interval == 1 ) {
            return "DATETIME($col,'unixepoch','localtime')";
        }
        else {
            return "STRFTIME('%Y-%m-%d %H:%M:%f',$col/$interval.0, 'unixepoch','localtime')";
        }
    }
    elsif ( $driver =~ /^(?:mysql|MariaDB)\z/ ) {
        # mysql: FROM_UNIXTIME doesn't work with negative timestamps
        if ( $interval == 1 ) {
            return "FROM_UNIXTIME($col)";
        }
        elsif ( $interval == 1_000 ) {
            return "FROM_UNIXTIME($col * 0.001)";
        }
        else {
            return "FROM_UNIXTIME($col * 0.000001)";
        }
    }
    elsif ( $driver eq 'Pg' ) {
        if ( $interval == 1 ) {
            return "TO_TIMESTAMP(${col}::bigint)::timestamp"
        }
        elsif ( $interval == 1_000 ) {
            return "TO_CHAR(TO_TIMESTAMP(${col}::bigint/$interval.0) at time zone 'UTC','yyyy-mm-dd hh24:mi:ss.ff3')";
        }
        else {
            return "TO_CHAR(TO_TIMESTAMP(${col}::bigint/$interval.0) at time zone 'UTC','yyyy-mm-dd hh24:mi:ss.ff6')";
        }
    }
    elsif ( $driver eq 'Firebird' ) {
        if ( $interval == 1 ) {
            return "SUBSTRING(CAST(DATEADD(SECOND,CAST($col AS BIGINT),TIMESTAMP '1970-01-01 00:00:00') AS VARCHAR(24)) FROM 1 FOR 19)";
        }
        elsif ( $interval == 1_000 ) {
            $interval /= 1_000;
            return "SUBSTRING(CAST(DATEADD(MILLISECOND,CAST($col AS BIGINT)/$interval,TIMESTAMP '1970-01-01 00:00:00') AS VARCHAR(24)) FROM 1 FOR 23)";
        }
        else {
            $interval /= 1_000;                        # don't remove the ".0"
            return "CAST(DATEADD(MILLISECOND,CAST($col AS BIGINT)/$interval.0,TIMESTAMP '1970-01-01 00:00:00') AS VARCHAR(24))";
        }
    }
    elsif ( $driver eq 'DB2' ) {
        if ( $interval == 1 ) {
            return "TIMESTAMP('1970-01-01 00:00:00',0) + $col SECONDS";
        }
        elsif ( $interval == 1_000 ) {
            return "TIMESTAMP('1970-01-01 00:00:00',3) + ($col/$interval) SECONDS";
        }
        else {
            return "TIMESTAMP('1970-01-01 00:00:00',6) + ($col/$interval) SECONDS";
        }
    }
    elsif ( $driver eq 'Informix' ) {
        return "DBINFO('utc_to_datetime',$col/$interval)";
    }
    elsif ( $driver eq 'Oracle' ) {
        if ( $interval == 1 ) {
            return "TO_CHAR(TO_TIMESTAMP('19700101000000','YYYYMMDDHH24MISS')+NUMTODSINTERVAL($col,'SECOND'),'YYYY-MM-DD HH24:MI:SS')";
        }
        elsif ( $interval == 1_000 ) {
            return "TO_CHAR(TO_TIMESTAMP('19700101000000','YYYYMMDDHH24MISS')+NUMTODSINTERVAL($col/$interval,'SECOND'),'YYYY-MM-DD HH24:MI:SS.FF3')";
        }
        else {
            return "TO_CHAR(TO_TIMESTAMP('19700101000000','YYYYMMDDHH24MISS')+NUMTODSINTERVAL($col/$interval,'SECOND'),'YYYY-MM-DD HH24:MI:SS.FF6')";
        }
    }
}





1;
