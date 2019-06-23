#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More tests => 2;
use Test::Number::Delta within => 1e-6;


BEGIN {
	use_ok( 'Astro::Montenbruck::Time::Sidereal' );
}


my $jd = 2446896.30625;
my $ramc = ramc($jd, 0);
delta_ok($ramc, 128.7378734);
