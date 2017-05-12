#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Clutter;
use Champlain;

exit tests();

sub tests {

	if (! Champlain::HAS_MEMPHIS) {
		plan skip_all => "No support for memphis";
		return 0;
	}
	plan tests => 2;

	Clutter->init();

	my $map_source = Champlain::NetworkMapDataSource->new();
	isa_ok($map_source, 'Champlain::NetworkMapDataSource');

	$map_source->set_api_uri('http://localhost/test');
	is($map_source->get_api_uri, 'http://localhost/test', "get/set api_uri");

	return 0;
}
