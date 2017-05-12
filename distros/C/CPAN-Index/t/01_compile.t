#!/usr/bin/perl -w

# Test that CPAN::Index loads and compiles

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

ok( $] >= 5.005, "Your perl is new enough" );
use_ok( 'CPAN::Index'         );
use_ok( 'CPAN::Index::Loader' );

exit(0);
