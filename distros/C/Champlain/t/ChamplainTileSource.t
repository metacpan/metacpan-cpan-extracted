#!/usr/bin/perl

use strict;
use warnings;

use Clutter::TestHelper tests => 12;

use Champlain;

exit tests();

sub tests {
	my $tile = Champlain::ErrorTileSource->new_full(64);
	isa_ok($tile, 'Champlain::ErrorTileSource');

	# get/set cache
	is($tile->get_cache, undef, "get_cache");
	my $cache = Champlain::FileCache->new();
	isa_ok($cache, 'Champlain::FileCache');
	$tile->set_cache($cache);
	is($tile->get_cache, $cache, "set_cache");

	$tile->set_id("tile-id");
	is($tile->get('id'), "tile-id", "set_id");

	$tile->set_name("tile-name");
	is($tile->get('name'), "tile-name", "set_name");

	$tile->set_license("tile-license");
	is($tile->get('license'), "tile-license", "set_license");

	$tile->set_license_uri("license-uri");
	is($tile->get('license-uri'), "license-uri", "set_license_uri");

	$tile->set_min_zoom_level(5);
	is($tile->get('min-zoom-level'), 5, "set_min_zoom_level");

	$tile->set_max_zoom_level(10);
	is($tile->get('max-zoom-level'), 10, "set_max_zoom_level");

	$tile->set_tile_size(128);
	is($tile->get('tile-size'), 128, "set_tile_size");

	$tile->set_projection('mercator');
	is($tile->get('projection'), 'mercator', "set_projection");

	return 0;
}
