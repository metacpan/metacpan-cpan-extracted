#!/usr/bin/perl
use Cartography::Projection::GCTP qw[:all];

# Projection used is Mercator with StandardMeridian=-130 and TrueScale=60
# See: http://dbwww.essc.psu.edu/lasdoc/programmer/supports/georeg/gctp.html (Table A)

# Spherical to Cartesian
my($lon, $lat) = (-137, 65);
my($x, $y) = Cartography::Projection::GCTP->projectCoordinatePair(
	$lon, $lat,
	P_GEO, 0, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], U_DEGREE, 0,
	P_MERCAT, 0, [0, 0, 0, 0, -130000000, 60000000, 0, 0, 0, 0, 0, 0, 0, 0, 0], U_METER, 0,
);
print "x=$x, y=$y\n";

# Cartesian to Spherical
my($lon, $lat) = Cartography::Projection::GCTP->projectCoordinatePair(
	$x, $y,
	P_MERCAT, 0, [0, 0, 0, 0, -130000000, 60000000, 0, 0, 0, 0, 0, 0, 0, 0, 0], U_METER, 0,
	P_GEO, 0, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], U_DEGREE, 0,
);
print "lon=$lon, lat=$lat\n";
