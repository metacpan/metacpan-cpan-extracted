#!/usr/bin/perl

use strict;
use warnings;

use Clutter::TestHelper tests => 10;

use Champlain;

exit tests();

sub tests {
	test_generic();
	return 0;
}


sub test_generic {
	my $point = Champlain::Point->new(10.2, 34.5);
	isa_ok($point, 'Champlain::Point');

	is($point->lat, 10.2, "point->lat()");
	is($point->lon, 34.5, "point->lon()");


	# Copy the point
	my $copy = $point->copy;
	isa_ok($copy, 'Champlain::Point');
	is($copy->lat, $point->lat, "lat of copy is identical to the original");
	is($copy->lon, $point->lon, "lon of copy is identical to the original");


	# Modify the copy
	$copy->lat(-45.03);
	is($copy->lat, -45.03, "point->lat(x)");
	is($point->lat, 10.2, "point->lat()");

	$copy->lon(74.364);
	is($copy->lon, 74.364, "point->lon(y)");
	is($point->lon, 34.5, "point->lon()");
}
