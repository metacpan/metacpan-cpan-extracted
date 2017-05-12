#!/usr/bin/perl

# Test compatibility with prefork.pm

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

# We don't need to run this if prefork is not installed
my @test_plan;
BEGIN {
	eval { require prefork; };
	@test_plan = $@
		? ('skip_all', 'prefork.pm is not installed')
		: (tests => 5);
}
use Test::More @test_plan;
use Class::Autouse 'C';

ok( ! $Class::Autouse::DEVEL, '$Class::Autouse::DEVEL is false' );
is( $INC{"C.pm"}, 'Class::Autouse', 'C.pm is autoused' );

ok( prefork::enable(), 'prefork::enable returns true' );
is( $Class::Autouse::DEVEL, 1, '$Class::Autouse::DEVEL is true' );
isnt( $INC{"C.pm"}, 'Class::Autouse', 'C.pm has been loaded' );
