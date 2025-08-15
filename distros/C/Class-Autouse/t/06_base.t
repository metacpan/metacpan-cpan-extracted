#!/usr/bin/perl

# Test interaction with base.pm

use strict;
use File::Spec ();
BEGIN {
	$|  = 1;
	$^W = 1;
	require lib;
	lib->import(
		File::Spec->catdir(
			File::Spec->curdir, 't', 'modules',
		)
	);
}

use Test::More tests => 4;
use Class::Autouse ();





#####################################################################
# The case where you autouse only the top module should work fine.

use_ok( 'Class::Autouse' => 'baseB' );
is( baseB->dummy, 2, 'Calling method in baseB interacts with baseA correctly' );





#####################################################################
# Autoloading BOTH of them may fail (nope...)

use_ok( 'Class::Autouse' => 'baseC', 'baseD' );
is( baseD->dummy, 3, 'Calling method in baseD interacts with baseC correctly' );

1;
