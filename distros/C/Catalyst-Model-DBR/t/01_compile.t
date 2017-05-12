#!/usr/bin/perl

# Test that everything compiles, so the rest of the test suite can
# load modules without having to check if it worked.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.00600, 'Perl version is new enough' );
use_ok('Catalyst::Model::DBR');

diag("\$Catalyst::Model::DBR::VERSION=$Catalyst::Model::DBR::VERSION");
