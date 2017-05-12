#!/usr/bin/perl

use strict;
use warnings;

use File::Temp 'tempdir';
use Clutter::TestHelper tests => 5;
use Champlain;

exit tests();

sub tests {
	my $cache = Champlain::FileCache->new();
	isa_ok($cache, 'Champlain::FileCache');
	
	my $folder = tempdir(CLEANUP => 1);
	$cache = Champlain::FileCache->new_full(1_024 * 10, $folder, FALSE);
	isa_ok($cache, 'Champlain::FileCache');


	is($cache->get_size_limit, 1_024 * 10, "get_size_limit");
	$cache->set_size_limit(2_048);
	is($cache->get_size_limit, 2_048, "set_size_limit");
	
	is($cache->get_cache_dir, $folder, "get_cache_dir");
	
	# Can't be tested
	$cache->purge();
	$cache->purge_on_idle();

	return 0;
}
