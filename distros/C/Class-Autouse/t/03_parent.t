#!/usr/bin/perl

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

use Test::More tests => 2;
use Class::Autouse qw{:devel};
use Class::Autouse::Parent;

# Test the loading of children
use_ok( 'A' );
ok( $A::B::loaded, 'Parent class loads child class OK' );
$A::B::loaded ? 1 : 0 # Shut a warning up
