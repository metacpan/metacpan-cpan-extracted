package main;

use strict;
use warnings;

use lib qw{ inc };

use Astro::Coord::ECI;
use Astro::Coord::ECI::Star;
use Astro::Coord::ECI::Utils qw{ :greg_time deg2rad PI };
use My::Module::Test qw{ tolerance format_time };
use Test::More 0.88;

use constant LIGHTYEAR2KILOMETER => 9.4607e12;
use constant SECSPERYEAR => 365.25 * 86400;

{

    #	Tests 1 - 2: Position of star at given time.

    #	This test is based on Meeus' 21.b and 23.a

    my $star = Astro::Coord::ECI::Star->new (name => 'Theta Persei')->
	position (
	    deg2rad (41.0499416666667), 	# right ascension - radians
	    deg2rad (49.2284666666667),	# declination - radians
	    36.64 * LIGHTYEAR2KILOMETER,	# range - kilometers
	    .03425 / 3600 / 12 * PI / SECSPERYEAR,	# motion in r.a. - radians/sec
	    -.0895 / 3600 / 180 * PI / SECSPERYEAR,	# motion in decl - radians/sec
	    0,					# recession vel - km/sec
	    );
    my $time = greg_time_gm( 0, 0, 12, 13, 10, 2028 ) + .19 * 86400;
    my ( $alpha, $delta ) = $star->dynamical( $time )->equatorial();

    my $tolerance = 2e-5;
    note <<'EOD';

In the following the tolerance is in radians. This seems a little large,
amounting to 4 seconds of arc. It's difficult to check in detail, since
I went through ecliptic coordinates and Meeus' example is in equatorial
coordinates.

EOD

    tolerance( $alpha, ( ( 14.390 / 60 + 46 ) / 60 + 2 ) / 12 * PI, $tolerance,
	'Right ascension of Theta Persei 2028 Nov 13.19' );

    tolerance( $delta, deg2rad ( ( 7.45 / 60 + 21 ) / 60 + 49 ), $tolerance,
	'Declination of Theta Persei 2028 Nov 13.19' );

}

SKIP: {

    note 'Almanac computed for Aldebaran. Times per U. S. Naval Observatory';

    my $sta = Astro::Coord::ECI->new(
	name => 'Washington, DC'
    )->geodetic(
	deg2rad(38.9),	# Position according to
	deg2rad(-77.0),	# U. S. Naval Observatory's
	0,		# http://aa.usno.navy.mil/data/docs/RS_OneDay.php
    );
    my $star = Astro::Coord::ECI::Star->new(
	name	=> 'Aldebaran',
    )->position(
	deg2rad( 68.98016279 ), 	# right ascension - radians
	deg2rad( 16.50930235 ),		# declination - radians
	20.43 * LIGHTYEAR2KILOMETER,	# range - kilometers
    );

    my $time = greg_time_gm( 0, 0, 4, 10, 8, 2025 );	# Sep 10, 2025 in TZ -4

    my @events = $star->universal( $time )->almanac( $sta );

    cmp_ok scalar @events, '==', 3,
	'Almanac method returned three events';

    @events
	or skip 'No events found', 12;

    is $events[0][1], 'transit', 'First event is meridian crossing';

    cmp_ok $events[0][2], '==', 1, 'First event is culmination';

    is $events[0][3], 'Aldebaran transits meridian', q{First event description is 'Aldebaran transits meridian'};

    tolerance( $events[0][0], greg_time_gm( 0, 27, 10, 10, 8, 2025 ), 60,
	'Aldebaran culmination occurred at September 10 2025 10:27:00 GMT',
	\&format_time );

    @events > 1
	or skip 'Only one event found', 8;

    is $events[1][1], 'horizon', 'Second event is horizon crossing';

    cmp_ok $events[1][2], '==', 0, 'Second event is set';

    is $events[1][3], 'Aldebaran sets',
	q{Second event description is 'Aldebaran sets'};

    tolerance( $events[1][0], greg_time_gm( 0, 24, 17, 10, 8, 2025 ), 60,
	'Aldebaran set occurred at September 10 2025 17:24:00 GMT',
	\&format_time );

    @events > 2
	or skip 'Only two events found', 4;

    is $events[2][1], 'horizon', 'Third event is horizon crossing';

    cmp_ok $events[2][2], '==', 1, 'Third event is Aldebaran rise';

    is $events[2][3], 'Aldebaran rises',
	q{Third event description is 'Aldebaran rises'};

    tolerance( $events[2][0], greg_time_gm( 0, 25,  3, 11, 8, 2025 ), 60,
	'Moon set occurred at September 11 2025 03:25:00 GMT',
	\&format_time );
}

SKIP: {

    note 'Almanac computed for Polaris. Times per U. S. Naval Observatory';

    my $sta = Astro::Coord::ECI->new(
	name => 'Washington, DC'
    )->geodetic(
	deg2rad(38.9),	# Position according to
	deg2rad(-77.0),	# U. S. Naval Observatory's
	0,		# http://aa.usno.navy.mil/data/docs/RS_OneDay.php
    );
    my $star = Astro::Coord::ECI::Star->new(
	name	=> 'Polaris',
    )->position(
	deg2rad( 37.95456067 ), 	# right ascension - radians
	deg2rad( 89.26410897 ),		# declination - radians
	132.63 * LIGHTYEAR2KILOMETER,	# range - kilometers
    );

    my $time = greg_time_gm( 0, 0, 4, 10, 8, 2025 );	# Sep 10, 2025 in TZ -4

    my @events = $star->universal( $time )->almanac( $sta );

    cmp_ok scalar @events, '==', 1,
	'Almanac method returned one event';

    @events
	or skip 'No events found', 4;

    is $events[0][1], 'transit', 'First event is meridian crossing';

    cmp_ok $events[0][2], '==', 1, 'First event is culmination';

    is $events[0][3], 'Polaris transits meridian',
	q{First event description is 'Polaris transits meridian'};

    tolerance( $events[0][0], greg_time_gm( 0, 55,  8, 10, 8, 2025 ), 60,
	'Polaris culmination occurred at September 10 2025 08:55:00 GMT',
	\&format_time );
}

done_testing;

1;

# ex: set filetype=perl textwidth=72 :
