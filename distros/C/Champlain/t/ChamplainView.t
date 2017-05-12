#!/usr/bin/perl

use strict;
use warnings;

use Clutter::TestHelper tests => 87;

use Champlain ':coords';


exit tests();


sub tests {
	my $stage = Clutter::Stage->get_default();
	$stage->set_size(400, 400);

	test_go_to();
	test_ensure_visible();
	test_ensure_markers_visible();
	test_generic();
	test_zoom();
	test_event();
	test_polygons();
	return 0;
}


#
# Test some default functionality.
#
sub test_generic {
	my $view = Champlain::View->new();
	isa_ok($view, 'Champlain::View');
	
	# center_on() can be tested by checking the properties latitude and longitude.
	# And even then, the values set are not the ones returned
	my $latitude = $view->get('latitude');
	my $longitude = $view->get('longitude');
	$view->center_on(48.144722, 17.112778);
	ok($view->get('latitude') != $latitude, "center_on() changed latitude");
	ok($view->get('longitude') != $longitude, "center_on() changed longitude");
	
	$view->set_size(600, 400);
	ok($view->get('width') >= 600, "set_size() changed width");
	ok($view->get('height') >=  400, "set_size() changed height");

	
	# Can't be tested but at least we check that it doesn't crash when invoked
	my $layer = Champlain::Layer->new();
	$view->add_layer($layer);
	$view->remove_layer($layer);
	
	# Change the map source (get a different map source)
	my $factory = Champlain::MapSourceFactory->dup_default();
	my $source_new = $factory->create(Champlain::MapSourceFactory->OSM_MAPNIK);
	my $source_original = $view->get('map-source');
	if ($source_original->get_id eq $source_new->get_id) {
		# The new map source is the same as the original! Take another map
		# source instead
		$source_new = $factory->create(Champlain::MapSourceFactory->OSM_OSMARENDER);
	}
	$view->set_map_source($source_new);
	is($view->get('map-source'), $source_new, "set_map_source()");
	is($view->get_map_source, $source_new, "get_map_source()");

	
	# Change the decel rate
	$view->set_decel_rate(1.2);
	is($view->get('decel-rate'), 1.2, "set_decel_rate()");
	$view->set_decel_rate(1.5);
	is($view->get('decel-rate'), 1.5, "set_decel_rate()");
	is($view->get_decel_rate, 1.5, "get_decel_rate()");

	
	# Change the scroll mode
	$view->set_scroll_mode('push');
	is($view->get('scroll-mode'), 'push', "set_scroll_mode('push')");
	$view->set_scroll_mode('kinetic');
	is($view->get('scroll-mode'), 'kinetic', "set_scroll_mode('kinetic')");
	is($view->get_scroll_mode, 'kinetic', "get_scroll_mode()");

	
	# Change the show license property
	$view->set_show_license(TRUE);
	ok($view->get('show-license'), "set_show_license(TRUE)");
	$view->set_show_license(FALSE);
	ok(!$view->get('show-license'), "set_show_license(FALSE)");
	ok(!$view->get_show_license, "get_show_license");
	
	
	# Change the set zoom on double click property
	$view->set_zoom_on_double_click(TRUE);
	ok($view->get('zoom-on-double-click'), "set_zoom_on_double_click(TRUE)");
	$view->set_zoom_on_double_click(FALSE);
	ok(!$view->get('zoom-on-double-click'), "set_zoom_on_double_click(FALSE)");
	ok(!$view->get_zoom_on_double_click, "get_zoom_on_double_click()");
	
	
	# Change the keep center on resize property
	$view->set_keep_center_on_resize(TRUE);
	ok($view->get('keep-center-on-resize'), "set_keep_center_on_resize(TRUE)");
	$view->set_keep_center_on_resize(FALSE);
	ok(!$view->get('keep-center-on-resize'), "set_keep_center_on_resize(FALSE)");
	ok(!$view->get_keep_center_on_resize, "get_keep_center_on_resize()");
	
	
	# Call ensure_visible(), it's hard to test, but at least we check that it doesn't crash
	$view->ensure_visible(10, 10, 30, 30, TRUE);


	$view->set_license_text("Perl Universal License");
	is($view->get_license_text, "Perl Universal License", "set_license_text(text)");

	$view->set_license_text(undef);
	is($view->get_license_text, undef, "set_license_text(undef)");


	$view->set_max_scale_width(200);
	is($view->get_max_scale_width, 200, "set_max_scale_width(200)");

	$view->set_max_scale_width(400);
	is($view->get_max_scale_width, 400, "set_max_scale_width(400)");


	$view->set_scale_unit('miles');
	is($view->get_scale_unit, 'miles', "set_max_scale_width('miles')");

	$view->set_scale_unit('km');
	is($view->get_scale_unit, 'km', "set_max_scale_width('km')");


	$view->set_show_scale(TRUE);
	is($view->get_show_scale, TRUE, "set_show_scale(TRUE)");

	$view->set_show_scale(FALSE);
	is($view->get_show_scale, FALSE, "set_show_scale(FALSE)");
}


#
# Test the zoom functionality.
#
sub test_zoom {
	my $view = Champlain::View->new();
	isa_ok($view, 'Champlain::View');
	
	
	# Zoom in
	is($view->get('zoom-level'), 0, "original zoom-level");
	$view->zoom_in();
	is($view->get('zoom-level'), 1, "zoom-in once");
	$view->zoom_in();
	is($view->get('zoom-level'), 2, "zoom-in twice");
	
	# Zoom out
	$view->zoom_out();
	is($view->get('zoom-level'), 1, "zoom-out once");
	$view->zoom_out();
	is($view->get('zoom-level'), 0, "zoom-out twice");
	
	my $map_source = $view->get('map-source');
	
	# Zoom out past the min zoom level
	my $min = $map_source->get_min_zoom_level;
	$view->set_zoom_level($min);
	is($view->get('zoom-level'), $min, "zoom-out to the minimal level");
	is($view->get_zoom_level, $min, "get_zoom_level()");

	$view->set("zoom-level", $min);
	is($view->get('zoom-level'), $min, "set('zoom-level') to the minimal level");

	$view->zoom_out();
	is($view->get('zoom-level'), $min, "zoom-out past minimal level has no effect");
	
	
	# Zoom in after the max zoom level
	my $max = $map_source->get_max_zoom_level;
	$view->set_zoom_level($max);
	is($view->get('zoom-level'), $max, "zoom-in to the maximal level");

	$view->set("zoom-level", $max);
	is($view->get('zoom-level'), $max, "set('zoom-level') to the maximal level");

	$view->zoom_in();
	is($view->get('zoom-level'), $max, "zoom-in past maximal level has no effect");
	
	# Go to the middle zoom level
	my $middle = int( ($max - $min) / 2 );
	$view->set_zoom_level($middle);
	is($view->get('zoom-level'), $middle, "set zoom to the middle level");

	$view->set("zoom-level", $middle);
	is($view->get('zoom-level'), $middle, "set('zoom-level', (max-min)/2) to the middle level");
	
	
	# Try to set directly the zoom level to a value inferior to min level
	$view->set_zoom_level($min - 1);
	is($view->get('zoom-level'), $middle, "set zoom (min - 1) has no effect");

	# NOTE: This gives a warning because -1 out of range for property `zoom-level'
	#$view->set("zoom-level", $min - 1);
	#is($view->get('zoom-level'), $middle, "set('zoom-level', min - 1) has no effect");
	
	# Try to set directly the zoom level to a valu superior to max level
	$view->set_zoom_level($max + 1);
	is($view->get('zoom-level'), $middle, "set zoom (max + 1) has no effect");

	$view->set("zoom-level", $max + 1);
	is($view->get('zoom-level'), $middle, "set('zoom-level', max + 1) has no effect");

	
	# Limit the application's zoom levels
	$view->set_zoom_level(1);
	is($view->get('zoom-level'), 1, "set('zoom-level', 1)");
	is($view->get('min-zoom-level'), $min, "defaullt min-zoom-level");
	is($view->get_min_zoom_level, $min, "get_min_zoom_level()");
	$view->set_min_zoom_level(3);
	is($view->get('min-zoom-level'), 3, "set_min_zoom_level(3)");
	is($view->get('zoom-level'), 3, "zoom-level level is 3 after setting min-zoom-level to 3");
	
	$view->set_zoom_level(6);
	is($view->get('zoom-level'), 6, "set('zoom-level', 6)");
	is($view->get('max-zoom-level'), $max, "defaullt max-zoom-level");
	is($view->get_max_zoom_level, $max, "get_max_zoom_level()");
	$view->set_max_zoom_level(4);
	is($view->get('max-zoom-level'), 4, "set_mx_zoom_level(4)");
	is($view->get('zoom-level'), 4, "zoom-level level is 4 after setting min-zoom-level to 4");
}


#
# Test getting the coordinates from an event.
#
# This tests simulates that the user clicked at the coordinate (0, 0) (where
# Greenwich meets the Equator). In order to simulate this, the test sets the
# view to be as big as the first tile and will simulate a click in the middle of
# the tile. Because the computations are made with a projection a slight error
# threshold will be accepted.
#
sub test_event {
	my $view = Champlain::View->new();
	isa_ok($view, 'Champlain::View');
	
	my $map_source = $view->get('map-source');
	my $size = $map_source->get_tile_size;
	ok($size > 0, "Tile has a decent size");
	
	# NOTE: At the moment this works only if the view is in a stage and if
	# show_all() was called
	my $stage = Clutter::Stage->get_default();
	$stage->remove_all();
	$view->set_size($size, $size);
	$view->center_on(0, 0);
	$stage->add($view);
	$stage->show_all();
	
	# Create a fake event in the middle of the tile
	my $event = Clutter::Event->new('button_press');
	my $middle = int($size/2);
	$event->x($middle);
	$event->y($middle);
	is($event->x, $middle, "Fake event is in the middle (x)");
	is($event->y, $middle, "Fake event is in the middle (y)");

	my ($latitude, $longitude) = $view->get_coords_from_event($event);
	ok($latitude >= -2.0 && $latitude <= 2.0, "get_coords_from_event() latitude ($latitude)");
	ok($longitude >= -2.0 && $longitude <= 2.0, "get_coords_from_event() longitude ($longitude)");

	($latitude, $longitude) = $view->get_coords_at($event->x, $event->y);
	ok($latitude >= -2.0 && $latitude <= 2.0, "get_coords_at() latitude ($latitude)");
	ok($longitude >= -2.0 && $longitude <= 2.0, "get_coords_at() longitude ($longitude)");
}


#
# Test going to a different location with go_to().
#
sub test_go_to {
	my $view = Champlain::View->new();
	isa_ok($view, 'Champlain::View');

	my $stage = Clutter::Stage->get_default();
	$stage->remove_all();
	$view->set_size($stage->get_size);
	$stage->add($view);
	$stage->show_all();

	# Set a proper zoom-level otherwise the test will fail because we would be
	# zoomed in Antartica.
	$view->set_property("zoom-level", 4);

	# Place the view in the center
	$view->center_on(0, 0);
	is($view->get('latitude'), 0, "center_on() reset latitude");
	is($view->get('longitude'), 0, "center_on() reset longitude");
	
	
	# Go to a different place
	my ($latitude, $longitude) = (48.218611, 17.146397);
	run_animation_loop($view, sub { $view->go_to($latitude, $longitude); });
	
	# Check if we got somewhere close to desired location
	is_view_near($view, $latitude, $longitude);
	
	# Replace the view in the center
	$view->center_on(0, 0);
	is($view->get('latitude'), 0, "center_on() reset latitude");
	is($view->get('longitude'), 0, "center_on() reset longitude");
	
	# Go to a different place. This is too fast and can't be tested properly.
	$view->go_to($latitude, $longitude);
	my $stop_called;
	$view->signal_connect('animation-completed::go-to', sub { $stop_called = 1 });
	run_animation_loop($view, sub { Glib::Idle->add(sub {$view->stop_go_to()}); });
	ok($stop_called, "stop_go_to called");
}


#
# Test the polygons
#
sub test_polygons {
	my $view = Champlain::View->new();
	isa_ok($view, 'Champlain::View');

	my $line = Champlain::Polygon->new();
	my $triangle = Champlain::Polygon->new();
	my $square = Champlain::Polygon->new();
	
	# Note these can't be tested as the API provides no way for querying the polygons
	$view->add_polygon($line);
	$view->add_polygon($triangle);
	$view->add_polygon($square);
	
	$view->remove_polygon($line);
	$view->remove_polygon($square);
}


#
# Test ensure_visible().
#
sub test_ensure_visible {
	my $view = Champlain::View->new();
	isa_ok($view, 'Champlain::View');

	# Place the view in the center and zoomed
	$view->center_on(0, 0);
	$view->set_zoom_level(6);
	is($view->get('latitude'), 0);
	is($view->get('longitude'), 0);
	is($view->get('zoom-level'), 6);

	# Ensure that 2 points are visible
	my (@marker1) = (48.218611, 17.146397);
	my (@marker2) = (48.21066, 16.31476);

	run_animation_loop($view, sub {
		# Must start the animations from the event loop
		Glib::Idle->add(sub {
			diag("Start ensure visible");
			$view->ensure_visible(@marker1, @marker2, TRUE);
			return FALSE;
		});
	});
	
	# Check if we got somewhere close to the middle of the markers
	my $middle_latitude = ($marker1[0] + $marker2[0]) / 2;
	my $middle_longitude = ($marker1[1] + $marker2[1]) / 2;
	is_view_near($view, $middle_latitude, $middle_longitude);
}


#
# Test ensure_markers_visible().
#
sub test_ensure_markers_visible {

	# Must add the view to a stage and give a size for this test
	my $stage = Clutter::Stage->get_default();
	$stage->remove_all();

	my $view = Champlain::View->new();
	isa_ok($view, 'Champlain::View');

	$stage->add($view);
	$view->set_size($stage->get_size);


	# Place the view in the center and zoomed
	$view->center_on(0, 0);
	$view->set_zoom_level(6);
	is($view->get('latitude'), 0);
	is($view->get('longitude'), 0);
	is($view->get('zoom-level'), 6);

	# Ensure that some markers are visible
	my @markers = (
		create_marker('A', 48.218611, 17.146397),
		create_marker('B', 48.14838,  17.10791),
		create_marker('C', 48.21066,  16.31476),
	);
	
	my $layer = Champlain::Layer->new();
	foreach my $marker (@markers) {
		$layer->add($marker);
	}
	$view->add_layer($layer);

	# Must display the stage otherwise the test will fail
	$stage->show_all();
	$stage->hide_all();

	run_animation_loop($view, sub { $view->ensure_markers_visible(\@markers, TRUE); });
	
	# Check if we got somewhere close to the middle of the markers
	is_view_near($view, 48.0, 16.5, 5.0);
}


#
# Test if the view is near the given (latitude, longitude). This function checks
# if the cordinate is close to the given point by accepting an error margin. If
# no margin is given then one degree is assumed.
#
sub is_view_near {
	my ($view, $latitude, $longitude, $delta) = @_;
	$delta = 1.0 unless defined $delta;
	
	# Check if the view is close to the given position
	my ($current_latitude, $current_longitude) = $view->get('latitude', 'longitude');
	my $delta_latitude = $current_latitude - $latitude;
	my $delta_longitude = $current_longitude - $longitude;
	my $tester = Test::Builder->new();
	$tester->ok(
		$delta_latitude >= -$delta && $delta_latitude <= $delta,
		"ensure_visible() changed latitude close enough (delta: $delta_latitude; +/-$delta; $current_latitude ~ $latitude)"
	);

	$tester->ok(
		$delta_longitude >= -$delta && $delta_longitude <= $delta,
		"ensure_visible() changed longitude close enough (delta: $delta_longitude; +/-$delta; $current_longitude ~ $longitude)"
	);
}


sub create_marker {
	my ($label, $latitude, $longitude) = @_;
	my $marker = Champlain::Marker->new_with_text($label);
	$marker->set_position($latitude, $longitude);
	return $marker;
}


#
# Runs a main loop for the purpose of executing one animation. The main loop is
# timed in case where the test doesn't work.
#
sub run_animation_loop {
	my ($view, $code) = @_;

	my $stage = $view->get_stage;
	if (!$stage) {
		$stage = Clutter::Stage->get_default();
		$stage->remove_all();
		$stage->add($view);
		$view->set_size($stage->get_size);
	}
	$stage->show_all();
	$stage->hide_all() unless @ARGV;

	$code->();

	# Give us a bit of time to get there since this is an animation and it
	# requires an event loop. We add an idle timeout in order to make sure that
	# we don't wait forever.
	$view->signal_connect('animation-completed' => sub {
		Clutter->main_quit();
	});
	Glib::Timeout->add(10_000, sub {
		diag("Event loop timeout, perhaps the animation needs more time?");
		Clutter->main_quit();
		return FALSE;
	});
	Clutter->main();
}
