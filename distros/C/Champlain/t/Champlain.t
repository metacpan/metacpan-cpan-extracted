#!/usr/bin/perl

use strict;
use warnings;

use Clutter::TestHelper tests => 17;

#use Champlain qw(:coords :maps);
use Champlain qw(:coords :maps);

exit tests();

sub tests {
	test_version();
	test_constants();
	return 0;
}


sub test_version {
	ok($Champlain::VERSION, "Library loaded");

	ok(defined Champlain::MAJOR_VERSION, "MAJOR_VERSION exists");
	ok(defined Champlain::MINOR_VERSION, "MINOR_VERSION exists");
	ok(defined Champlain::MICRO_VERSION, "MICRO_VERSION exists");

	ok(Champlain->CHECK_VERSION(0,0,0), "CHECK_VERSION pass");
	ok(!Champlain->CHECK_VERSION(50,0,0), "CHECK_VERSION fail");

	my @version = Champlain->GET_VERSION_INFO;
	my @expected = (
		Champlain::MAJOR_VERSION,
		Champlain::MINOR_VERSION,
		Champlain::MICRO_VERSION,
	);
	is_deeply(\@version, \@expected, "GET_VERSION_INFO");

	is(MAP_OSM_MAPNIK, Champlain::MapSourceFactory->OSM_MAPNIK, "MAP_OSM_MAPNIK exists");
	is(MAP_OSM_OSMARENDER, Champlain::MapSourceFactory->OSM_OSMARENDER, "MAP_OSM_OSMARENDER exists");
	is(MAP_OSM_CYCLE_MAP, Champlain::MapSourceFactory->OSM_CYCLE_MAP, "MAP_OSM_CYCLE_MAP exists");
	is(MAP_OAM, Champlain::MapSourceFactory->OAM, "MAP_OAM exists");
	is(MAP_MFF_RELIEF, Champlain::MapSourceFactory->MFF_RELIEF, "MAP_MFF_RELIEF exists");

	ok(defined Champlain::HAS_MEMPHIS, "HAS_MEMPHIS exists");
}


sub test_constants {
	is(MIN_LAT,   -90, "MIN_LAT");
	is(MAX_LAT,    90, "MAX_LAT");
	is(MIN_LONG, -180, "MIN_LONG");
	is(MAX_LONG,  180, "MAX_LONG");
}
