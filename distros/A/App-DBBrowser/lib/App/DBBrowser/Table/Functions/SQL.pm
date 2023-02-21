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
    $func = uc( $func );
    if ( $func eq 'LTRIM' ) {
        return "TRIM(LEADING FROM $col)"  if $sf->{i}{driver} =~ /^(?:Pg|Firebird|Informix)\z/;
        return "LTRIM($col)";
    }
    elsif ( $func eq 'RTRIM' ) {
        return "TRIM(TRAILING FROM $col)" if $sf->{i}{driver} =~ /^(?:Pg|Firebird|Informix)\z/;
        return "RTRIM($col)";
    }
    elsif ( $func eq 'BIT_LENGTH' ) {
        return "OCTET_LENGTH($col)" if $sf->{i}{driver} eq 'Informix';
        return "BIT_LENGTH($col)";
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
    return "DATE($col/$interval,'unixepoch','localtime')"                                  if $sf->{i}{driver} eq 'SQLite';
    return "FROM_UNIXTIME($col/$interval,'%Y-%m-%d')"                                      if $sf->{i}{driver} =~ /^(?:mysql|MariaDB)\z/;
    return "TO_TIMESTAMP(${col}::bigint/$interval)::date"                                  if $sf->{i}{driver} eq 'Pg';
    return "DATEADD(CAST($col AS BIGINT)/$interval SECOND TO DATE '1970-01-01')"           if $sf->{i}{driver} eq 'Firebird';
    return "TIMESTAMP('1970-01-01') + ($col/$interval) SECONDS"                            if $sf->{i}{driver} eq 'DB2';
    return "TO_DATE('1970-01-01','YYYY-MM-DD') + NUMTODSINTERVAL($col/$interval,'SECOND')" if $sf->{i}{driver} eq 'Oracle';
}


sub epoch_to_datetime {
    my ( $sf, $col, $interval ) = @_;
    if ( $sf->{i}{driver} eq 'SQLite' ) {
        if ( $interval == 1 ) {
            return "DATETIME($col,'unixepoch','localtime')";
        }
        else {
            return "STRFTIME( '%Y-%m-%d %H:%M:%f', $col/$interval.0, 'unixepoch', 'localtime' )";
        }
    }
    elsif ( $sf->{i}{driver} =~ /^(?:mysql|MariaDB)\z/ ) {
        # mysql: FROM_UNIXTIME doesn't work with negative timestamps
        # https://stackoverflow.com/questions/26299149/timestamp-with-a-millisecond-precision-how-to-save-them-in-mysql
        if ( $interval == 1 ) {
            return "FROM_UNIXTIME($col)";
        }
        elsif ( $interval == 1_000 ) {
            return "FROM_UNIXTIME($col * 0.001)";
        }
        else {
            return "FROM_UNIXTIME($col * 0.000001)";
            #return "FROM_UNIXTIME($col/$interval,'%Y-%m-%d %H:%i:%s.%f')";
        }
    }
    elsif ( $sf->{i}{driver} eq 'Pg' ) {
        if ( $interval == 1 ) {
            return "TO_TIMESTAMP(${col}::bigint)::timestamp"
        }
        elsif ( $interval == 1_000 ) {
            return "TO_CHAR(TO_TIMESTAMP(${col}::bigint/$interval.0) at time zone 'UTC', 'yyyy-mm-dd hh24:mi:ss.ff3')";
        }
        else {
            return "TO_CHAR(TO_TIMESTAMP(${col}::bigint/$interval.0) at time zone 'UTC', 'yyyy-mm-dd hh24:mi:ss.ff6')";
        }
    }
    elsif ( $sf->{i}{driver} eq 'Firebird' ) {
        if ( $interval == 1 ) {
            return "SUBSTRING(CAST(DATEADD(SECOND,CAST($col AS BIGINT),TIMESTAMP '1970-01-01 00:00:00') AS VARCHAR(24)) FROM 1 FOR 19)";
        }
        elsif ( $interval == 1_000 ) {
            $interval /= 1_000;
            return "SUBSTRING(CAST(DATEADD(MILLISECOND,CAST($col AS BIGINT)/$interval,TIMESTAMP '1970-01-01 00:00:00') AS VARCHAR(24)) FROM 1 FOR 23)";
        }
        else {
            $interval /= 1_000;                     # works with: $interval.0
            return "CAST(DATEADD(MILLISECOND,CAST($col AS BIGINT)/$interval.0,TIMESTAMP '1970-01-01 00:00:00') AS VARCHAR(24))";
        }
    }
    elsif ( $sf->{i}{driver} eq 'DB2' ) {
        if ( $interval == 1 ) {
            return "TIMESTAMP('1970-01-01 00:00:00', 0) + $col SECONDS";
        }
        elsif ( $interval == 1_000 ) {
            return "TIMESTAMP('1970-01-01 00:00:00', 3) + ($col/$interval) SECONDS";
        }
        else {
            return "TIMESTAMP('1970-01-01 00:00:00', 6) + ($col/$interval) SECONDS";
        }
    }
    elsif ( $sf->{i}{driver} eq 'Oracle' ) {
        if ( $interval == 1 ) {
            return "TO_TIMESTAMP('1970-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS') + NUMTODSINTERVAL($col,'SECOND')"
        }
        else {
            return "TO_TIMESTAMP('1970-01-01 00:00:00.0','YYYY-MM-DD HH24:MI:SS.FF') + NUMTODSINTERVAL($col/$interval,'SECOND')";
        }
    }
}


sub replace {
    my ( $sf, $col, $string_to_replace, $replacement_string ) = @_;
    return "REPLACE($col,$string_to_replace,$replacement_string)";
}




1;
