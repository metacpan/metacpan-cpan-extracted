#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Test::Number::Delta within => 1e-4;

BEGIN {
	use_ok( 'Astro::Montenbruck::CoCo', qw/:all/  );
}

subtest 'Ecliptic <-> Equator' => sub {
    plan tests => 2;

	my $alpha   = 116.328942;
	my $delta   = 28.026183;
	my $epsilon = 23.4392911;
    my $lambda  = 113.21563;
    my $beta    = 6.68417;

    subtest 'equ2ecl' => sub {
        plan tests => 2;
        my ($x, $y) = equ2ecl( $alpha, $delta, $epsilon);
    	delta_ok($x, $lambda, 'lambda');
    	delta_ok($y, $beta, 'beta');
    };

    subtest 'ecl2equ' => sub {
        plan tests => 2;
        my ($x, $y) = ecl2equ( $lambda, $beta, $epsilon);
    	delta_ok($x, $alpha, 'alpha');
    	delta_ok($y, $delta, 'delta');
    };
};

subtest 'Equator <-> Horizon' => sub {
    plan tests => 2;

	my $delta  = 14.3986111111111;
	my $h      = 8.62222222222222;
    my $az     = 310.259333333333;
    my $alt    = -10.9724444444444;
    my $phi    = 51.25;

    subtest 'equ2hor' => sub {
        plan tests => 2;
        my ($x, $y) = equ2hor( $h * 15, $delta, $phi);
    	delta_ok($x, $az, 'azimuth');
    	delta_ok($y, $alt, 'altitude');
    };

    subtest 'hor2equ' => sub {
        plan tests => 2;
        my ($x, $y) = hor2equ( $az, $alt, $phi);
    	delta_ok($x / 15, $h, 'hour angle');
    	delta_ok($y, $delta, 'delta');
    };
};



done_testing();
