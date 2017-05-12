#!/usr/bin/perl

use 5.008;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More        0.86 tests => 2;
use Test::NoWarnings 0.084;

use_ok( 'CPAN::Mini::Visit' );
