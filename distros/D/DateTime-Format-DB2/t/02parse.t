use strict;

use Test::More tests => 21;

use DateTime::Format::DB2;

my $db2 = 'DateTime::Format::DB2';

{
    my $dt = $db2->parse_date( '2003-02-15' );
    is( $dt->year, 2003 );
    is( $dt->month, 2 );
    is( $dt->day, 15 );
}

# {
#     my $dt = $db2->parse_time( '10:09:08' );
#     is( $dt->hour, 10 );
#     is( $dt->minute, 9 );
#     is( $dt->second, 8 );
# }

{
    my $dt = $db2->parse_timestamp( '2003-02-15-10.09.08.200000' );
    is( $dt->year, 2003 );
    is( $dt->month, 2 );
    is( $dt->day, 15 );
    is( $dt->hour, 10 );
    is( $dt->minute, 9 );
    is( $dt->second, 8 );
}

{
    my $dt = $db2->parse_timestamp( '2003-02-15 10:09:08.200000' );
    is( $dt->year, 2003 );
    is( $dt->month, 2 );
    is( $dt->day, 15 );
    is( $dt->hour, 10 );
    is( $dt->minute, 9 );
    is( $dt->second, 8 );
}

{
    my $dt = $db2->parse_datetime( '2003-02-15 10:09:08.200000' );
    is( $dt->year, 2003 );
    is( $dt->month, 2 );
    is( $dt->day, 15 );
    is( $dt->hour, 10 );
    is( $dt->minute, 9 );
    is( $dt->second, 8 );
}


