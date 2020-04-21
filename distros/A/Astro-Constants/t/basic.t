#!perl -T

use Test::More tests => 2;
use Astro::Constants::MKS qw/SPEED_LIGHT/;

is( SPEED_LIGHT, 2.99792458e8, 'SPEED_LIGHT in MKS' );

eval 'SPEED_LIGHT = 2';
like($@, qr/Can't modify constant item in scalar assignment/, "Can't change a constant");
