#!/usr/bin/perl

use strict;
use warnings;

use Clutter::TestHelper tests => 9;

use Champlain ':coords';


exit tests();


sub tests {
	test_all();
	return 0;
}


sub test_all {
	my $map_source = Champlain::NetworkTileSource->new_full(
		'test::fake-map',
		'Fake map',
		'free',
		'http://www.it-is-free.org/license.txt',
		0,
		10,
		128,
		'mercator',
		'http://www.it-is-free.org/tiles/#Z#/#X#-#Y#.png'
	);
	isa_ok($map_source, 'Champlain::NetworkTileSource');
	
	$map_source->set_offline(TRUE);
	ok($map_source->get_offline, "get_offline");
	$map_source->set_offline(FALSE);
	ok(!$map_source->get_offline, "set_offline");
	
	is($map_source->get_id, 'test::fake-map');
	is($map_source->get_name, 'Fake map');
	
	
	is ($map_source->get_uri_format, 'http://www.it-is-free.org/tiles/#Z#/#X#-#Y#.png', "get_uri_format");
	$map_source->set_uri_format('http://www.changed.org/tiles/#Z#/#X#-#Y#.png');
	is ($map_source->get_uri_format, 'http://www.changed.org/tiles/#Z#/#X#-#Y#.png', "set_uri_format");
	
	
	
	is($map_source->get('proxy-uri'), undef);
	$map_source->set_proxy_uri("http://my-proxy:8080");
	is($map_source->get('proxy-uri'), "http://my-proxy:8080", "set_proxy_uri");
}
