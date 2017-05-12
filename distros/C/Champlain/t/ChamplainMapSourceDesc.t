#!/usr/bin/perl

use strict;
use warnings;

use Clutter::TestHelper tests => 22;
use Champlain ':maps';


exit tests();


sub tests {
	test_get_set();
	return 0;
}


sub test_get_set {
	my $factory = Champlain::MapSourceFactory->dup_default();
	isa_ok($factory, 'Champlain::MapSourceFactory');
	
	# Get the maps available
	my @maps = $factory->dup_list();
	ok(@maps >= 5, "Maps factory has the default maps");
	
	# Find the OAM map and check that the it's properly described
	my @found = grep { $_->id eq Champlain::MapSourceFactory->OSM_MAPNIK } @maps;
	is(scalar(@found), 1, "Found a single map matching OAM");
	if (! @found) {
		fail("Can't test a Champlain::MapSourceDesc without a map description") for 1 .. 22;
		return;
	}

	# Getters
	my ($source) = @found;
	isa_ok($source, 'Champlain::MapSourceDesc');
	is($source->id, Champlain::MapSourceFactory->OSM_MAPNIK, "get id()");
	is($source->name, 'OpenStreetMap Mapnik', "get name()");
	ok($source->license =~ /OpenStreetMap contributors/, "get license()");
	is($source->license_uri, 'http://creativecommons.org/licenses/by-sa/2.0/', "get license_uri()");
	is($source->min_zoom_level, 0, "get min_zoom_level()");
	is($source->max_zoom_level, 18, "get max_zoom_level()");
	is($source->projection, 'mercator', "get projection()");
	is($source->uri_format, 'http://tile.openstreetmap.org/#Z#/#X#/#Y#.png', "get uri_format()");
	
	# Setters
	$source->id('test');
	is($source->id, 'test', "set id()");
	
	$source->name("new name");
	is($source->name, "new name", "set name()");
	
	$source->license("free for all");
	is($source->license, "free for all", "set license()");
	
	$source->license_uri('file:///tmp/free.txt');
	is($source->license_uri, 'file:///tmp/free.txt', "set license_uri()");
	
	$source->min_zoom_level(2);
	is($source->min_zoom_level, 2, "set min_zoom_level()");
	
	$source->max_zoom_level(4);
	is($source->max_zoom_level, 4, "set max_zoom_level()");
	
	# There are no other projections now, we have to trust that the setter works
	$source->projection('mercator');
	is($source->projection, 'mercator', "set projection()");

	$source->uri_format('http://tile.oam.org/tiles/#Z#/#X#/#Y#.jpg');
	is($source->uri_format, 'http://tile.oam.org/tiles/#Z#/#X#/#Y#.jpg', "set uri_format()");

	# Optional tests that require Test::Exception to be installed
	my $has_test_exception = 0;
	eval {
		require Test::Exception;
		$has_test_exception = 1;
	} or do {
		diag("Can't load test exception $@");
	};
	
	SKIP: {
		skip  "Can't test for exceptions because Test::Exception is not loaded", 2 unless $has_test_exception;

		# The constructor is not yet available in the perl bindings
		Test::Exception::throws_ok(
			sub { $source->constructor },
			qr/\Qdesc->constructor() isn't implemented yet/,
			"get constructor() isn't implemented"
		);

		Test::Exception::throws_ok(
			sub { $source->constructor(sub{}) },
			qr/\Qdesc->constructor(\&code_ref)/,
			"set constructor() isn't implemented"
		);
	}
}
