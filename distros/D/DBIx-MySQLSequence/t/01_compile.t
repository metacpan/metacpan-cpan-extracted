#!/usr/bin/perl

# Load testing for DBIx::MySQLSequence

# This test script only tests that the module compiles

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.005, "Your perl is new enough" );

use_ok( 'DBIx::MySQLSequence' );
