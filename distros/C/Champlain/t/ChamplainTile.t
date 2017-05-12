#!/usr/bin/perl

use strict;
use warnings;

use Clutter::TestHelper tests => 46;

use Champlain ':coords';
use Data::Dumper;

exit tests();


sub tests {
	test_new_empty();
	test_new_full();
	return 0;
}


sub test_new_full {
	my $tile = Champlain::Tile->new_full(50, 75, 514, 1);
	isa_ok($tile, 'Champlain::Tile');
	
	is($tile->get_x(), 50, "get_x() full tile");
	is($tile->get_y(), 75, "get_y() full tile");
	is($tile->get_zoom_level(), 1, "get_zoom_level() full tile");
	is($tile->get_size(), 514, "get_size() full tile");
	is($tile->get_state(), 'none', "get_state() full tile");
	is($tile->get_content(), undef, "get_content() full tile");
	is($tile->get_etag(), undef, "get_etag() full tile");
	is_deeply(
		[$tile->get_modified_time],
		[undef, undef],
		"get_modified_time() full tile"
	);

	test_all_setters($tile);
}


sub test_new_empty {
	my $tile = Champlain::Tile->new();
	isa_ok($tile, 'Champlain::Tile');
	
	is($tile->get_x(), 0, "get_x() default tile");
	is($tile->get_y(), 0, "get_y() default tile");
	is($tile->get_zoom_level(), 0, "get_zoom_level() default tile");
	is($tile->get_size(), 0, "get_size() default tile");
	is($tile->get_state(), 'none', "get_state() default tile");
	is($tile->get_content(), undef, "get_content() full tile");
	is($tile->get_etag(), undef, "get_etag() full tile");
	is_deeply(
		[$tile->get_modified_time],
		[undef, undef],
		"get_modified_time() full tile"
	);
	
	test_all_setters($tile);
}


sub test_all_setters {
	my $tile = Champlain::Tile->new();
	
	$tile->set_x(100);
	is($tile->get_x(), 100, "set_x()");
	
	$tile->set_y(250);
	is($tile->get_y(), 250, "set_y()");
	
	$tile->set_zoom_level(2);
	is($tile->get_zoom_level(), 2, "set_zoom_level()");
	
	$tile->set_size(128);
	is($tile->get_size(), 128, "set_size()");
	
	$tile->set_state('done');
	is($tile->get_state(), 'done', "set_state()");

	my $actor = Clutter::Group->new();
	$tile->set_content($actor);
	is($tile->get_content(), $actor, "set_content()");
	
	$tile->set_etag('http://localhost/tile/2/100-250.png');
	is($tile->get_etag(), 'http://localhost/tile/2/100-250.png', "set_etag()");

	# Set the time to now
	$tile->set_modified_time();
	my @time = $tile->get_modified_time();
	is(scalar(@time), 2, "Got seconds and microseconds");
	ok(defined $time[0], "Seconds are defined");
	ok(defined $time[1], "Microseconds are defined");

	
	# The epoch
	$tile->set_modified_time(0, 0);
	is_deeply(
		[$tile->get_modified_time()],
		[0, 0],
		"set_modified_time(0, 0)"
	);
	
	# 2009-07-11 20:10:23
	$tile->set_modified_time(1247335783, 20);
	is_deeply(
		[$tile->get_modified_time()],
		[1247335783, 20],
		"set_modified_time(0, 0)"
	);

	$tile->set_fade_in(FALSE);
	is($tile->get_fade_in, FALSE, "get_fade_in");

	$tile->set_fade_in(TRUE);
	is($tile->get_fade_in, TRUE, "set_fade_in");
}
