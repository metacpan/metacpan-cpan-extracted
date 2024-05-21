package # hide from PAUSE
App::DBBrowser::Table::Extensions::ScalarFunctions::SQL;

use warnings;
use strict;
use 5.014;

use App::DBBrowser::Auxil;


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
    if ( $func eq 'NOW' ) {
        return "strftime('%Y-%m-%d %H-%M-%S','now')" if $driver eq 'SQLite';
        return "timestamp 'NOW'"                     if $driver eq 'Firebird';
        return "CURRENT"                             if $driver eq 'Informix'; # "CURRENT YEAR TO SECOND"
        return "NOW()"                               if $driver =~ /^(?:mysql|MariaDB|Pg)\z/;
        return "CURRENT_TIMESTAMP"; # ansi 2003
        # "CURRENT_TIMESTAMP(9)"
    }
    elsif ( $func eq 'RAND' ) {
        return "RANDOM()"          if $driver =~ /^(?:SQLite|Pg)\z/;
        return "DBMS_RANDOM.VALUE" if $driver eq 'Oracle';
        return "RAND()";
    }
    else {
        return "$func()"; # none
    }
}


sub function_with_one_col {
    my ( $sf, $func, $col, $args ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $driver = $sf->{i}{driver};
    $func = uc( $func );
    if ( $func =~ /^(?:YEAR|QUARTER|MONTH|WEEK|DAY|HOUR|MINUTE|SECOND|DAYOFWEEK|DAYOFYEAR)\z/ ) {
        return $sf->function_with_one_col( 'EXTRACT', $col, [ $func ] );
    }
    elsif ( $func eq 'CAST' ) {
        my ( $data_type ) = @$args;
        return "CAST($col AS $data_type)";
    }
    elsif ( $func eq 'DATEADD' ) {
        my ( $amount, $unit ) = @$args;
        return                                         if ! defined $amount || ! defined $unit;
        return "DATETIME($col,$amount || ' $unit')"    if $driver eq 'SQLite';
        return "DATE_ADD($col,INTERVAL $amount $unit)" if $driver =~ /^(?:mysql|MariaDB)\z/;
        return "$col + $amount * INTERVAL '1 $unit'"   if $driver eq 'Pg';
        return "ADD_${unit}S($col,$amount)"            if $driver eq 'DB2';
        return "$col + $amount UNITS $unit"            if $driver eq 'Informix';
        return "DATEADD($unit,$amount,$col)";
    }
    elsif ( $func eq 'EXTRACT' ) {
        my ( $field ) = @$args;
        if ( $driver eq 'SQLite' ) {
            return "CEILING(strftime('%m',$col)/3.00)" if $field eq 'QUARTER';
            my %map = ( YEAR => '%Y', MONTH => '%m', WEEK => '%W', DAY => '%d', HOUR => '%H', MINUTE => '%M', SECOND => '%S',
                        DAYOFYEAR => '%j', DAYOFWEEK => '%w',
            );
            if ( $map{ uc( $field ) } ) {
                $field = "'" . $map{ uc( $field ) } . "'";
            }
            return "strftime($field,$col)";
        }
        elsif ( $driver =~ /^(?:mysql|MariaDB|DB2|Informix)\z/ ) {
            return "EXTEND($col,$field to $field)" if $driver eq 'Informix' && $field =~ /^(?:HOUR|MINUTE|SECOND)\z/;
            return "$field($col)";
            # mysql: WEEKDAY:   0 = Monday
            # mysql: DAYOFWEEK: 1 = Sunday
            # DB2: DAYOFWEEK_ISO: 1 = Monday
            # DB2: DAYOFWEEK:     1 = Sunday
        }
        elsif ( $driver eq 'Pg' ) {
            return "EXTRACT(DOW FROM $col)" if $field eq 'DAYOFWEEK';
            return "EXTRACT(DOY FROM $col)" if $field eq 'DAYOFYEAR';
            return "EXTRACT($field FROM $col)";
            # Pg: ISODOW: 1 = Monday
            # Pg: DOW:    0 = Sunday
        }
        elsif ( $driver eq 'Firebird' ) {
            return "CEILING(EXTRACT(MONTH FROM $col)/3.00)" if $field eq 'QUARTER';
            return "EXTRACT(WEEKDAY FROM $col)"             if $field eq 'DAYOFWEEK';
            return "EXTRACT(YEARDAY FROM $col)"             if $field eq 'DAYOFYEAR';
            return "EXTRACT($field FROM $col)";
        }
        elsif ( $driver eq 'Oracle' ) {
            return "to_char($col,'Q')"   if $field eq 'QUARTER';
            return "to_char($col,'WI')"  if $field eq 'WEEK'; # WW
            return "to_char($col,'D')"   if $field eq 'DAYOFWEEK';
            return "to_char($col,'DDD')" if $field eq 'DAYOFYEAR';
            return "EXTRACT($field FROM $col)";
        }
        else {
            return "CEILING(EXTRACT(MONTH FROM $col)/3.00)" if $field eq 'QUARTER';
            return "EXTRACT($field FROM $col)";
        }
    }
    elsif ( $func eq 'LEFT' ) {
        my ( $length ) = @$args;
        return                          if ! defined $length;
        return "SUBSTR($col,1,$length)" if $driver eq 'SQLite';
        return "LEFT($col,$length)";
    }
    elsif ( $func eq 'LOCATE' ) {
        my ( $substring, $start ) = @$args;
        return                                   if ! defined $substring;
        return "LOCATE($substring,$col)"         if ! defined $start;
        return "LOCATE($substring,$col,$start)";
    }
    elsif ( $func eq 'LPAD' ) {
        my ( $length, $fill ) = @$args;
        return if ! defined $length;
        if ( $driver eq 'SQLite' ) {
            $fill = defined $fill ? $ax->unquote_constant( $fill ) : ' ';
            $fill = $sf->{d}{dbh}->quote( $fill x $length );
            return "SUBSTR($fill||$col,-$length,$length)";
        }
        else {
            return "LPAD($col,$length)"        if ! defined $fill;
            return "LPAD($col,$length,$fill)";
        }
    }
    elsif ( $func eq 'POSITION' ) {
        my ( $substring, $start ) = @$args;
        if ( $driver eq 'Firebird' ) {
            return "POSITION($substring,$col)"         if ! defined $start;
            return "POSITION($substring,$col,$start)";
        }
        return "POSITION($substring IN $col)";
    }
    elsif ( $func eq 'RIGHT' ) {
        my ( $length ) = @$args;
        return                         if ! defined $length;
        return "SUBSTR($col,-$length)" if $driver eq 'SQLite';
        return "RIGHT($col,$length)";
    }
    elsif ( $func eq 'RPAD' ) {
        my ( $length, $fill ) = @$args;
        return if ! defined $length;
        if ( $driver eq 'SQLite' ) {
            $fill = defined $fill ? $ax->unquote_constant( $fill ) : ' ';
            $fill = $sf->{d}{dbh}->quote( $fill x $length );
            return "SUBSTR($col||$fill,1,$length)";
        }
        else {
            return "RPAD($col,$length)"        if ! defined $fill;
            return "RPAD($col,$length,$fill)";
        }
    }
    elsif ( $func eq 'STRFTIME' ) {
        my ( $format, $modifiers ) = @$args;
        return "STRFTIME($format,$col)"             if ! defined $modifiers;
        return "STRFTIME($format,$col,$modifiers)";
    }
    elsif ( $func eq 'SUBSTRING' ) {
        my ( $startpos, $length ) = @$args;
        return                                               if ! defined $startpos;
        return "SUBSTRING($col FROM $startpos)"              if ! defined $length;
        return "SUBSTRING($col FROM $startpos FOR $length)";
    }
    elsif ( $func eq 'TRIM' ) {
        if ( $driver eq 'SQLite' ) {
            my ( $what ) = @$args;
            return "TRIM($col)"        if ! defined $what;
            return "TRIM($col,$what)";
        }
        else {
            my ( $where, $what ) = @$args;
            my $tmp = join ' ', grep { length } $where, $what;
            return "TRIM($col)"            if ! length $tmp;
            return "TRIM($tmp FROM $col)";
        }
    }
    elsif ( $func eq 'TO_EPOCH' ) {
        if ( $driver eq 'SQLite' ) {
            return "UNIXEPOCH($col,'utc','subsec')"; # subsec: sqlite 3.42.0
        }
        elsif ( $driver =~ /^(?:mysql|MariaDB)\z/ ) {
            return "UNIX_TIMESTAMP($col)";
        }
        elsif ( $driver eq 'Pg' ) {
            return "EXTRACT(EPOCH FROM ${col}::timestamp with time zone)";
        }
        elsif ( $driver eq 'Firebird' ) {
            #my $firebird_major_version = $ax->major_server_version();
            my $firebird_major_version = 3; ##
            return "DATEDIFF(SECOND,TIMESTAMP '1970-01-01 00:00:00 UTC',$col)" if $firebird_major_version >= 4;
            return "DATEDIFF(SECOND,TIMESTAMP '1970-01-01 00:00:00',$col)"; # no timezone
            #return "DATEDIFF(MILLISECOND,TIMESTAMP '1970-01-01 00:00:00',$col) * 0.001";   # * 0.001 doesn't work in version 4 ##
        }
        elsif ( $driver eq 'DB2' ) {
            return "EXTRACT(EPOCH FROM $col)"; # no timezone
        }
        elsif ( $driver eq 'Oracle' ) {
            my ( $column_type ) = @$args;
            return "TRUNC((CAST($col AT TIME ZONE 'UTC' AS DATE) - DATE '1970-01-01') * 86400)"                                              if $column_type eq 'TIMESTAMP_TZ';
            return "TRUNC((CAST(FROM_TZ($col,SESSIONTIMEZONE) AT TIME ZONE 'UTC' AS DATE) - DATE '1970-01-01') * 86400)"                     if $column_type eq 'TIMESTAMP';
            return "TRUNC((CAST(FROM_TZ(CAST($col AS TIMESTAMP),SESSIONTIMEZONE) AT TIME ZONE 'UTC' AS DATE) - DATE '1970-01-01') * 86400)";                   # DATE
        }
    }
    else {
        my $function_stmt = "$func($col";
        for my $arg ( @$args ) {
            last if ! defined $arg;
            $function_stmt .= ",$arg";
        }
        return $function_stmt . ")";
    }
}


sub concatenate {
    my ( $sf, $cols, $sep ) = @_;
    my $arg;
    if ( length $sep ) {
        for ( @$cols ) {
            push @$arg, $_, $sep;
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
    #my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $driver = $sf->{i}{driver};
    if ( $driver eq 'SQLite' ) {
        return "DATE($col/$interval,'unixepoch','localtime')";
    }
    elsif ( $driver =~ /^(?:mysql|MariaDB)\z/ ) {
        return "FROM_UNIXTIME($col/$interval,'%Y-%m-%d')";
    }
    elsif ( $driver eq 'Pg' ) {
        return "TO_TIMESTAMP(${col}::bigint/$interval)::date";
    }
    elsif ( $driver eq 'Firebird' ) {
        #my $firebird_major_version = $ax->major_server_version();
        my $firebird_major_version = 3; ##
        if ( $firebird_major_version >= 4 ) {
            #return "DATEADD(CAST($col AS BIGINT)/$interval SECOND TO DATE '1970-01-01 UTC') AT LOCAL";
            return "CAST(DATEADD(CAST($col AS BIGINT)/$interval SECOND TO DATE '1970-01-01 UTC') AT LOCAL AS VARCHAR(10))";
        }
        else {
            #   return "DATEADD(CAST($col AS BIGINT)/$interval SECOND TO DATE '1970-01-01')";
            return "CAST(DATEADD(CAST($col AS BIGINT)/$interval SECOND TO DATE '1970-01-01') AS VARCHAR(10))";
        }
    }
    elsif ( $driver eq 'DB2' ) {
        return "TIMESTAMP('1970-01-01') + ($col/$interval) SECONDS";
    }
    elsif ( $driver eq 'Informix' ) {
        return "TO_CHAR(DBINFO('utc_to_datetime',$col/$interval),'%Y-%m-%d')";
    }
    elsif ( $driver eq 'Oracle' ) {
        return "TO_CHAR((TIMESTAMP '1970-01-01 00:00:00 UTC' + $col/$interval * INTERVAL '1' SECOND) AT TIME ZONE SESSIONTIMEZONE,'YYYY-MM-DD')";
    }
}


sub epoch_to_timestamp {
    my ( $sf, $col, $interval ) = @_;
    #my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $driver = $sf->{i}{driver};
    if ( $driver eq 'Pg' ) {
        return "TO_TIMESTAMP(${col}::bigint)::timestamptz"              if $interval == 1;
        return "TO_TIMESTAMP(${col}::bigint/$interval.0)::timestamptz";
    }
    elsif ( $driver eq 'Firebird' ) {
        #my $firebird_major_version = $ax->major_server_version();
        my $firebird_major_version = 3; ##
        if ( $firebird_major_version >= 4 ) {
            return "DATEADD(SECOND,$col,TIMESTAMP '1970-01-01 UTC') AT LOCAL"                                 if $interval == 1;
            return "DATEADD(MILLISECOND,CAST($col AS BIGINT),TIMESTAMP '1970-01-01 UTC') AT LOCAL"            if $interval == 1_000;
            $interval /= 1_000;
            return "DATEADD(MILLISECOND,CAST($col AS BIGINT)/$interval,TIMESTAMP '1970-01-01 UTC') AT LOCAL";
        }
        else {
            return "DATEADD(SECOND,$col,TIMESTAMP '1970-01-01')"                                 if $interval == 1;
            return "DATEADD(MILLISECOND,CAST($col AS BIGINT),TIMESTAMP '1970-01-01')"            if $interval == 1_000;
            $interval /= 1_000;
            return "DATEADD(MILLISECOND,CAST($col AS BIGINT)/$interval,TIMESTAMP '1970-01-01')";
        }
    }
    elsif ( $driver eq 'Oracle' ) {
        return "(TIMESTAMP '1970-01-01 00:00:00 UTC' + $col * INTERVAL '1' SECOND) AT TIME ZONE SESSIONTIMEZONE"            if $interval == 1;
        return "(TIMESTAMP '1970-01-01 00:00:00 UTC' + $col/$interval * INTERVAL '1' SECOND) AT TIME ZONE SESSIONTIMEZONE";
    }
}


sub epoch_to_datetime {
    my ( $sf, $col, $interval ) = @_;
    #my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $driver = $sf->{i}{driver};
    if ( $driver eq 'SQLite' ) {
        return "DATETIME($col,'unixepoch','localtime')"                       if $interval == 1;
        return "DATETIME($col/$interval.0,'unixepoch','localtime','subsec')";
    }
    elsif ( $driver =~ /^(?:mysql|MariaDB)\z/ ) {   # DATE_FORMAT and STR_TO_DATE ##
        # mysql: FROM_UNIXTIME doesn't work with negative timestamps
        return "FROM_UNIXTIME($col)"             if $interval == 1;
        return "FROM_UNIXTIME($col * 0.001)"     if $interval == 1_000;
        return "FROM_UNIXTIME($col * 0.000001)";
    }
    elsif ( $driver eq 'Pg' ) {
        return "TO_CHAR(TO_TIMESTAMP(${col}::bigint)::timestamp,'yyyy-mm-dd hh24:mi:ss')"                 if $interval == 1;
        return "TO_CHAR(TO_TIMESTAMP(${col}::bigint/$interval.0)::timestamp,'yyyy-mm-dd hh24:mi:ss.ff3')" if $interval == 1_000;
        return "TO_CHAR(TO_TIMESTAMP(${col}::bigint/$interval.0)::timestamp,'yyyy-mm-dd hh24:mi:ss.ff6')";
    }
    elsif ( $driver eq 'Firebird' ) {
        #my $firebird_major_version = $ax->major_server_version();
        my $firebird_major_version = 3; ##
        if ( $firebird_major_version >= 4 ) {
            return "SUBSTRING(CAST(DATEADD(SECOND,CAST($col AS BIGINT),TIMESTAMP '1970-01-01 UTC') AT LOCAL AS VARCHAR(24)) FROM 1 FOR 19)"      if $interval == 1;
            return "SUBSTRING(CAST(DATEADD(MILLISECOND,CAST($col AS BIGINT),TIMESTAMP '1970-01-01 UTC') AT LOCAL AS VARCHAR(24)) FROM 1 FOR 23)" if $interval == 1_000;
            $interval /= 1_000;                        # don't remove the ".0"
            return "CAST(DATEADD(MILLISECOND,CAST($col AS BIGINT)/$interval.0,TIMESTAMP '1970-01-01 UTC') AT LOCAL AS VARCHAR(24))";
        }
        else {
            return "SUBSTRING(CAST(DATEADD(SECOND,CAST($col AS BIGINT),TIMESTAMP '1970-01-01') AS VARCHAR(24)) FROM 1 FOR 19)"      if $interval == 1;
            return "SUBSTRING(CAST(DATEADD(MILLISECOND,CAST($col AS BIGINT),TIMESTAMP '1970-01-01') AS VARCHAR(24)) FROM 1 FOR 23)" if $interval == 1_000;
            $interval /= 1_000;                        # don't remove the ".0"
            return "CAST(DATEADD(MILLISECOND,CAST($col AS BIGINT)/$interval.0,TIMESTAMP '1970-01-01') AS VARCHAR(24))";
        }
    }
    elsif ( $driver eq 'DB2' ) { # TO_DATE and TO_CHAR ##
        return "TIMESTAMP('1970-01-01 00:00:00',0) + $col SECONDS"              if $interval == 1;
        return "TIMESTAMP('1970-01-01 00:00:00',3) + ($col/$interval) SECONDS"  if $interval == 1_000;
        return "TIMESTAMP('1970-01-01 00:00:00',6) + ($col/$interval) SECONDS";
    }
    elsif ( $driver eq 'Informix' ) { # TO_CHAR ##
        return "DBINFO('utc_to_datetime',$col)"            if $interval == 1;
        return "DBINFO('utc_to_datetime',$col/$interval)";
    }
    elsif ( $driver eq 'Oracle' ) {
        return "TO_CHAR((TIMESTAMP '1970-01-01 00:00:00 UTC' + $col * INTERVAL '1' SECOND) AT TIME ZONE SESSIONTIMEZONE,'YYYY-MM-DD HH24:MI:SS')"                if $interval == 1;
        return "TO_CHAR((TIMESTAMP '1970-01-01 00:00:00 UTC' + $col/$interval * INTERVAL '1' SECOND) AT TIME ZONE SESSIONTIMEZONE,'YYYY-MM-DD HH24:MI:SS.FF3')"  if $interval == 1_000;
        return "TO_CHAR((TIMESTAMP '1970-01-01 00:00:00 UTC' + $col/$interval * INTERVAL '1' SECOND) AT TIME ZONE SESSIONTIMEZONE,'YYYY-MM-DD HH24:MI:SS.FF6')";
    }
}



1;
