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

use DateTime;
use DateTime::Fiction::JRRTolkien::Shire;
use Time::Local;

plan tests => 17;

my ( $dt, $shire );

set_absolute_time( timegm( 0, 0, 12, 1, 3, 2016 ) );

$shire = DateTime::Fiction::JRRTolkien::Shire->now();
is( $shire->iso8601(), '7480-04-10S12:00:00', 'now() Shire date' );
is( $shire->time_zone_short_name(), 'UTC', 'now() produces UTC' );
$dt = DateTime->from_object( object => $shire );
is( $dt->iso8601(), '2016-04-01T12:00:00', 'now() round-trip' );

$shire = DateTime::Fiction::JRRTolkien::Shire->today();
is( $shire->iso8601(), '7480-04-10S00:00:00', 'today() Shire date' );
is( $shire->time_zone_short_name(), 'UTC', 'today() produces UTC' );
$dt = DateTime->from_object( object => $shire );
is( $dt->iso8601(), '2016-04-01T00:00:00', 'today() round-trip' );

set_absolute_time( timelocal( 0, 0, 12, 1, 3, 2016 ) );

$shire = DateTime::Fiction::JRRTolkien::Shire->now_local();
is( $shire->iso8601(), '7480-04-10S12:00:00', 'now_local() Shire date' );
is( $shire->time_zone_short_name(), 'floating',
    'now_local() produces floating' );
$dt = DateTime->from_object( object => $shire );
is( $dt->iso8601(), '2016-04-01T12:00:00', 'now_local() round-trip' );

foreach my $arg ( qw{ accented traditional } ) {
    local $@ = undef;
    foreach my $method ( qw{ now today } ) {
	my $rslt = eval {
	    DateTime::Fiction::JRRTolkien::Shire->$method( $arg => 1 );
	    1;
	} || 0;
	ok $rslt, "-$method() accepts ( $arg => 1 )";
    }
    {
	my $rslt = eval {
	    DateTime::Fiction::JRRTolkien::Shire->from_epoch(
		epoch	=> $dt->epoch(),
		$arg	=> 1,
	    );
	    1;
	} || 0;
	ok $rslt, "->from_epoch() accepts ( $arg => 1 )";
    }
    {
	my $rslt = eval {
	    DateTime::Fiction::JRRTolkien::Shire->from_object(
		object	=> $dt,
		$arg	=> 1,
	    );
	    1;
	} || 0;
	ok $rslt, "->from_object() accepts ( $arg => 1 )";
    }
}
