#!/usr/bin/perl 

# Compile testing for CPAN::Inject

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

ok( $] >= 5.005, 'Your perl is new enough' );

use_ok( 'CPAN::Inject' );
script_compiles_ok( 'script/cpaninject' );
