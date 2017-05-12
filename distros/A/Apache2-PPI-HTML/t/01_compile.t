#!/usr/bin/perl

# Load test the Apache2::PPI::HTML module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More 'tests' => 1;

ok( $] >= 5.005, 'Your perl is new enough' );

# use_ok('Apache2::PPI::HTML');
