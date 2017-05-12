#!/usr/bin/perl

use strict;
use warnings;

use Clutter::TestHelper tests => 2;

use Champlain qw(:coords :maps);

exit tests();

sub tests {
	my $chain = Champlain::MapSourceChain->new();
	isa_ok($chain, 'Champlain::MapSourceChain');

	my $factory = Champlain::MapSourceFactory->dup_default();
	my $osm_mapnik = $factory->create(MAP_OSM_MAPNIK);
	my $osm_cycle_map = $factory->create(MAP_OSM_CYCLE_MAP);

	# Can't be tested but at least we call them
	$chain->push($osm_mapnik);
	$chain->push($osm_cycle_map);
	$chain->pop();
	$chain->pop();
	pass("push/pop");

	return 0;
}
