package main;

use strict;
use warnings;

use Test::More 0.47;

BEGIN {
    eval {
	require Test::MockTime;
	Test::MockTime->import( ':all' );
	1;
    } or plan skip_all => 'This test requires Test::MockTime';
}

use Date::Tolkien::Shire;
use Time::Local;

plan tests => 3;

set_absolute_time( timelocal( 0, 0, 12, 1, 3, 2016 ) );

my $dts = eval { Date::Tolkien::Shire->today() };

SKIP: {
    isa_ok( $dts, 'Date::Tolkien::Shire', 'today() returns object' )
	or skip( 'today() failed to return object', 2 );

    is( "$dts", 'Monday 10 Astron 7480',
	'today() gives the correct Shire date' );

    cmp_ok( $dts->time_in_seconds(), '==', timelocal( 0, 0, 0, 1, 3, 2016 ),
	'today() creates an object set to midnight the current day' );
}

1;

# ex: set textwidth=72 :
