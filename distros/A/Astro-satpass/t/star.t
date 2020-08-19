package main;

use strict;
use warnings;

use lib qw{ inc };

use Astro::Coord::ECI;
use Astro::Coord::ECI::Star;
use Astro::Coord::ECI::Utils qw{ :greg_time deg2rad PI };
use My::Module::Test qw{ tolerance };
use POSIX qw{strftime floor};
use Test::More 0.88;

use constant LIGHTYEAR2KILOMETER => 9.4607e12;
use constant SECSPERYEAR => 365.25 * 86400;

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

done_testing;

1;

# ex: set filetype=perl textwidth=72 :
