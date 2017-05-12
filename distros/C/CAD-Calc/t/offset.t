#!/usr/bin/perl

use Test::More qw(
	no_plan
	);

use_ok('CAD::Calc');

SKIP: {
	my $helper = 'Math::Geometry::Planar::Offset';
	my $ok = eval("require $helper;"); 
	$ok or skip("could not load $helper");
	my @gons = CAD::Calc::offset([ [0,0], [1,0], [1,1], [0,1] ], 0.25);
	ok(@gons == 1);
}
