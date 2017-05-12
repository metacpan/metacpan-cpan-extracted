#!/usr/bin/perl

#
# Custom marker that's animated and drawn through Cairo. The marker is composed
# of 1 static filled circle and 1 stroked circle animated as an echo.
#
package Champain::Ex::AnimatedMarker;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Clutter;
use Champlain;
use Math::Trig ':pi';

my $MARKER_SIZE = 10;

#
# In order to have the marker animated the timeline and the behaviours must live
# long enough for the code to use them. One way to do this is to keep the
# references to this objects as global variables (it's uggly but it works).
#
# Another way it so create a base class of Marker and to keep this timeline and
# the behaviours associated with the marker. This approach is implemented here.
#
use Glib::Object::Subclass 'Champlain::BaseMarker' =>
	properties => [
		
		# The timeline controlling the animation
		Glib::ParamSpec->object(
			'timeline', 
			'Timeline',
			'Timeline controling the animation',
			'Clutter::Timeline',
			[ qw(readable writable) ],
		),
		
		# The opacity change in the echo
		Glib::ParamSpec->object(
			'behaviour-opacity', 
			'Behaviour Opacity',
			'Behaviour controling the opacity of the marker',
			'Clutter::Behaviour::Opacity',
			[ qw(readable writable) ],
		),
		
		# The growing of the echo
		Glib::ParamSpec->object(
			'behaviour-zoom', 
			'Behaviour Zoom',
			'Behaviour controling the zoom of the marker',
			'Clutter::Behaviour::Scale',
			[ qw(readable writable) ],
		),
	],
;


# Constructor
sub INIT_INSTANCE {
	my $self = shift;
	
	# The middle dot	
	my $circle = create_static_circle();
	$self->add($circle);

	# The echo ring
	my $echo_circle = create_echo_circle();
	$self->add($echo_circle);

	# Animate the echo ring
	$self->create_animation($echo_circle);
}


sub create_animation {
	my $self = shift;
	my ($texture) = @_;
	
	# Timeline controlling the animation
	my $timeline = Clutter::Timeline->new(1000);
	$self->set(timeline => $timeline);
	$timeline->set_loop(TRUE);
	my $alpha = Clutter::Alpha->new($timeline, 'ease-in-sine');
	
	# Circle's echo growing
	my $behaviour_zoom = Clutter::Behaviour::Scale->new($alpha, 0.5, 0.5, 2.0, 2.0);
	$self->set(behaviour_zoom => $behaviour_zoom);
	$behaviour_zoom->apply($texture);
	
	# Circle's echo fading
	my $behaviour_opacity = Clutter::Behaviour::Opacity->new($alpha, 255, 0);
	$self->set(behaviour_opacity => $behaviour_opacity);
	$behaviour_opacity->apply($texture);
	$timeline->start();
}


sub create_static_circle {
	my $texture = Clutter::CairoTexture->new($MARKER_SIZE, $MARKER_SIZE);
	my $cr = $texture->create_context();
	
	# Draw the circle
	$cr->set_source_rgb(0, 0, 0);
	$cr->arc($MARKER_SIZE/2, $MARKER_SIZE/2, $MARKER_SIZE/2, 0, pi2);
	$cr->close_path();

	# Fill the circle
	$cr->set_source_rgba(0.1, 0.1, 0.9, 1.0);
	$cr->fill();
	
	$texture->set_anchor_point_from_gravity('center');
	$texture->set_position(0, 0);

	return $texture;
}


sub create_echo_circle {
	my $texture = Clutter::CairoTexture->new($MARKER_SIZE * 2, $MARKER_SIZE * 2);
	my $cr = $texture->create_context();
	
	# Draw the circle
	$cr->set_source_rgb(0, 0, 0);
	$cr->arc($MARKER_SIZE, $MARKER_SIZE, $MARKER_SIZE * 0.9, 0, pi2);
	$cr->close_path();

	# Stroke the circle
	$cr->set_line_width(2.0);
	$cr->set_source_rgba(0.1, 0.1, 0.7, 1.0);
	$cr->stroke();

	$texture->set_anchor_point_from_gravity('center');
	$texture->set_position(0, 0);
	
	return $texture;
}



package main;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Clutter qw(-threads-init -init);
use Champlain;


exit main();


sub main {
	
	my $stage = Clutter::Stage->get_default();
	$stage->set_size(800, 600);
	
	# Create the map view
	my $map = Champlain::View->new();
	$map->set_size($stage->get_size);
	$stage->add($map);
	
	
	# Create the marker layer
	my $layer = Champlain::Layer->new();
	$map->add_layer($layer);
	
	# Create the marker
	my $marker = Champain::Ex::AnimatedMarker->new();
	$marker->set_position(45.528178, -73.563788); # Montreal, Canada
	$layer->add($marker);
	
	
	# Finish initializing the map view
	$map->set_property("zoom-level", 5);
	$map->set_property("scroll-mode", 'kinetic');
	$map->center_on(45.466, -73.75);
	

	$stage->show_all();
	
	Clutter->main();
	
	return 0;
}
