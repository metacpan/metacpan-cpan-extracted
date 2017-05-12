package main;

use strict;
use warnings;

use lib qw{ inc };

use Astro::Coord::ECI;
use Astro::Coord::ECI::Sun;
use Astro::Coord::ECI::Utils qw{ :time deg2rad };
use My::Module::Test qw{ :tolerance format_time };
use Test::More 0.88;

use constant EQUATORIALRADIUS => 6378.14;	# Meeus page 82.
use constant ASTRONOMICAL_UNIT => 149_597_870; # Meeus, Appendix 1, pg 407


# Sun position in ecliptic latitude/longitude
# Tests: ::Sun->time_set() (and ecliptic())

# This test is based on Meeus' example 25.a.

# Note that we're not too picky about the position of the sun, since
# it's an extended object. One part in a thousand is less than half its
# disk.

{
    my $time = time_gm( 0, 0, 0, 13, 9, 1992 );
    my $sun = Astro::Coord::ECI::Sun->dynamical( $time );

##  my ( $lat, $long, $rho ) = $sun->ecliptic();
    my ( undef, $long, $rho ) = $sun->ecliptic();

    tolerance_frac $long, deg2rad( 199.90895 ), 1e-5,
    'Ecliptic longitude of the Sun October 13 1992 00:00:00 dynamical';

    tolerance_frac $rho, .99766 * ASTRONOMICAL_UNIT, 1e-5,
    'Distance (AU) to the Sun October 13 1992 00:00:00 dynamical';

    tolerance_frac $sun->geometric_longitude(), deg2rad( 199.90988 ), 1e-5,
    'Geometric longitude of the Sun October 13 1992 00:00:00 dynamical';
}

# Sunrise, noon, and sunset
# Tests: next_meridian (), next_elevation ()

# This test is based on data for Washington, DC provided by the U.S.
# Naval Observatory, available from http://aa.usno.navy.mil/ The dates
# are the equinoxes and solstices for 2005 (same source), and the
# location is Washington, DC (same source). Note that times are computed
# in U.T. and then hand-converted to zone -5. We don't simply use
# localtime() since we don't know that the test script is being run in
# zone -5. This kind of argues for the use of DateTime, but I don't
# understand their leap-second code well enough yet.

{
    note 'Test with Sun passed as argument to next_elevation()';

    my $sta = Astro::Coord::ECI->new( refraction => 1 )->
	geodetic( deg2rad( 53/60 + 38 ), deg2rad( -(2/60 + 77) ), 0 );
    my $sun = Astro::Coord::ECI::Sun->new ();
    my $zone = -5 * 3600;

    my $time = time_gm( 0, 0, 0, 20, 2, 2005 ) - $zone;
    $sta->universal( $time );

    tolerance $sta->next_elevation( $sun, 0, 1 ) + $zone,
	time_gm( 0, 11, 6, 20, 2, 2005 ), 30,
	'Sunrise Washington DC March 11 2005', \&format_time;

    tolerance $sta->next_meridian( $sun ) + $zone,
	time_gm( 0, 16, 12, 20, 2, 2005 ), 30,
	'Local noon Washington DC March 11 2005', \&format_time;

    tolerance $sta->next_elevation( $sun, 0, 1 ) + $zone,
	time_gm( 0, 20, 18, 20, 2, 2005 ), 30,
	'Sunset Washington DC March 11 2005', \&format_time;

    $time = time_gm( 0, 0, 0, 21, 5, 2005 ) - $zone;
    $sta->universal( $time );

    tolerance $sta->next_elevation( $sun, 0, 1 ) + $zone,
	time_gm( 0, 43, 4, 21, 5, 2005 ), 30,
	'Sunrise Washington DC June 21 2005', \&format_time;

    tolerance $sta->next_meridian( $sun ) + $zone,
	time_gm( 0, 10, 12, 21, 5, 2005 ), 30,
	'Local noon Washington DC June 21 2005', \&format_time;

    tolerance $sta->next_elevation( $sun, 0, 1 ) + $zone,
	time_gm( 0, 37, 19, 21, 5, 2005 ), 30,
	'Sunset Washington DC June 21 2005', \&format_time;

    $time = time_gm( 0, 0, 0, 22, 8, 2005 ) - $zone;
    $sta->universal( $time );

    tolerance $sta->next_elevation( $sun, 0, 1 ) + $zone,
	time_gm( 0, 56, 5, 22, 8, 2005 ), 30,
	'Sunrise Washington DC September 22 2005', \&format_time;

    tolerance $sta->next_meridian( $sun ) + $zone,
	time_gm( 0, 1, 12, 22, 8, 2005 ), 30,
	'Local noon Washington DC September 22 2005', \&format_time;

    tolerance $sta->next_elevation( $sun, 0, 1 ) + $zone,
	time_gm( 0, 5, 18, 22, 8, 2005 ), 30,
	'Sunset Washington DC September 22 2005', \&format_time;

    $time = time_gm( 0, 0, 0, 21, 11, 2005 ) - $zone;
    $sta->universal( $time );

    tolerance $sta->next_elevation( $sun, 0, 1 ) + $zone,
	time_gm( 0, 23, 7, 21, 11, 2005 ), 30,
	'Sunrise Washington DC December 21 2005', \&format_time;

    tolerance $sta->next_meridian( $sun ) + $zone,
	time_gm( 0, 6, 12, 21, 11, 2005 ), 30,
	'Local noon Washington DC December 21 2005', \&format_time;

    tolerance $sta->next_elevation( $sun, 0, 1 ) + $zone,
	time_gm( 0, 50, 16, 21, 11, 2005 ), 30,
	'Sunset Washington DC December 21 2005', \&format_time;
}

{
    note 'Test with location in station attribute of Sun';

    my $sta = Astro::Coord::ECI->new( refraction => 1 )->
	geodetic( deg2rad( 53/60 + 38 ), deg2rad( -(2/60 + 77) ), 0 );
    my $sun = Astro::Coord::ECI::Sun->new( station => $sta );
    my $zone = -5 * 3600;

    my $time = time_gm( 0, 0, 0, 20, 2, 2005 ) - $zone;
    $sun->universal( $time );

    tolerance $sun->next_elevation( 0, 1 ) + $zone,
	time_gm( 0, 11, 6, 20, 2, 2005 ), 30,
	'Sunrise Washington DC March 11 2005', \&format_time;

    tolerance $sun->next_meridian() + $zone,
	time_gm( 0, 16, 12, 20, 2, 2005 ), 30,
	'Local noon Washington DC March 11 2005', \&format_time;

    tolerance $sun->next_elevation( 0, 1 ) + $zone,
	time_gm( 0, 20, 18, 20, 2, 2005 ), 30,
	'Sunset Washington DC March 11 2005', \&format_time;

    $time = time_gm( 0, 0, 0, 21, 5, 2005 ) - $zone;
    $sun->universal( $time );

    tolerance $sun->next_elevation( 0, 1 ) + $zone,
	time_gm( 0, 43, 4, 21, 5, 2005 ), 30,
	'Sunrise Washington DC June 21 2005', \&format_time;

    tolerance $sun->next_meridian() + $zone,
	time_gm( 0, 10, 12, 21, 5, 2005 ), 30,
	'Local noon Washington DC June 21 2005', \&format_time;

    tolerance $sun->next_elevation( 0, 1 ) + $zone,
	time_gm( 0, 37, 19, 21, 5, 2005 ), 30,
	'Sunset Washington DC June 21 2005', \&format_time;

    $time = time_gm( 0, 0, 0, 22, 8, 2005 ) - $zone;
    $sun->universal( $time );

    tolerance $sun->next_elevation( 0, 1 ) + $zone,
	time_gm( 0, 56, 5, 22, 8, 2005 ), 30,
	'Sunrise Washington DC September 22 2005', \&format_time;

    tolerance $sun->next_meridian() + $zone,
	time_gm( 0, 1, 12, 22, 8, 2005 ), 30,
	'Local noon Washington DC September 22 2005', \&format_time;

    tolerance $sun->next_elevation( 0, 1 ) + $zone,
	time_gm( 0, 5, 18, 22, 8, 2005 ), 30,
	'Sunset Washington DC September 22 2005', \&format_time;

    $time = time_gm( 0, 0, 0, 21, 11, 2005 ) - $zone;
    $sun->universal( $time );

    tolerance $sun->next_elevation( 0, 1 ) + $zone,
	time_gm( 0, 23, 7, 21, 11, 2005 ), 30,
	'Sunrise Washington DC December 21 2005', \&format_time;

    tolerance $sun->next_meridian() + $zone,
	time_gm( 0, 6, 12, 21, 11, 2005 ), 30,
	'Local noon Washington DC December 21 2005', \&format_time;

    tolerance $sun->next_elevation( 0, 1 ) + $zone,
	time_gm( 0, 50, 16, 21, 11, 2005 ), 30,
	'Sunset Washington DC December 21 2005', \&format_time;
}


# Equinoxes and Solstices for 2005
# Tests: next_quarter_hash() (and implicitly next_quarter())

# This test is based on Meeus' table 27.E on page 182. The accuracy is a
# fairly poor 16 minutes 40 seconds, because our  position of the Sun is
# only good to 0.01 degrees.

{
    my $time = time_gm( 0, 0, 0, 1, 0, 2005 );
    my $sun = Astro::Coord::ECI::Sun->universal( $time );
    my $tolerance = 16 * 60 + 40;

    my $hash = $sun->next_quarter_hash();
    tolerance $sun->dynamical(), time_gm( 29, 34, 12, 20, 2, 2005 ),
	$tolerance, "$hash->{almanac}{description} 2005", \&format_dyn;

    $hash = $sun->next_quarter_hash();
    tolerance $sun->dynamical(), time_gm( 12, 47, 6, 21, 5, 2005 ),
	$tolerance, "$hash->{almanac}{description} 2005", \&format_dyn;

    $hash = $sun->next_quarter_hash();
    tolerance $sun->dynamical(), time_gm( 14, 24, 22, 22, 8, 2005 ),
	$tolerance, "$hash->{almanac}{description} 2005", \&format_dyn;

    $hash = $sun->next_quarter_hash();
    tolerance $sun->dynamical(), time_gm( 1, 36, 18, 21, 11, 2005 ),
	$tolerance, "$hash->{almanac}{description} 2005", \&format_dyn;
}


# Singleton object

{
    local $Astro::Coord::ECI::Sun::Singleton = 1;

    my @sun = map { Astro::Coord::ECI::Sun->new() } ( 0, 1 );

    cmp_ok $sun[0], '==', $sun[1],
    'Get same object from different calls to new() with $Singleton true';
}

{
    local $Astro::Coord::ECI::Sun::Singleton = 0;

    my @sun = map { Astro::Coord::ECI::Sun->new() } ( 0, 1 );

    cmp_ok $sun[0], '!=', $sun[1],
    'Get different objects from different calls to new() with $Singleton false';
}

# almanac_hash() (and implicitly almanac())
# testing against data from the U. S. Naval Observatory

SKIP: {

    note 'almanac_hash() with explicit station';

    my $sta = Astro::Coord::ECI->new(
	name => 'Washington, DC'
    )->geodetic(
	deg2rad(38.9),	# Position according to
	deg2rad(-77.0),	# U. S. Naval Observatory's
	0,		# http://aa.usno.navy.mil/data/docs/RS_OneDay.php
    );
    my $sun = Astro::Coord::ECI::Sun->new();
    my $time = time_gm( 0, 0, 5, 1, 0, 2008 );	# Jan 1, 2008 in TZ -5

    my @almanac = $sun->universal( $time )->almanac_hash( $sta );

    cmp_ok scalar @almanac, '==', 6,
    'Got six Sun events for January 1 2008, Washington DC';

    @almanac
	or skip 'No events returned', 23;

    is $almanac[0]{almanac}{event}, 'transit',
	'First event is transit';

    cmp_ok $almanac[0]{almanac}{detail}, '==', 0,
	'First event is local midnight';

    is $almanac[0]{almanac}{description}, 'local midnight',
	q{First event description is 'local midnight'};

    note <<'EOD';
The Naval Observatory does not provide a time for local midnight.
EOD

    @almanac > 1
	or skip 'Only 1 event returned', 20;

    is $almanac[1]{almanac}{event}, 'twilight',
	'Second event is twilight';

    cmp_ok $almanac[1]{almanac}{detail}, '==', 1,
	'Second event is beginning of twilight';

    is $almanac[1]{almanac}{description}, 'begin twilight',
	q{Second event description is 'begin twilight'};

    tolerance $almanac[1]{time}, time_gm( 0, 57, 11, 1, 0, 2008 ), 60,
	'Time twilight begins', \&format_gmt;

    @almanac > 2
	or skip 'Only 2 events returned', 16;

    is $almanac[2]{almanac}{event}, 'horizon',
	'Third event is horizon';

    cmp_ok $almanac[2]{almanac}{detail}, '==', 1,
	'Third event is Sunrise';

    is $almanac[2]{almanac}{description}, 'Sunrise',
	q{Third event description is 'Sunrise'};

    tolerance $almanac[2]{time}, time_gm( 0, 27, 12, 1, 0, 2008 ), 60,
	'Time of Sunrise', \&format_gmt;

    @almanac > 3
	or skip 'Only 3 events returned', 12;

    is $almanac[3]{almanac}{event}, 'transit',
	'Fourth event is transit';

    cmp_ok $almanac[3]{almanac}{detail}, '==', 1,
	'Fourth event is local noon';

    is $almanac[3]{almanac}{description}, 'local noon',
	q{Fourth event description is 'local noon'};

    tolerance $almanac[3]{time}, time_gm( 0, 12, 17, 1, 0, 2008 ), 60,
	'Time of local noon', \&format_gmt;

    @almanac > 4
	or skip 'Only 4 events returned', 8;

    is $almanac[4]{almanac}{event}, 'horizon',
	'Fifth event is horizon';

    cmp_ok $almanac[4]{almanac}{detail}, '==', 0,
	'Fifth event is Sunset';

    is $almanac[4]{almanac}{description}, 'Sunset',
	q{Fifth event description is 'Sunset'};

    tolerance $almanac[4]{time}, time_gm( 0, 56, 21, 1, 0, 2008 ), 60,
	'Time of Sunset', \&format_gmt;

    @almanac > 5
	or skip 'Only 5 events returned', 4;

    is $almanac[5]{almanac}{event}, 'twilight',
	'Sixth event is twilight';

    cmp_ok $almanac[5]{almanac}{detail}, '==', 0,
	'Sixth event is end of twilight';

    is $almanac[5]{almanac}{description}, 'end twilight',
	q{Sixth event description is 'end twilight'};

    tolerance $almanac[5]{time}, time_gm( 0, 26, 22, 1, 0, 2008 ), 60,
	'Time twilight ends', \&format_gmt;
}

SKIP: {

    note 'almanac_hash() with location from station attribute';

    my $sta = Astro::Coord::ECI->new(
	name => 'Washington, DC'
    )->geodetic(
	deg2rad(38.9),	# Position according to
	deg2rad(-77.0),	# U. S. Naval Observatory's
	0,		# http://aa.usno.navy.mil/data/docs/RS_OneDay.php
    );
    my $sun = Astro::Coord::ECI::Sun->new( station => $sta );
    my $time = time_gm( 0, 0, 5, 1, 0, 2008 );	# Jan 1, 2008 in TZ -5

    my @almanac = $sun->universal( $time )->almanac_hash();

    cmp_ok scalar @almanac, '==', 6,
    'Got six Sun events for January 1 2008, Washington DC';

    @almanac
	or skip 'No events returned', 23;

    is $almanac[0]{almanac}{event}, 'transit',
	'First event is transit';

    cmp_ok $almanac[0]{almanac}{detail}, '==', 0,
	'First event is local midnight';

    is $almanac[0]{almanac}{description}, 'local midnight',
	q{First event description is 'local midnight'};

    note <<'EOD';
The Noval Observatory does not provide a time for local midnight.
EOD

    @almanac > 1
	or skip 'Only 1 event returned', 20;

    is $almanac[1]{almanac}{event}, 'twilight',
	'Second event is twilight';

    cmp_ok $almanac[1]{almanac}{detail}, '==', 1,
	'Second event is beginning of twilight';

    is $almanac[1]{almanac}{description}, 'begin twilight',
	q{Second event description is 'begin twilight'};

    tolerance $almanac[1]{time}, time_gm( 0, 57, 11, 1, 0, 2008 ), 60,
	'Time twilight begins', \&format_gmt;

    @almanac > 2
	or skip 'Only 2 events returned', 16;

    is $almanac[2]{almanac}{event}, 'horizon',
	'Third event is horizon';

    cmp_ok $almanac[2]{almanac}{detail}, '==', 1,
	'Third event is Sunrise';

    is $almanac[2]{almanac}{description}, 'Sunrise',
	q{Third event description is 'Sunrise'};

    tolerance $almanac[2]{time}, time_gm( 0, 27, 12, 1, 0, 2008 ), 60,
	'Time of Sunrise', \&format_gmt;

    @almanac > 3
	or skip 'Only 3 events returned', 12;

    is $almanac[3]{almanac}{event}, 'transit',
	'Fourth event is transit';

    cmp_ok $almanac[3]{almanac}{detail}, '==', 1,
	'Fourth event is local noon';

    is $almanac[3]{almanac}{description}, 'local noon',
	q{Fourth event description is 'local noon'};

    tolerance $almanac[3]{time}, time_gm( 0, 12, 17, 1, 0, 2008 ), 60,
	'Time of local noon', \&format_gmt;

    @almanac > 4
	or skip 'Only 4 events returned', 8;

    is $almanac[4]{almanac}{event}, 'horizon',
	'Fifth event is horizon';

    cmp_ok $almanac[4]{almanac}{detail}, '==', 0,
	'Fifth event is Sunset';

    is $almanac[4]{almanac}{description}, 'Sunset',
	q{Fifth event description is 'Sunset'};

    tolerance $almanac[4]{time}, time_gm( 0, 56, 21, 1, 0, 2008 ), 60,
	'Time of Sunset', \&format_gmt;

    @almanac > 5
	or skip 'Only 5 events returned', 4;

    is $almanac[5]{almanac}{event}, 'twilight',
	'Sixth event is twilight';

    cmp_ok $almanac[5]{almanac}{detail}, '==', 0,
	'Sixth event is end of twilight';

    is $almanac[5]{almanac}{description}, 'end twilight',
	q{Sixth event description is 'end twilight'};

    tolerance $almanac[5]{time}, time_gm( 0, 26, 22, 1, 0, 2008 ), 60,
	'Time twilight ends', \&format_gmt;
}

done_testing;

sub format_dyn {
    my ( $time ) = @_;
    return format_time( $time ) . ' dynamical';
}

sub format_gmt {
    my ( $time ) = @_;
    return format_time( $time ) . ' GMT';
}

1;

# ex: set textwidth=72 :
