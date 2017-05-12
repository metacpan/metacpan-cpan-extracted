#!/usr/bin/perl

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Clutter qw(-threads-init -init);
use Champlain;
use FindBin;
use File::Spec;


my $PADDING = 10;


exit main();


sub main {
	
	my $stage = Clutter::Stage->get_default();
	$stage->set_size(800, 600);
	
	# Create the map view
	my $map = Champlain::View->new();
	$map->set_scroll_mode('kinetic');
	$map->set_size($stage->get_size);
	$stage->add($map);
	
	# Create the zoom buttons
	my $buttons = Clutter::Group->new();
	$buttons->set_position($PADDING, $PADDING);
	$stage->add($buttons);
	
	my $button = make_button("Zoom in", sub {
		$map->zoom_in();
	});
	$buttons->add($button);
	my ($width) = $button->get_size();
	
	$button = make_button("Zoom out", sub {
		$map->zoom_out();
	});
	$buttons->add($button);
	$button->set_position($width + $PADDING, 0);
	
	
	# Create the markers and marker layer
	my $layer = create_marker_layer($map);
	$map->add_layer($layer);
	
	# Finish initializing the map view
	$map->set_property("zoom-level", 5);
	$map->center_on(45.466, -73.75);
	
	# Middle click to get the location in the map
	$map->set_reactive(TRUE);
	$map->signal_connect_after("button-release-event", \&map_view_button_release_cb, $map);

	$stage->show_all();
	
	Clutter->main();
	
	return 0;
}


#
# Creates a button and registers the given callback. The callback will be called
# each time that the button is clicked.
#
sub make_button {
	my ($text, $callback) = @_;

	my $button = Clutter::Group->new();

	my $white = Clutter::Color->new(0xff, 0xff, 0xff, 0xff);
	my $button_bg = Clutter::Rectangle->new($white);
	$button->add($button_bg);
	$button_bg->set_opacity(0xcc);

	my $black = Clutter::Color->new(0x00, 0x00, 0x00, 0xff);
	my $button_text = Clutter::Text->new("Sans 10", $text, $black);
	$button->add($button_text);
	my ($width, $height) = $button_text->get_size();

	$button_bg->set_size($width + $PADDING * 2, $height + $PADDING * 2);
	$button_bg->set_position(0, 0);
	$button_text->set_position($PADDING, $PADDING);
	
	
	$button->set_reactive(TRUE);
	$button->signal_connect('button-release-event', $callback);

	return $button;
}


sub create_marker_layer {
	my ($map) = @_;
	my $layer = Champlain::SelectionLayer->new();

	my $orange = Clutter::Color->new(0xf3, 0x94, 0x07, 0xbb);
	my $white = Clutter::Color->new(0xff, 0xff, 0xff, 0xff);
	
	my $marker;
	
	$marker = Champlain::Marker->new_with_text("Montr\x{e9}al", "Airmole 14");
	$marker->set_position(45.528178, -73.563788);
	$marker->set_reactive(TRUE);
	$marker->signal_connect_after("button-release-event", \&marker_button_release_cb, $map);
	$layer->add($marker);

	$marker = Champlain::Marker->new_with_text("New York", "Sans 15", $white);
	$marker->set_position(40.77, -73.98);
	$layer->add($marker);

	my $file = File::Spec->catfile($FindBin::Bin, 'images', 'who.png');
	eval {
		$marker = Champlain::Marker->new_from_file($file);
		$marker->set_position(47.130885, -70.764141);
		$layer->add($marker);
	};
	if (my $error = $@) {
		warn "Failed to load image $file because $error";
	}

	$layer->show();
	return $layer;
}


sub marker_button_release_cb {
	my ($marker, $event, $map) = @_;
	return FALSE unless $event->button == 1 && $event->click_count == 1;

	print "Montreal was clicked\n";
	return TRUE;
}


sub map_view_button_release_cb {
	my ($actor, $event, $map) = @_;
	return FALSE unless $event->button == 2 && $event->click_count == 1;

	my ($lat, $lon) = $map->get_coords_from_event($event);
	printf "Map was clicked at %f, %f\n", $lat, $lon;
	return TRUE;
}

