package main;

use strict;
use warnings;

use Astro::Coord::ECI::TLE;
use Time::Local;

use Test::More 0.88;	# Because of done_testing()

my ($near, $deep) = Astro::Coord::ECI::TLE->parse(<<eod);
1 88888U          80275.98708465  .00073094  13844-3  66816-4 0    8
2 88888  72.8435 115.9689 0086731  52.6988 110.5714 16.05824518  105
1 11801U          80230.29629788  .01431103  00000-0  14311-1
2 11801  46.7916 230.4354 7318036  47.4722  10.4117  2.28537848
eod

my $time = 61196688000	# 01-Apr-3909 00:00:00 GMT, epoch 1-Jan-1970.
    + timegm( 0, 0, 0, 1, 0, 1970 );	# Adjust for system epoch.

plan(tests => 14);

my $want;

# SGP

$near->set(model => 'sgp');
$want = qr{effective eccentricity > 1};

fails( $near, universal => $time, $want,
    'SGP model failure' );

fails( $near, universal => $time, $want,
    'SGP should give same failure on retry' );

# SGP4

$near->set(model => 'sgp4');

fails( $near, universal => $time, $want,
    'SGP4 model failure' );

fails( $near, universal => $time, $want,
    'SGP4 should give same failure on retry' );

# SDP4

$deep->set(model => 'sdp4');

fails( $deep, universal => $time, $want,
    'SDP4 model failure' );

fails( $deep, universal => $time, $want,
    'SDP4 should give same failure on retry' );

# SGP8

$near->set(model => 'sgp8');

fails( $near, universal => $time, $want,
    'SGP8 model failure' );

fails( $near, universal => $time, $want,
    'SGP8 should give same failure on retry' );

# SDP8

$deep->set(model => 'sdp8');

fails( $deep, universal => $time, $want,
    'SDP8 model failure' );

fails( $deep, universal => $time, $want,
    'SDP8 should give same failure on retry' );

# SGP4R

$near->set(model => 'sgp4r');
$deep->set(model => 'sgp4r');
$want = qr{Mean eccentricity < 0 or > 1};

fails( $near, universal => $time, $want,
    'SGP4R model failure (near-Earth)' );

fails( $near, universal => $time, $want,
    'SGP4R should give same failure on retry (near-Earth)' );

fails( $deep, universal => $time, $want,
    'SGP4R model failure (deep-space).');

fails( $deep, universal => $time, $want,
    'SGP4R should give same failure on retry (deep-space)' );

sub fails {	## no critic (RequireArgUnpacking)
    my ( $obj, $method, @args ) = @_;
    my $name = pop @args;
    my $want = pop @args;
    if ( eval { $obj->$method( @args ); 1 } ) {
	@_ = ( "$name failed to throw error" );
	goto &fail;
    } else {
	@_ = ( $@, $want, $name );
	goto &like;
    }
}

1;
