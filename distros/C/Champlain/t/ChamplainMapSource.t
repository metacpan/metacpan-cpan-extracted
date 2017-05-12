#!/usr/bin/perl

use strict;
use warnings;

use Clutter::TestHelper tests => 169;

use Champlain qw(:coords :maps);

my $OSM_LICENSE_REGEXP = qr/OpenStreetMap contributors/;
my $OSM_URL_LICENSE = 'http://creativecommons.org/licenses/by-sa/2.0/';

exit tests();

sub tests {
	test_osm_mapnik();
	test_osm_cyclemap();
	test_osm_osmarender();
	test_oam();
	test_mff_relief();

	return 0;
}


# OpenStreetMap Mapnik
sub test_osm_mapnik {
	my $label = "OpenStreetMap";
	my $map = get_osm_mapnik();
	isa_ok($map, 'Champlain::MapSource');
	
	# Map identification
	is($map->get_id, 'osm-mapnik', "$label id");
	is($map->get_name, 'OpenStreetMap Mapnik', "$label name");
	is($map->get_min_zoom_level, 0, "$label min zoom");
	is($map->get_max_zoom_level, 18, "$label max zoom");
	is($map->get_tile_size, 256, "$label tile size");
	ok($map->get_license =~ /$OSM_LICENSE_REGEXP/, "$label license");
	is($map->get_license_uri, $OSM_URL_LICENSE , "$label license_uri");
	
	# Generic map operations
	generic_map_operations($label, $map);
}


# OpenStreetMap Cycle Map
sub test_osm_cyclemap {
	my $label = "OpenStreetMap (cyclemap)";
	my $map = get_osm_cycle_map();
	isa_ok($map, 'Champlain::MapSource');
	
	# Map identification
	is($map->get_id, 'osm-cyclemap', "$label id");
	is($map->get_name, 'OpenStreetMap Cycle Map', "$label name");
	is($map->get_min_zoom_level, 0, "$label min zoom");
	is($map->get_max_zoom_level, 18, "$label max zoom");
	is($map->get_tile_size, 256, "$label tile size");
	ok($map->get_license =~ /$OSM_LICENSE_REGEXP/, "$label license");
	is($map->get_license_uri, $OSM_URL_LICENSE , "$label license_uri");
	
	# Generic map operations
	generic_map_operations($label, $map);
}


# OpenStreetMap Osmarender
sub test_osm_osmarender {
	my $label = "OpenStreetMap (osmarender)";
	my $map = get_osm_osmarender();
	isa_ok($map, 'Champlain::MapSource');
	
	# Map identification
	is($map->get_id, 'osm-osmarender', "$label id");
	is($map->get_name, 'OpenStreetMap Osmarender', "$label name");
	is($map->get_min_zoom_level, 0, "$label min zoom");
	is($map->get_max_zoom_level, 17, "$label max zoom");
	is($map->get_tile_size, 256, "$label tile size");
	ok($map->get_license =~ /$OSM_LICENSE_REGEXP/, "$label license");
	is($map->get_license_uri, $OSM_URL_LICENSE , "$label license_uri");
	
	# Generic map operations
	generic_map_operations($label, $map);
}


# OpenAerialMap
sub test_oam {
	my $label = "OpenAerialMap";
	my $map = get_oam();

	if (! defined $map) {
		# The map source is now gone
		SKIP: {
			skip "The map source $label is no longer available", 33;
		};
		return;
	}

	isa_ok($map, 'Champlain::MapSource');
	
	# Map identification
	is($map->get_id, 'oam', "$label id");
	is($map->get_name, 'OpenAerialMap', "$label name");
	is($map->get_min_zoom_level, 0, "$label min zoom");
	is($map->get_max_zoom_level, 17, "$label max zoom");
	is($map->get_tile_size, 256, "$label tile size");
	is($map->get_license, "(CC) BY 3.0 OpenAerialMap contributors", "$label license");
	is($map->get_license_uri, 'http://creativecommons.org/licenses/by/3.0/' , "$label license_uri");
	
	# Generic map operations
	generic_map_operations($label, $map);
}


# Maps for Free
sub test_mff_relief {
	my $label = "Maps for Free";
	my $map = get_mff_relief();
	isa_ok($map, 'Champlain::MapSource');
	
	# Map identification
	is($map->get_id, 'mff-relief', "$label id");
	is($map->get_name, 'Maps for Free Relief', "$label name");
	is($map->get_min_zoom_level, 0, "$label min zoom");
	is($map->get_max_zoom_level, 11, "$label max zoom");
	is($map->get_tile_size, 256, "$label tile size");
	is(
		$map->get_license,
		"Map data available under GNU Free Documentation license, Version 1.2 or later",
		"$label license"
	);
	is($map->get_license_uri, 'http://www.gnu.org/copyleft/fdl.html' , "$label license_uri");
	
	# Generic map operations
	generic_map_operations($label, $map);
}



# Genereic checks that should work on all map sources
sub generic_map_operations {
	my ($label, $map) = @_;
	
	# Rename of the map
	$map->set_name("No name");
	is($map->get_name, "No name", "Rename the map");
	$map->set_id('test-map');
	is($map->get_id, 'test-map', "Change the map id");
	
	
	# Relicense the map
	$map->set_license("Free for all!");
	is($map->get_license, "Free for all!", "Relicense the map");
	
	

	# Ask for the X position of the middle point
	is(
		$map->get_x($map->get_min_zoom_level, 0.0),
		$map->get_tile_size/2,
		"$label middle map x"
	);
	is(
		$map->get_longitude($map->get_min_zoom_level, $map->get_tile_size/2),
		0.0,
		"$label middle map longitude"
	);
	
	# Ask for the X position of the point the most to the right
	is(
		$map->get_x($map->get_min_zoom_level, MAX_LONG),
		$map->get_tile_size,
		"$label max map x"
	);
	is(
		$map->get_longitude($map->get_min_zoom_level, $map->get_tile_size),
		MAX_LONG,
		"$label max map longitude"
	);
	
	# Ask for the X position of the point the most to the left
	is(
		$map->get_x($map->get_min_zoom_level, MIN_LONG),
		0,
		"$label min map x"
	);
	is(
		$map->get_longitude($map->get_min_zoom_level, 0),
		MIN_LONG,
		"$label min map longitude"
	);
	
	
	# Ask for the Y position of the point in the middle
	is(
		$map->get_y($map->get_min_zoom_level, 0.0),
		$map->get_tile_size/2,
		"$label middle map y"
	);
	is(
		$map->get_latitude($map->get_min_zoom_level, $map->get_tile_size/2),
		0.0,
		"$label middle map latitude"
	);
	
	# Ask for the Y position of the point the most to the right.
	# Libchamplain is using a "Mercator projection" which has troubles with high
	# latidudes. Values above 85 are not handled properly.
	my $mercator_limit = 85;
	ok(
		$map->get_y($map->get_min_zoom_level, MAX_LAT) > 0,
		"$label max map y"
	);
	ok(
		$map->get_latitude($map->get_min_zoom_level, $map->get_tile_size) < -$mercator_limit,
		"$label max map latitude"
	);
	
	# Ask for the Y position of the point the most to the left
	is(
		$map->get_y($map->get_min_zoom_level, MIN_LAT),
		0,
		"$label min map y"
	);
	ok(
		$map->get_latitude($map->get_min_zoom_level, 0) > $mercator_limit,
		"$label min map latitude"
	);
	
	
	# The map at the first level should have a single tile (1x1)
	is(
		$map->get_row_count($map->get_min_zoom_level),
		1,
		"$label row count at min zoom"
	);
	is(
		$map->get_column_count($map->get_min_zoom_level),
		1,
		"$label column count at min zoom"
	);


	# Check that min zoom level and max zoom level meters per pixel at different
	my $meters_at_min = $map->get_meters_per_pixel($map->get_min_zoom_level, 0, 0);
	ok($meters_at_min > 0, "Meters per pixel $meters_at_min at min zoom level");

	my $meters_at_max = $map->get_meters_per_pixel($map->get_max_zoom_level, 0, 0);
	ok($meters_at_max > 0, "Meters per pixel $meters_at_max at max zoom level");

	ok($meters_at_max < $meters_at_min, "Meters per pixel are different at max/min zoom level");


	my $tile = Champlain::Tile->new();
	is($tile->get_size(), 0, "get_size() default tile");
	is($tile->get_state(), 'none', "get_state() default tile");
	$map->fill_tile($tile);
	is($tile->get_size(), 0, "size is filled");
	is($tile->get_state(), 'none', "state changed");


	is($map->get_next_source, undef, "get_next_source");
	my $next_source = Champlain::FileCache->new();
	$map->set_next_source($next_source);
	is($map->get_next_source, $next_source, "set_next_source");
}


sub get_osm_mapnik {
	my $factory = Champlain::MapSourceFactory->dup_default();
	return $factory->create(MAP_OSM_MAPNIK);
}


sub get_osm_cycle_map {
	my $factory = Champlain::MapSourceFactory->dup_default();
	return $factory->create(MAP_OSM_CYCLE_MAP);
}


sub get_osm_osmarender {
	my $factory = Champlain::MapSourceFactory->dup_default();
	return $factory->create(MAP_OSM_OSMARENDER);
}


sub get_oam {
	my $factory = Champlain::MapSourceFactory->dup_default();
	return $factory->create(MAP_OAM);
}


sub get_mff_relief {
	my $factory = Champlain::MapSourceFactory->dup_default();
	return $factory->create(MAP_MFF_RELIEF);
}
