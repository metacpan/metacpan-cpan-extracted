#!/usr/bin/perl

use strict;
use warnings;

use Clutter::TestHelper tests => 5;

use Champlain;

my $CACHE_DIR = "test-cache";
END {
	rmdir $CACHE_DIR if -d $CACHE_DIR;
}

exit tests();

sub tests {
	mkdir($CACHE_DIR) unless -d $CACHE_DIR;
	my $cache = Champlain::FileCache->new_full(1_024 * 10, $CACHE_DIR, FALSE);
	isa_ok($cache, 'Champlain::TileCache');

	is($cache->get_persistent, FALSE, "get_persistent");

	SKIP: {
		skip "Not implemented (store_tile/refresh_tile_time/on_tile_filled)", 2;
		my $tile = Champlain::Tile->new();
		isa_ok($tile, "Champlain::Tile");
		$cache->store_tile($tile, '');
		$cache->refresh_tile_time($tile);
		$cache->on_tile_filled($tile);
		pass("store_tile/refresh_tile_time/on_tile_filled");
  };

	
	# Can't be tested
	$cache->clean();
	pass("clean");

	return 0;
}
