package # hide from PAUSE
App::DBBrowser::Table::Functions::SQL;

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


sub function_with_col {
    my ( $sf, $func, $col ) = @_;
    my $driver = $sf->{i}{driver};
    $func = uc( $func );
    if ( $func eq 'LTRIM' ) {
        return "TRIM(LEADING FROM $col)"  if $driver =~ /^(?:Pg|Firebird|Informix)\z/;
        return "LTRIM($col)";
    }
    elsif ( $func eq 'RTRIM' ) {
        return "TRIM(TRAILING FROM $col)" if $driver =~ /^(?:Pg|Firebird|Informix)\z/;
        return "RTRIM($col)";
    }
    elsif ( $func eq 'OCTET_LENGTH' ) {
        return "OCTET_LENGTH($col)";
    }
    elsif ( $func =~ /^CHAR_LENGTH/ ) {
        if ( $driver eq 'SQLite' ) {
            return "LENGTH($col)";
        }
        elsif ( $driver eq 'DB2' ) {
            return "CHARACTER_LENGTH($col,CODEUNITS16)" if $func eq 'CHAR_LENGTH_16';
            return "CHARACTER_LENGTH($col,CODEUNITS32)" if $func eq 'CHAR_LENGTH_32';
        }
        else {
            return "CHAR_LENGTH($col)";
        }
    }
    else {
        return "$func($col)";
    }
}


sub function_with_col_and_arg {
    my ( $sf, $func, $col, $arg ) = @_;
    $func = uc( $func );
    if ( $func eq 'CAST' ) {
        return "CAST($col AS $arg)";
    }
    elsif ( $func eq 'ROUND' ) {
        return "ROUND($col,$arg)";
    }
    elsif ( $func eq 'TRUNCATE' ) {
        #if ( $sf->{i}{driver} eq 'SQLite' ) {
        #    my $prec_num = '1' . '0' x $arg;
        #    return "cast( ( $col * $prec_num ) as int ) / $prec_num.0";
        #}
        return "TRUNC($col,$arg)"     if $sf->{i}{driver} =~ /^(?:Pg|Firebird|Informix|Oracle)\z/;
        return "TRUNCATE($col,$arg)";
    }
    else {
        return "$func($col,$arg)"; # none
    }
}


sub function_with_col_and_2args {
    my ( $sf, $func, $col, $arg1, $arg2 ) = @_;
    my $driver = $sf->{i}{driver};
    if ( $func eq 'REPLACE' ) {
        my $string_to_replace =  $sf->{d}{dbh}->quote( $arg1 );
        my $replacement_string = $sf->{d}{dbh}->quote( $arg2 );
        return "REPLACE($col,$string_to_replace,$replacement_string)";
    }
    elsif ( $func eq 'SUBSTR' ) {
        my $startpos = $arg1;
        my $length = $arg2;
        if ( $driver =~ /^(?:SQLite|mysql|MariaDB)\z/ ) {
            return "SUBSTR($col,$startpos,$length)" if length $length;
            return "SUBSTR($col,$startpos)";
        }
        else {
            return "SUBSTRING($col FROM $startpos FOR $length)" if length $length;
            return "SUBSTRING($col FROM $startpos)";
        }
    }
    else {
        return "$func($col,$arg1,$arg2)"; # none
    }
}


sub concatenate {
    my ( $sf, $arguments, $sep ) = @_;
    my $arg;
    if ( defined $sep && length $sep ) {
        my $qt_sep = "'" . $sep . "'";
        for ( @$arguments ) {
            push @$arg, $_, $qt_sep;
        }
        pop @$arg;
    }
    else {
        $arg = $arguments
    }
    return "CONCAT(" . join( ',', @$arg ) . ")"  if $sf->{i}{driver} =~ /^(?:mysql|MariaDB)\z/;
    return join( " || ", @$arg );
}


sub epoch_to_date {
    my ( $sf, $col, $interval ) = @_;
    my $driver = $sf->{i}{driver};
    return "DATE($col/$interval,'unixepoch','localtime')"                                  if $driver eq 'SQLite';
    return "FROM_UNIXTIME($col/$interval,'%Y-%m-%d')"                                      if $driver =~ /^(?:mysql|MariaDB)\z/;
    return "TO_TIMESTAMP(${col}::bigint/$interval)::date"                                  if $driver eq 'Pg';
    return "DATEADD(CAST($col AS BIGINT)/$interval SECOND TO DATE '1970-01-01')"           if $driver eq 'Firebird';
    return "TIMESTAMP('1970-01-01') + ($col/$interval) SECONDS"                            if $driver eq 'DB2';
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
            return "TO_TIMESTAMP('1970-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS') + NUMTODSINTERVAL($col,'SECOND')"
        }
        else {
            return "TO_TIMESTAMP('1970-01-01 00:00:00.0','YYYY-MM-DD HH24:MI:SS.FF') + NUMTODSINTERVAL($col/$interval,'SECOND')";
        }
    }
}





1;
