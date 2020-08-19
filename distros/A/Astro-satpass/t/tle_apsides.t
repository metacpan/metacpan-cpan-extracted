package main;	# To make Perl::Critic happy.

use strict;
use warnings;

use lib qw{ inc };

use Astro::Coord::ECI::TLE::Period;
use My::Module::Test qw{ tolerance };
use Test::More 0.88;

# All data from Space Track http://www.space-track.org/
# Their perigee and apogee data converted by adding 6378.14 km (the
# equatorial radius of the Earth according to Jean Meeus' "Astronomical
# Algorithms"). Semimajor is the average of their perigee and apogee,
# plus Meeus' radius of the Earth.

new( 7970.4, 0.1849966, 'OID 00005 (Vanguard 1) Epoch 09198.49982685' );
check( semimajor =>  8624.14, 1 );
check( periapsis =>  7029.14, 1 );
check( apoapsis  => 10219.14, 1 );
check( perigee   =>  7029.14, 1 );
check( apogee    => 10219.14, 1 );

new( 5487.6, 0.0007102, 'OID 25544 (ISS) Epoch 09197.89571571' );
check( semimajor =>  6724.64, 1 );
check( periapsis =>  6720.14, 1 );
check( apoapsis  =>  6729.14, 1 );
check( perigee   =>  6720.14, 1 );
check( apogee    =>  6729.14, 1 );

new( 43081.2, 0.0134177, 'OID 20959 (Navstar 22) Epoch 09197.50368658' );
check( semimajor => 26561.14, 1 );
check( periapsis => 26203.14, 2 );
check( apoapsis  => 26919.14, 2 );
check( perigee   => 26203.14, 2 );
check( apogee    => 26919.14, 2 );

new( 43107.0, 0.7271065, 'OID 21118 (Molniya 1-80) Epoch 09197.37303507' );
check( semimajor => 26572.14, 1 );
check( periapsis =>  7251.14, 1 );
check( apoapsis  => 45893.14, 1 );
check( perigee   =>  7251.14, 1 );
check( apogee    => 45893.14, 1 );

done_testing;

{
    my $tle;

    sub new {
	my ( $period, $eccentricity, $name ) = @_;
	$tle = Astro::Coord::ECI::TLE::Period->new(
	    period => $period,
	    eccentricity => $eccentricity,
	    name => $name );
	return;
    }

    sub check {
	my ( $method, $want, $tolerance ) = @_;
	my $name = sprintf '%s %s', $tle->get( 'name' ), $method;
	my $got = $tle->$method();
	@_ = ( $got, $want, $tolerance, $name );
	goto &tolerance;
    }

}

1;

# ex: set filetype=perl textwidth=72 :
