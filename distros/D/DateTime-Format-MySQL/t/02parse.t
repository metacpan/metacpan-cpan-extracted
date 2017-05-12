use strict;

use Test::More tests => 84;

use DateTime::Format::MySQL;

my $mysql = 'DateTime::Format::MySQL';

{
    my $dt = $mysql->parse_date( '2003_02_15' );
    is( $dt->year, 2003 );
    is( $dt->month, 2 );
    is( $dt->day, 15 );
}

{
    my $dt = $mysql->parse_datetime( '2003-02-15 10:09:08' );
    is( $dt->year, 2003 );
    is( $dt->month, 2 );
    is( $dt->day, 15 );
    is( $dt->hour, 10 );
    is( $dt->minute, 9 );
    is( $dt->second, 8 );
}

{
    my $dt = $mysql->parse_datetime( '2003-02-15 10:09:08.2' );
    is( $dt->year, 2003 );
    is( $dt->month, 2 );
    is( $dt->day, 15 );
    is( $dt->hour, 10 );
    is( $dt->minute, 9 );
    is( $dt->second, 8 );
    is( $dt->microsecond, 200_000 );
    is( $dt->nanosecond, 200_000_000 );
}

{
    my $dt = $mysql->parse_datetime( '2014:10:26 01:02:03.002' );
    is( $dt->year, 2014 );
    is( $dt->month, 10 );
    is( $dt->day_of_month, 26 );
    is( $dt->hour, 1 );
    is( $dt->minute, 02 );
    is( $dt->second, 03 );
    is( $dt->microsecond, 2_000 );
    is( $dt->nanosecond, 2_000_000 );
} 

{
    my $dt = $mysql->parse_timestamp( '2003-02-15 10:09:08.0' );
    is( $dt->year, 2003 );
    is( $dt->month, 2 );
    is( $dt->day, 15 );
    is( $dt->hour, 10 );
    is( $dt->minute, 9 );
    is( $dt->second, 8 );
    is( $dt->microsecond, 0 );
    is( $dt->nanosecond, 0 );
}

{
    my $dt = $mysql->parse_timestamp( '2014:10:26 01:02:03' );
    is( $dt->year, 2014 );
    is( $dt->month, 10 );
    is( $dt->day_of_month, 26 );
    is( $dt->hour, 1 );
    is( $dt->minute, 02 );
    is( $dt->second, 03 );
    is( $dt->microsecond, 0 );
    is( $dt->nanosecond, 0 );
} 

{
    my $dt = $mysql->parse_datetime( '2014-10-26T01:02:03.2' );
    is( $dt->year, 2014 );
    is( $dt->month, 10 );
    is( $dt->day_of_month, 26 );
    is( $dt->hour, 1 );
    is( $dt->minute, 02 );
    is( $dt->second, 03 );
    is( $dt->microsecond, 200_000 );
    is( $dt->nanosecond, 200_000_000 );
}  

{
    my $dt = $mysql->parse_timestamp( '2014^1^6 1^2^3.123456' );
    is( $dt->year, 2014 );
    is( $dt->month, 1 );
    is( $dt->day_of_month, 6 );
    is( $dt->hour, 1 );
    is( $dt->minute, 2 );
    is( $dt->second, 3 );
    is( $dt->microsecond, 123_456 );
    is( $dt->nanosecond, 123_456_000 );
} 

{
    my $dt = $mysql->parse_timestamp('70');
    is( $dt->year, 1970 );
}

{
    my $dt = $mysql->parse_timestamp('69');
    is( $dt->year, 2069 );
}

{
    my $dt = $mysql->parse_timestamp('1202');
    is( $dt->year, 2012 );
    is( $dt->month, 2 );
}

{
    my $dt = $mysql->parse_timestamp('120211');
    is( $dt->year, 2012 );
    is( $dt->month, 2 );
    is( $dt->day_of_month, 11 );
}

{
    my $dt = $mysql->parse_timestamp('20120211');
    is( $dt->year, 2012 );
    is( $dt->month, 2 );
    is( $dt->day_of_month, 11 );
}

{
    my $dt = $mysql->parse_timestamp('1202110545');
    is( $dt->year, 2012 );
    is( $dt->month, 2 );
    is( $dt->day_of_month, 11 );
    is( $dt->hour, 5 );
    is( $dt->minute, 45 );
}

{
    my $dt = $mysql->parse_timestamp('120211054537');
    is( $dt->year, 2012 );
    is( $dt->month, 2 );
    is( $dt->day_of_month, 11 );
    is( $dt->hour, 5 );
    is( $dt->minute, 45 );
    is( $dt->second, 37 );
}

{
    my $dt = $mysql->parse_timestamp('20120211054537');
    is( $dt->year, 2012 );
    is( $dt->month, 2 );
    is( $dt->day_of_month, 11 );
    is( $dt->hour, 5 );
    is( $dt->minute, 45 );
    is( $dt->second, 37 );
}
