#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

my $base = 'DateTime::Format::Flexible';

use DateTime::Format::Flexible;

{
    my $dt = $base->parse_datetime( '2007-10-01 13:11:32.741804' );
    is( $dt->datetime.'.'.$dt->nanosecond , '2007-10-01T13:11:32.741804' ,
        'recognize datetimes with milliseconds two digit month' );
}

{
    my $dt = $base->parse_datetime( '2007-1-01 13:11:32.741804' );
    is( $dt->datetime.'.'.$dt->nanosecond , '2007-01-01T13:11:32.741804' ,
        'recognize datetimes with milliseconds single digit month' );
}

{
    my $dt = $base->parse_datetime( '2007-1-1 13:11:32.741804' );
    is( $dt->datetime.'.'.$dt->nanosecond , '2007-01-01T13:11:32.741804' ,
        'recognize datetimes with milliseconds single digit month and day' );
}

{
    my $dt = $base->parse_datetime( '2007-10-1 13:11:32.741804' );
    is( $dt->datetime.'.'.$dt->nanosecond , '2007-10-01T13:11:32.741804' ,
        'recognize datetimes with milliseconds single digit day' );
}

{
    my $dt = $base->parse_datetime( '2007-10-01T13:11:32.741804' );
    is( $dt->datetime.'.'.$dt->nanosecond , '2007-10-01T13:11:32.741804' ,
        'recognize datetimes with T separating the date and time' );
}

{
    my $dt = $base->parse_datetime( '2009102812261137' );
    is( $dt->datetime , '2009-10-28T12:26:11' , 'can parse Y|M|D|H|M|S|HS' );
    is( $dt->millisecond , '370' , 'and the millisecond' );
}
