package main;

use strict;
use warnings;

use lib qw{ inc };

use Astro::Coord::ECI;
use Astro::Coord::ECI::Utils qw{ :time deg2rad PERL2000 PI rad2deg };
use My::Module::Test qw{ :tolerance velocity_sanity };
use POSIX qw{strftime floor};
use Test::More 0.88;
use Time::Local;

use constant CLASS	=> 'Astro::Coord::ECI';
use constant EQUATORIALRADIUS => 6378.14;	# Meeus page 82.
use constant TIMFMT => '%d-%b-%Y %H:%M:%S';

Astro::Coord::ECI->set (debug => 0);

{
    local $@ = undef;
    my $eci;
    eval {
	$eci = Astro::Coord::ECI->new();
	pass 'Can instantiate a default object';
	1;
    } or BAIL_OUT 'Can not instantiate a default object';

    eval {
	$eci->get( 'sun' );
	pass q<Can get the default 'sun' attribute>;
	1;
    } or BAIL_OUT q<Can not get the default 'sun' attribute>;
}

# universal time
# Tests: universal()

# We just make sure we get the same thing back.

{
    my $want = time_gm( 0, 0, 0, 1, 0, 2000 );
    my $got = Astro::Coord::ECI->universal( $want )->universal();

    cmp_ok $got, '==', $want,
	'Univeral time round trip: Jan 1 2000';

    $want = time_gm( 0, 0, 0, 1, 0, 2005 );
    $got = Astro::Coord::ECI->universal( $want )->universal();

    cmp_ok $got, '==', $want,
	'Univeral time round trip: Jan 1 2005';
}


# universal time -> dynamical time
# Tests: dynamical()

{
    my $univ = time_gm( 0, 0, 0, 1, 0, 2000 );
    my $dyn = floor(
	Astro::Coord::ECI->universal( $univ )->dynamical + .5 );

    cmp_ok $dyn, '==', $univ + 65,
	'Universal to dynamical time: Jan 1 2000';

    $univ = time_gm( 0, 0, 0, 1, 0, 2005 );
    $dyn = floor(
	Astro::Coord::ECI->universal( $univ )->dynamical + .5 );

    cmp_ok $dyn, '==', $univ + 72,
	'Universal to dynamical time: Jan 1 2005';
}


# dynamical time -> universal time
# tests: dynamical()

{
    my $dyn = time_gm( 0, 0, 0, 1, 0, 2000 );
    my $univ = floor(
	Astro::Coord::ECI->dynamical( $dyn
	)->universal() + .5 );

    cmp_ok $univ, '==', $dyn - 65,
	'Dynamical to universal time: Jan 1 2000 dynamical';

    $dyn = time_gm( 0, 0, 0, 1, 0, 2005 );
    $univ = floor(
	Astro::Coord::ECI->dynamical( $dyn
	)->universal() + .5 );

    cmp_ok $univ, '==', $dyn - 72,
	'Dynamical to universal time: Jan 1 2005 dynamical';
}


# ecef
# Tests: ecef()

# All we do here is be sure we get back what we put in.

{
    my ( $X, $Y, $Z ) = Astro::Coord::ECI->ecef( 3000, 4000, 5000 )->ecef();

    cmp_ok $X, '==', 3000, 'ECEF round-trip: X';

    cmp_ok $Y, '==', 4000, 'ECEF round-trip: Y';

    cmp_ok $Z, '==', 5000, 'ECEF round-trip: Z';
}


# geodetic -> geocentric
# Tests: geodetic()

# Meeus, page 82, example 11a

# Both TopoZone and Google say the observatory is latitude 34 deg 13'33"
# N (=   degrees), longitude 118 deg 03'25" W (= -118.056944444444
# degrees).  The test uses Meeus' latitude of 33 deg 21'22" N (since
# that's what Meeus himself uses) but the TopoZone/Google value for
# longitude, since longitude does not affect the calculation, but my
# Procrustean validation expects it.

# We also test the antpodal (sort of) point, since finding a bug in my
# implementation of Borkowski's algorithm when running on a point in the
# southern hemisphere. No, this particular test doesn't use that
# algorithm, but once bitten, twice shy.

{
    my ( $phiprime, undef, $rho ) =
	Astro::Coord::ECI->new( ellipsoid => 'IAU76' )->
	geodetic( .58217396455, -2.060487233536, 1.706 )->geocentric();
    my $rhosinphiprime = $rho / EQUATORIALRADIUS * sin ($phiprime);
    my $rhocosphiprime = $rho / EQUATORIALRADIUS * cos ($phiprime);

    cmp_ok sprintf( '%.6f', $rhosinphiprime ), '==', .546861,
	'geodetic to geocentric: rho * sin( phiprime )';

    cmp_ok sprintf( '%.6f', $rhocosphiprime ), '==', .836339,
	'geodetic to geocentric: rho * cos( phiprime )';

    ( $phiprime, undef, $rho ) =
	Astro::Coord::ECI->new( ellipsoid => 'IAU76' )->
	geodetic( -.58217396455, 2.060487233536, 1.706 )->geocentric();
    $rhosinphiprime = $rho / EQUATORIALRADIUS * sin ($phiprime);
    $rhocosphiprime = $rho / EQUATORIALRADIUS * cos ($phiprime);

    cmp_ok sprintf( '%.6f', $rhosinphiprime ), '==', -.546861,
	'geodetic to geocentric: rho * sin( phiprime )';

    cmp_ok sprintf( '%.6f', $rhocosphiprime ), '==', .836339,
	'geodetic to geocentric: rho * cos( phiprime )';
}


# geocentric -> geodetic
# Tests: geodetic()

# Borkowski
# For this, we just invert Meeus' example.

# We also test the antpodal point, since finding a bug in my
# implementation of Borkowski's algorithm when running on a point in the
# southern hemisphere.

{
    my ( $lat, $long, $elev ) =
	Astro::Coord::ECI->new( ellipsoid => 'IAU76' )->
	geocentric(
	    0.579094339305825, -2.060487233536, 6373.41803380646,
	)->geodetic();

    tolerance_frac $lat, .58217396455, 1e-6,
	'Geocentric to geodetic: latitude';

    tolerance_frac $long, -2.060487233536, 1e-6,
	'Geocentric to geodetic: longitude';

    tolerance_frac $elev, 1.706, 1e-3,
	'Geocentric to geodetic: height above sea level';

#	[IAU76 => -0.579094339305825, 1.08110542005979, 6373.41803380646,
#		[-.58217396455, 1e-6], [1.08110542005979, 1e-6], [1.706, 1e-3]],
#	) {

    ( $lat, $long, $elev ) =
	Astro::Coord::ECI->new( ellipsoid => 'IAU76' )->
	geocentric(
	    -0.579094339305825, 1.08110542005979, 6373.41803380646,
	)->geodetic();

    tolerance_frac $lat, -.58217396455, 1e-6,
	'Geocentric to geodetic: latitude';

    tolerance_frac $long, 1.08110542005979, 1e-6,
	'Geocentric to geodetic: longitude';

    tolerance_frac $elev, 1.706, 1e-3,
	'Geocentric to geodetic: height above sea level';
}

# geodetic -> Earth-Centered, Earth-Fixed
# Tests: geocentric() (and geodetic())

# Continuing the above example, but ecef coordinates. Book answer from
# http://www.ngs.noaa.gov/cgi-bin/xyz_getxyz.prl is
#    x                y             z       Elipsoid
# -2508975.4549 -4707403.8939  3487953.2711 GRS80

note <<'EOD';

In the following twelve tests the tolerance is degraded because the book
solution is calculated using a different, and apparently simpler model
attributed to Escobal, "Methods of Orbit Determination", 1965, Wiley &
Sons, Inc., pp. 27-29.

EOD

{
    my ( $x, $y, $z ) =
	Astro::Coord::ECI->new( ellipsoid => 'GRS80' )->
	geodetic( .58217396455, -2.060487233536, 1.706 )->ecef();

    tolerance_frac $x, -2508.9754549, 1e-5,
	'Geodetic to ECEF: X';

    tolerance_frac $y, -4707.4038939, 1e-5,
	'Geodetic to ECEF: Y';

    tolerance_frac $z, 3487.9532711, 1e-5,
	'Geodetic to ECEF: Z';

    ( $x, $y, $z ) =
	Astro::Coord::ECI->new( ellipsoid => 'GRS80' )->
	geodetic( -.58217396455, 1.08110542005979, 1.706 )->ecef();

    tolerance_frac $x, 2508.9754549, 1e-5,
	'Geodetic to ECEF: X';

    tolerance_frac $y, 4707.4038939, 1e-5,
	'Geodetic to ECEF: Y';

    tolerance_frac $z, -3487.9532711, 1e-5,
	'Geodetic to ECEF: Z';
}


# Earth-Centered, Earth-Fixed -> geodetic
# Tests: geocentric() (and geodetic())

# Continuing the above example, but ecef coordinates. We use the book
# solution of the opposite test as our input, and vice versa.

{
    my ( $lat, $long, $elev ) =
	Astro::Coord::ECI->new( ellipsoid => 'GRS80' )->
	ecef( -2508.9754549, -4707.4038939, 3487.9532711 )->geodetic();

    tolerance_frac $lat, .58217396455, 1e-5,
	'ECEF to Geodetic: latitude';

    tolerance_frac $long, -2.060487233536, 1e-5,
	'ECEF to Geodetic: longitude';

    tolerance_frac $elev, 1.706, 1e-5,
	'ECEF to Geodetic: height above sea level';

    ( $lat, $long, $elev ) =
	Astro::Coord::ECI->new( ellipsoid => 'GRS80' )->
	ecef( 2508.9754549, 4707.4038939, -3487.9532711 )->geodetic();

    tolerance_frac $lat, -.58217396455, 1e-5,
	'ECEF to Geodetic: latitude';

    tolerance_frac $long, 1.08110542005979, 1e-5,
	'ECEF to Geodetic: longitude';

    tolerance_frac $elev, 1.706, 1e-5,
	'ECEF to Geodetic: height above sea level';
}


# geodetic -> eci
# Tests: eci() (and geodetic() and geocentric())

# Standard is from http://celestrak.com/columns/v02n03/ (Kelso)

{
    my $time = time_gm( 0, 0, 9, 1, 9, 1995 );

    my ( $x, $y, $z ) =
	Astro::Coord::ECI->new( ellipsoid => 'WGS72' )->
	geodetic( deg2rad( 40 ), deg2rad( -75 ), 0 )->eci( $time );

    tolerance_frac $x, 1703.295, 1e-6, 'Geodetic to ECI: X';

    tolerance_frac $y, 4586.650, 1e-6, 'Geodetic to ECI: Y';

    tolerance_frac $z, 4077.984, 1e-6, 'Geodetic to ECI: Z';

    $time = time_gm( 0, 0, 9, 1, 9, 1995 );

    ( $x, $y, $z ) =
	Astro::Coord::ECI->new( ellipsoid => 'WGS72' )->
	geodetic( deg2rad( -40 ), deg2rad( 105 ), 0 )->eci( $time );

    tolerance_frac $x, -1703.295, 1e-6, 'Geodetic to ECI: X';

    tolerance_frac $y, -4586.650, 1e-6, 'Geodetic to ECI: Y';

    tolerance_frac $z, -4077.984, 1e-6, 'Geodetic to ECI: Z';
}


# eci -> geodetic
# Tests: eci() (and geodetic() and geocentric())

# This is the reverse of the previous test.

{
    my $time = time_gm( 0, 0, 9, 1, 9, 1995 );

    my ( $lat, $long, $elev ) =
	Astro::Coord::ECI->new( ellipsoid => 'WGS72' )->
	eci( 1703.295, 4586.650, 4077.984, $time )->geodetic();

    tolerance_frac $lat, deg2rad( 40 ), 1e-6,
	'ECI to geodetic: latitude';

    tolerance_frac $long, deg2rad( -75 ), 1e-6,
	'ECI to geodetic: longitude';

    $elev += EQUATORIALRADIUS;
    tolerance_frac $elev, EQUATORIALRADIUS, 1e-6,
	'ECI to geodetic: distance from center';

    $time = time_gm( 0, 0, 9, 1, 9, 1995 );

    ( $lat, $long, $elev ) =
	Astro::Coord::ECI->new( ellipsoid => 'WGS72' )->
	eci( -1703.295, -4586.650, -4077.984, $time )->geodetic();

    tolerance_frac $lat, deg2rad( -40 ), 1e-6,
	'ECI to geodetic: latitude';

    tolerance_frac $long, deg2rad( 105 ), 1e-6,
	'ECI to geodetic: longitude';

    $elev += EQUATORIALRADIUS;
    tolerance_frac $elev, EQUATORIALRADIUS, 1e-6,
	'ECI to geodetic: distance from center';
}


# azel
# Tests: azel() (and geodetic(), geocentric(), and eci())

# Book solution from
# http://www.satcom.co.uk/article.asp?article=1

note <<'EOD';

In the following three tests the tolerance is degraded because the
book solution is calculated by http://www.satcom.co.uk/article.asp?article=1
which apparently assumes an exactly synchronous orbit. Their exact
altitude assumption is undocumented, as is their algorithm. So the
tests are really more of a sanity check.

EOD

{
    my $time = time_gm( 0, 0, 5, 27, 7, 2005 );
    my $sta = Astro::Coord::ECI->new( ellipsoid => 'GRS80' )->
	geodetic( deg2rad( 38 ), deg2rad( -80 ), 1 );
    my $sat = Astro::Coord::ECI->new( ellipsoid => 'GRS80' )->
	universal( $time )->
	geodetic( deg2rad( 0 ), deg2rad( -75 ), 35800 );

    my ( $azm, $elev, $rng ) = $sta->azel( $sat );

    tolerance_frac $azm, deg2rad( 171.906 ), 1e-3,
	'Azimuth for observer';

    tolerance_frac $elev, deg2rad( 45.682 ), 1e-3,
	'Elevation for observer';

    tolerance_frac $rng, 37355.457, 1e-3,
	'Range for observer';

    # Same as above tests, but with the station in the 'station'
    # attribute.

    $sat->set( station => $sta );

    ( $azm, $elev, $rng ) = $sat->azel();

    tolerance_frac $azm, deg2rad( 171.906 ), 1e-3,
	'Azimuth for observer';

    tolerance_frac $elev, deg2rad( 45.682 ), 1e-3,
	'Elevation for observer';

    tolerance_frac $rng, 37355.457, 1e-3,
	'Range for observer';

    # enu
    # Tests: enu()

    # From the azel() test above, converted as described at
    # http://geostarslib.sourceforge.net/main.html#conv

    my ( $East, $North, $Up ) = $sat->enu();

    tolerance $East, 3675, 10,
	'East for observer';

    tolerance $North, -25840, 10,
	'North for observer';

    tolerance $Up, 26746, 10,
	'Up for observer';
}

# atmospheric refraction.
# Tests: correct_for_refraction()

# Based on Meeus' Example 16.a.

{
    my $got = Astro::Coord::ECI->
	correct_for_refraction( deg2rad( .5541 ) );

    tolerance_frac $got, deg2rad( 57.864 / 60 ), 1e-4,
	'Correction for atmospheric refraction';
}


# Angle between two points as seen from a third.
# Tests: angle()

{
    my $A = Astro::Coord::ECI->ecef( 0, 0, 0 );
    my $B = Astro::Coord::ECI->ecef( 1, 0, 0 );
    my $C = Astro::Coord::ECI->ecef( 0, 1, 0 );

    my $got = $A->angle ($B, $C);

    tolerance $got, deg2rad( 90 ), 1e-6,
	'Angle between two points as seen from a third';
}

# Nutation
# Tests: nutation()

{
    my ( $delta_psi, $delta_epsilon ) = CLASS->nutation(
	timegm( 0, 0, 0, 10, 3, 87 ) );

    # Tolerance .5 seconds of arc
    tolerance $delta_psi, -1.8364e-5, .00001,
	'nutation in longitude: Midnight Nov 3 1987: Meeus ex 22.a';

    # Tolerance .1 seconds of arc
    tolerance $delta_epsilon, 4.5781e-5, .000001,
	'nutation in obliquity: Midnight Nov 3 1987: Meeus ex 22.a';
}

# Obliquity
# Tests: obliquity()

{
    my $epsilon = CLASS->obliquity(
	timegm( 0, 0, 0, 10, 3, 87 ) );

    tolerance $epsilon, 0.409167475225493, .00001,
	'obliquity: Midnight Nov 3 1987: Meeus ex 22.a';
}

# Equation of time
# Tests: equation_of_time

{
    my $got = CLASS->equation_of_time( timegm( 0, 0, 0, 13, 9, 92 ) );

    tolerance $got, 13 * 60 + 42.7, .1,
	'equation_of_time: Midnight Oct 13 1992: Meeus ex 28b';

}

# Precession of equinoxes.
# Tests: precess()

# Based on Meeus' example 21.b.

use constant LIGHTYEAR2KILOMETER => 9.4607e12;

{
    note q{Precession - no 'station' attribute};

    my $alpha0 = 41.054063;
    my $delta0 = 49.227750;
    my $rho = 36.64;
    my $t0 = PERL2000;
    my $alphae = deg2rad( 41.547214 );
    my $deltae = deg2rad( 49.348483 );
    my $time = time_gm( 0, 0, 0, 13, 10, 2028 ) + .19 * 86400;

    my $eci = Astro::Coord::ECI->dynamical( $t0 )->equatorial(
	deg2rad( $alpha0 ), deg2rad( $delta0 ),
	$rho *  LIGHTYEAR2KILOMETER )->set( equinox_dynamical => $t0 );
    my $utim = Astro::Coord::ECI->dynamical( $time )->universal();
    my ( $alpha, $delta ) = $eci->precess( $utim )->equatorial();
    my $tolerance = 1e-6;

    tolerance $alpha, $alphae, $tolerance,
	'Precession of equinoxes: right ascension';

    tolerance $delta, $deltae, $tolerance,
	'Precession of equinoxes: declination';
}

{
    note q{Precession - with 'station' attribute};

    my $alpha0 = 41.054063;
    my $delta0 = 49.227750;
    my $rho = 36.64;
    my $t0 = PERL2000;
    my $alphae = deg2rad( 41.547214 );
    my $deltae = deg2rad( 49.348483 );
    my $time = time_gm( 0, 0, 0, 13, 10, 2028 ) + .19 * 86400;

    my $sta = Astro::Coord::ECI->dynamical( $t0 )->eci( 0, 0, 0 )->set(
	equinox_dynamical => $t0 );
    my $eci = Astro::Coord::ECI->dynamical( $t0 )->equatorial(
	deg2rad( $alpha0 ), deg2rad( $delta0 ),
	$rho *  LIGHTYEAR2KILOMETER )->set(
	equinox_dynamical => $t0,
	station	=> $sta,
    );
    my $utim = Astro::Coord::ECI->dynamical( $time )->universal();
    my ( $alpha, $delta ) = $eci->precess( $utim )->equatorial();
    my $tolerance = 1e-6;

    tolerance $alpha, $alphae, $tolerance,
	'Precession of equinoxes: right ascension';

    tolerance $delta, $deltae, $tolerance,
	'Precession of equinoxes: declination';

    cmp_ok $sta->get( 'equinox_dynamical' ), '==', $time,
	'Station object was precessed';
}


# Right ascension/declination to ecliptic lat/lon
# Tests: ecliptic() (and obliquity())

# Based on Meeus' example 13.a, page 95.

# Meeus' example involves the star Pollux. We use an arbitrary (and much
# too small) rho, because it doesn't come into the conversion anyway.
# The time matters because it figures in to the obliquity of the
# ecliptic. Unfortunately Meeus didn't give us the time in his example,
# only the obliquity. The time used in the example was chosen because it
# gave the desired obliquity value of 23.4392911 degrees.

{
    my $time = time_gm( 36, 27, 2, 30, 6, 2009 );

    my ( $lat, $long ) = Astro::Coord::ECI->equatorial(
	deg2rad( 116.328942 ), deg2rad( 28.026183 ), 1e12, $time )->ecliptic();

    tolerance_frac $lat, deg2rad( 6.684170 ), 1e-6,
	'Equatorial to Ecliptic: latitude';


    tolerance_frac $long, deg2rad( 113.215630 ), 1e-6,
	'Equatorial to Ecliptic: longitude';
}


# Ecliptic lat/lon to right ascension/declination
# Tests: ecliptic() (and obliquity())

# Based on inverting the above test.

{
    my $time = time_gm( 36, 27, 2, 30, 6, 2009 );

    my ( $ra, $dec ) = Astro::Coord::ECI->ecliptic(
	deg2rad( 6.684170 ), deg2rad( 113.215630 ), 1e12, $time )->equatorial();

    tolerance_frac $ra, deg2rad( 116.328942 ), 1e-6,
	'Ecliptic to Equatorial: Right ascension';

    tolerance_frac $dec, deg2rad( 28.026183 ), 1e-6,
	'Ecliptic to Equatorial: Declination';
}

use constant ASTRONOMICAL_UNIT => 149_597_870; # Meeus, Appendix 1, pg 407

# Ecliptic lat/long to ECI
# Tests: equatorial() (and ecliptic())

# This test is based on Meeus' example 26.a.

{
    my $time = time_gm( 0, 0, 0, 13, 9, 1992 );
    my $lat = .62 / 3600;
    my $lon = 199.907347;
    my $rho = .99760775 * ASTRONOMICAL_UNIT;
    my $expx = -0.9379952 * ASTRONOMICAL_UNIT;
    my $expy = -0.3116544 * ASTRONOMICAL_UNIT;
    my $expz = -0.1351215 * ASTRONOMICAL_UNIT;

    my ( $x, $y, $z ) = Astro::Coord::ECI->dynamical( $time )->
	ecliptic( deg2rad( $lat ), deg2rad( $lon ), $rho
	)->eci();
    my $tolerance = 1e-5;

    tolerance_frac $x, $expx, $tolerance, 'Ecliptic to ECI: X';

    tolerance_frac $y, $expy, $tolerance, 'Ecliptic to ECI: Y';

    tolerance_frac $z, $expz, $tolerance, 'Ecliptic to ECI: Z';
}

# universal time to local mean time
# Tests: local_mean_time()

# This test is based on http://www.statoids.com/tconcept.html

{
    my $time = time_gm( 0, 0, 0, 1, 0, 2001 );
    my $lat = 29/60 + 40;
    my $lon = -( 8/60 + 86 );
    my $offset = -( ( 5 * 60 + 44 ) * 60 + 32 );

    my $got = floor( Astro::Coord::ECI->geodetic(
	    deg2rad( $lat ), deg2rad( $lon ), 0 )->universal(
	    $time )->local_mean_time() );
    my $want = $time + $offset;

    cmp_ok $got, '==', $want, 'Universal time to Local mean time';
}


# local mean time to universal time
# Tests: local_mean_time()

# This test is the inverse of the previous one.

{
    my $time = time_gm( 28, 15, 18, 31, 11, 2000 );
    my $lat = 29/60 + 40;
    my $lon = -( 8/60 + 86 );
    my $offset = -( ( 5 * 60 + 44 ) * 60 + 32 );

    my $got = floor( Astro::Coord::ECI->geodetic(
	    deg2rad( $lat ), deg2rad( $lon ), 0 )->local_mean_time(
	    $time )->universal() + .5 );
    my $want = $time - $offset;

    cmp_ok $got, '==', $want, 'Local mean time to universal time';
}


# Equatorial coordinates relative to observer.

# I don't have a book solution for this, but if I turn off atmospheric
# refraction, you should get the same result as if you simply subtract
# the ECI coordinates of the observer from the ECI coordinates of the
# body.


{	# Begin local symbol block;

    note 'Equatorial relative to location, specified explicitly';

    my $time = time ();
    my $station = Astro::Coord::ECI->geodetic(
	deg2rad (  38.898741 ),
	deg2rad ( -77.037684 ),
	0.01668
    );
    $station->set( refraction => 0 );
    my $body = Astro::Coord::ECI->eci(
	2328.97048951, -5995.22076416, 1719.97067261,
	2.91207230, -0.98341546, -7.09081703, $time);
    my @staeci = $station->eci( $time );
    my @bdyeci = $body->eci();
    my @want = Astro::Coord::ECI->eci(
	    ( map {$bdyeci[$_] - $staeci[$_]} 0 .. 5 ), $time )->
	    equatorial();
    my @got = $station->equatorial ($body);

    tolerance $got[0], $want[0], 0.000001,
	'Right ascension relative to explicit location';

    tolerance $got[1], $want[1], 0.000001,
	'Declination relative to explicit location';

    tolerance $got[2], $want[2], 0.000001,
	'Right ascension relative to explicit location';

}	# End local symbol block.

{	# Begin local symbol block;

    note 'Equatorial relative to location specified in station attribute';

    my $time = time ();
    my $station = Astro::Coord::ECI->geodetic(
	deg2rad (  38.898741 ),
	deg2rad ( -77.037684 ),
	0.01668
    );
    $station->set( refraction => 0 );
    my $body = Astro::Coord::ECI->eci(
	2328.97048951, -5995.22076416, 1719.97067261,
	2.91207230, -0.98341546, -7.09081703, $time);
    my @staeci = $station->eci( $time );
    my @bdyeci = $body->eci();
    my @want = Astro::Coord::ECI->eci(
	    ( map {$bdyeci[$_] - $staeci[$_]} 0 .. 5 ), $time )->
	    equatorial();

    $body->set( station => $station );
    my @got = $body->equatorial_apparent();

    tolerance $got[0], $want[0], 0.000001,
	'Right ascension relative to station attribute';

    tolerance $got[1], $want[1], 0.000001,
	'Declination relative to station attribute';

    tolerance $got[2], $want[2], 0.000001,
	'Right ascension relative to station attribute';

}	# End local symbol block.

# represents().

is( Astro::Coord::ECI->represents(), 'Astro::Coord::ECI',
    'Astro::Coord::ECI->represents() returns itself' );

ok( Astro::Coord::ECI->represents( 'Astro::Coord::ECI' ),
    q{Astro::Coord::ECI->represents('Astro::Coord::ECI') is true} );

ok( ! Astro::Coord::ECI->represents( 'Astro::Coord::ECI::TLE' ),
    q{Astro::Coord::ECI->represents('Astro::Coord::ECI::TLE') is false} );

{
    # Maidenhead Locator System. Reference implementation is at
    # http://home.arcor.de/waldemar.kebsch/The_Makrothen_Contest/fmaidenhead.html
    my $got;
    my ( $lat, $lon ) = ( 38.898748, -77.037684 );

    my $sta = Astro::Coord::ECI->new()->geodetic(
	deg2rad( $lat ),
	deg2rad( $lon ),
	0,
    );


    ( $got ) = $sta->maidenhead( 3 );
    is $got, 'FM18lv', "Maidenhead precision 3 for $lat, $lon is 'FM18lv'";

    ( $got ) = $sta->maidenhead( 2 );
    is $got, 'FM18', "Maidenhead precision 2 for $lat, $lon is 'FM18'";

    ( $got ) = $sta->maidenhead( 1 );
    is $got, 'FM', "Maidenhead precision 1 for $lat, $lon is 'FM'";

}

# Velocity sanity tests
{
    my $time = time_gm( 0, 0, 12, 1, 3, 2012 );

    my $body = Astro::Coord::ECI->new(
	name => 'eci coordinates',
    )->eci(
	1000, 1000, 1000, 0, 0, 0, $time );

    my $sta = Astro::Coord::ECI->new(
	name => 'White House',
    )->geodetic(
	deg2rad( 38.8987 ),
	deg2rad( -77.0377 ),
	17 / 1000,
    );

    $body->set( station => $sta );

    velocity_sanity ecef => $body;

    velocity_sanity neu => $body->universal( $time );

    velocity_sanity enu => $body->universal( $time );

    velocity_sanity azel => $body->universal( $time ), $sta;

    velocity_sanity azel => $body->universal( $time );

    velocity_sanity eci => $sta->universal( $time );

    {
	$body->set( frequency => 1_000_000 );
	my @azel = $body->azel();
	if ( @azel > 6 ) {
	    # This is just to be sure it is calculated consistently; I
	    # have no idea whether I am getting the right answer.
	    tolerance $azel[6], .25, 0.01, 'Doppler shift';
	} else {
	    fail 'No Doppler calculated';
	}
	$body->set( frequency => undef );
    }

    # I would love to have tested the internal routines before this, but
    # the critical thing is velocity, and I have no test data. So
    # assuming that the sanity tests are correct, we go back the other
    # way and see how we do.

    my @want = $body->universal( $time )->neu();
    my @got = Astro::Coord::ECI::_convert_spherical_to_cartesian(
	$body->azel() );
    my @coord = qw{ X Y Z X_dot Y_dot Z_dot };
    foreach my $inx ( 0 .. 5 ) {
	tolerance $got[$inx], $want[$inx], 1e-12, $coord[$inx];
    }
}

{
    local $@ = undef;
    my $eci = Astro::Coord::ECI->new();

    if ( eval { $eci->set( twilight => PI ); 1 } ) {
	fail 'Should not be able to set twilight to PI';
    } elsif ( $@ =~ m/ \Qinvalid value for 'twilight'\E /smx ) {
	pass 'Setting twilight to PI threw correct exception';
    } else {
	fail "Setting twilight to PI threw incorrect exception '$@'";
    }
}

done_testing;

# need to test:
#    dip
#    get (class, object)
#    reference_ellipsoid
#    set (class, object with and without resetting the object)

1;

# ex: set textwidth=72 :
