package main;

use strict;
use warnings;

use lib qw{ inc };

use Astro::Coord::ECI;
use Astro::Coord::ECI::Moon;
use Astro::Coord::ECI::Utils qw{ :time deg2rad PI TWOPI };
use My::Module::Test qw{ :tolerance format_time };
use Test::More 0.88;

# Moon position in ecliptic latitude/longitude and distance.
# Tests: ::Moon->time_set() (and ecliptic())

# This test is based on Meeus' example 47.a.

# Meeus states that his accuracy is 10 seconds of arc in longitude, and
# 4 seconds in latitude. He does not give an accuracy on the distance.

# Note that we're not too picky about the position of the sun, since
# it's an extended object. One part in a thousand is less than half its
# disk.

{
    my $time = time_gm( 0, 0, 0, 12, 3, 1992 );

    my ( $lat, $long, $delta ) = Astro::Coord::ECI::Moon->
	dynamical( $time )->ecliptic();

    tolerance_frac $lat, deg2rad( -3.229126 ), 1e-6,
	'Ecliptic latitude of Moon April 12 1992 00:00:00 dynamical';

    tolerance_frac $long, deg2rad( 133.167265 ), 1e-6,
	'Ecliptic longitude of Moon April 12 1992 00:00:00 dynamical';

    tolerance_frac $delta, 368409.7, 1e-6,
	'Ecliptic distance to Moon April 12 1992 00:00:00 dynamical';
}

# phase of the moon.
# Tests: phase ()

# This test is based on Meeus' example 49.a, but worked backward.

{
    my $time = time_gm( 42, 37, 3, 18, 1, 1977 );

    my $got = Astro::Coord::ECI::Moon->dynamical( $time )->phase();
    $got >= PI
	and $got -= TWOPI;

    tolerance $got, 0, 1e-4,
	'Phase of Moon February 18 1977 3:37:42 dynamical';
}

# Phase angle and illuminated fraction.

# This test is based on Meeus' example 48.a.

{
    my $time = time_gm( 0, 0, 0, 12, 3, 1992 );
    my ( $phase, $illum ) =
	Astro::Coord::ECI::Moon->dynamical( $time )->phase();

    tolerance $phase, deg2rad( 180 - 69.0756 ), 3e-3,
	'Phase of Moon April 12 1992 00:00:00 dynamical';

    tolerance $illum, .6786, .01,
	'Fraction of Moon illuminated April 12 1992 00:00:00 dynamical';
}


# next_quarter and next_quarter_hash

# This test is based on Meeus' example 49.1, right way around.

{
    my $time = time_gm( 0, 0, 0, 1, 1, 1977 );
    my $want = time_gm( 42, 37, 3, 18, 1, 1977 );
    my $moon = Astro::Coord::ECI::Moon->new();
    my $tolerance = 2;

    my $got = $moon->dynamical( $time )->next_quarter( 0 );

    tolerance $got, $want, $tolerance,
	'Next new Moon after February 1 1977 00:00:00 dynamical',
	\&format_time;

    $got = $moon->dynamical( $time )->next_quarter_hash( 0 );

    tolerance $got->{time}, $want, $tolerance,
	'Hash of next new Moon after February 1 1977 00:00:00 dynamical',
	\&format_time;
}


# Singleton object

{
    local $Astro::Coord::ECI::Moon::Singleton = 1;

    my @moon = map { Astro::Coord::ECI::Moon->new() } ( 0, 1 );

    cmp_ok $moon[0], '==', $moon[1],
    'Get same object from different calls to new() with $Singleton true';
}

{
    local $Astro::Coord::ECI::Moon::Singleton = 0;

    my @moon = map { Astro::Coord::ECI::Moon->new() } ( 0, 1 );

    cmp_ok $moon[0], '!=', $moon[1],
    'Get different objects from different calls to new() with $Singleton false';
}

SKIP: {

    note 'Almanac computed for an explicit location';

    my $sta = Astro::Coord::ECI->new(
	name => 'Washington, DC'
    )->geodetic(
	deg2rad(38.9),	# Position according to
	deg2rad(-77.0),	# U. S. Naval Observatory's
	0,		# http://aa.usno.navy.mil/data/docs/RS_OneDay.php
    );
    my $moon = Astro::Coord::ECI::Moon->new();
    my $time = time_gm( 0, 0, 5, 1, 0, 2008 );	# Jan 1, 2008 in TZ -5

    my @events = $moon->universal( $time )->almanac( $sta );

    cmp_ok scalar @events, '==', 3,
	'Almanac method returned three events';

    @events
	or skip 'No events found', 12;

    is $events[0][1], 'horizon', 'First event is horizon crossing';

    cmp_ok $events[0][2], '==', 1, 'First event is Moon rise';

    is $events[0][3], 'Moon rise', q{First event description is 'Moon rise'};

    tolerance $events[0][0], time_gm( 0, 15,  6, 1, 0, 2008 ), 60,
	'Moon rise occurred at January 1 2008 6:15:00 GMT',
	\&format_time;

    @events > 1
	or skip 'Only one event found', 8;

    is $events[1][1], 'transit', 'Second event is meridian crossing';

    cmp_ok $events[1][2], '==', 1, 'Second event is Moon culmination';

    is $events[1][3], 'Moon transits meridian',
	q{Second event description is 'Moon transits meridian'};

    tolerance $events[1][0], time_gm( 0, 46, 11, 1, 0, 2008 ), 60,
	'Moon culmination occurred at January 1 2008 11:46:00 GMT',
	\&format_time;

    @events > 2
	or skip 'Only two events found', 4;

    is $events[2][1], 'horizon', 'Third event is horizon crossing';

    cmp_ok $events[2][2], '==', 0, 'Third event is Moon set';

    is $events[2][3], 'Moon set', q{Third event description is 'Moon set'};

    tolerance $events[2][0], time_gm( 0, 8,  17, 1, 0, 2008 ), 60,
	'Moon set occurred at January 1 2008 17:08:00 GMT',
	\&format_time;
}

SKIP: {

    note 'Almanac computed for the location in the station attribute';

    my $sta = Astro::Coord::ECI->new(
	name => 'Washington, DC'
    )->geodetic(
	deg2rad(38.9),	# Position according to
	deg2rad(-77.0),	# U. S. Naval Observatory's
	0,		# http://aa.usno.navy.mil/data/docs/RS_OneDay.php
    );
    my $moon = Astro::Coord::ECI::Moon->new( station => $sta );
    my $time = time_gm( 0, 0, 5, 1, 0, 2008 );	# Jan 1, 2008 in TZ -5

    my @events = $moon->universal( $time )->almanac();

    cmp_ok scalar @events, '==', 3,
	'Almanac method returned three events';

    @events
	or skip 'No events found', 12;

    is $events[0][1], 'horizon', 'First event is horizon crossing';

    cmp_ok $events[0][2], '==', 1, 'First event is Moon rise';

    is $events[0][3], 'Moon rise', q{First event description is 'Moon rise'};

    tolerance $events[0][0], time_gm( 0, 15,  6, 1, 0, 2008 ), 60,
	'Moon rise occurred at January 1 2008 6:15:00 GMT',
	\&format_time;

    @events > 1
	or skip 'Only one event found', 8;

    is $events[1][1], 'transit', 'Second event is meridian crossing';

    cmp_ok $events[1][2], '==', 1, 'Second event is Moon culmination';

    is $events[1][3], 'Moon transits meridian',
	q{Second event description is 'Moon transits meridian'};

    tolerance $events[1][0], time_gm( 0, 46, 11, 1, 0, 2008 ), 60,
	'Moon culmination occurred at January 1 2008 11:46:00 GMT',
	\&format_time;

    @events > 2
	or skip 'Only two events found', 4;

    is $events[2][1], 'horizon', 'Third event is horizon crossing';

    cmp_ok $events[2][2], '==', 0, 'Third event is Moon set';

    is $events[2][3], 'Moon set', q{Third event description is 'Moon set'};

    tolerance $events[2][0], time_gm( 0, 8,  17, 1, 0, 2008 ), 60,
	'Moon set occurred at January 1 2008 17:08:00 GMT',
	\&format_time;
}

SKIP: {
    my $sta = Astro::Coord::ECI->new(
	name => 'Washington, DC'
    )->geodetic(
	deg2rad(38.9),	# Position according to
	deg2rad(-77.0),	# U. S. Naval Observatory's
	0,		# http://aa.usno.navy.mil/data/docs/RS_OneDay.php
    );
    my $moon = Astro::Coord::ECI::Moon->new();
    my $time = time_gm( 0, 0, 5, 1, 0, 2008 );	# Jan 1, 2008 in TZ -5

    my @events = $moon->universal( $time )->almanac_hash( $sta );

    cmp_ok scalar @events, '==', 3,
	'Almanac_hash method returned three events';

    @events
	or skip 'No events found', 12;

    is $events[0]{almanac}{event}, 'horizon',
	'First event is horizon crossing';

    cmp_ok $events[0]{almanac}{detail}, '==', 1,
	'First event is Moon rise';

    is $events[0]{almanac}{description}, 'Moon rise',
	q{First event description is 'Moon rise'};

    tolerance $events[0]{time}, time_gm( 0, 15,  6, 1, 0, 2008 ), 60,
	'Moon rise occurred at January 1 2008 6:15:00 GMT',
	\&format_time;

    @events > 1
	or skip 'Only one event found', 8;

    is $events[1]{almanac}{event}, 'transit',
	'Second event is meridian crossing';

    cmp_ok $events[1]{almanac}{detail}, '==', 1,
	'Second event is Moon culmination';

    is $events[1]{almanac}{description}, 'Moon transits meridian',
	q{Second event description is 'Moon transits meridian'};

    tolerance $events[1]{time}, time_gm( 0, 46, 11, 1, 0, 2008 ), 60,
	'Moon culmination occurred at January 1 2008 11:46:00 GMT',
	\&format_time;

    @events > 2
	or skip 'Only two events found', 4;

    is $events[2]{almanac}{event}, 'horizon',
	'Third event is horizon crossing';

    cmp_ok $events[2]{almanac}{detail}, '==', 0,
	'Third event is Moon set';

    is $events[2]{almanac}{description}, 'Moon set',
	q{Third event description is 'Moon set'};

    tolerance $events[2]{time}, time_gm( 0, 8,  17, 1, 0, 2008 ), 60,
	'Moon set occurred at January 1 2008 17:08:00 GMT',
	\&format_time;
}

done_testing;

1;

# ex: set textwidth=72 :
