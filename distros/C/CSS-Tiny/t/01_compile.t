#!/usr/bin/perl

# Formal testing for CSS::Tiny

# This test only tests that the module compiles.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

# Check their Perl version
ok( $] >= 5.004, "Your perl is new enough" );

# Does the module load
use_ok( 'CSS::Tiny' );
