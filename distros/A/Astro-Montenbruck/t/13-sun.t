#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More tests => 4;
use Test::Number::Delta within => 1e-6;
use Astro::Montenbruck::NutEqu qw/mean2true/;

BEGIN {
	use_ok( 'Astro::Montenbruck::Ephemeris::Planet::Sun' );
}

my $sun = new_ok('Astro::Montenbruck::Ephemeris::Planet::Sun');


my $jd = 2448908.5; # 1992 Oct 13, 0h
my $t  = ($jd - 2451545) / 36525;
my ($l, $b, $r) = $sun->sunpos($t); # true geocentric ecliptical coordinates

subtest 'True Geocentric' => sub {
    plan tests => 3;

    # Meeus, "Astronomical Algoryhms", 2 ed, p.165
    # l = 199.907272, b = 0.99760853
    my @exp = (199.90704480756881, 0.00018165126429624617, 0.99760946097212733);
    delta_ok($l, $exp[0], 'l') or diag("Expected: ${$exp[0]}, got: $l");
    delta_ok($b, $exp[1], 'b') or diag("Expected: ${$exp[1]}, got: $b");
    delta_ok($r, $exp[2], 'r') or diag("Expected: ${$exp[2]}, got: $r");
};

subtest 'Apparent' => sub {
    plan tests => 2;

    my @exp = (199.90596405748963, 0.00021307003194609753);
    my ($al, $ab) = $sun->apparent($t, [$l, $b, $r], mean2true($t));
    delta_ok($al, $exp[0], 'longitude') or diag("Expected: ${$exp[0]}, got: $al");
    delta_ok($ab, $exp[1], 'latitude')  or diag("Expected: ${$exp[1]}, got: $ab");;
};






