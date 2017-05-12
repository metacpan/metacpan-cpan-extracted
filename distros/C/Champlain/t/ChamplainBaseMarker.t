#!/usr/bin/perl

use strict;
use warnings;

use Clutter::TestHelper tests => 13;

use Champlain;


exit tests();


sub tests {
	my $marker = Champlain::BaseMarker->new();
	isa_ok($marker, 'Champlain::BaseMarker');

	my ($latitude, $longitude) = $marker->get('latitude', 'longitude');
	is($latitude, 0.0, "Initial latitude is at 0.0");
	is($longitude, 0.0, "Initial longitude is at 0.0");

	$marker->set_position(20.0, 40.0);
	is($marker->get_latitude, 20.0, "set_position() changed the latitude");
	is($marker->get_longitude, 40.0, "set_position() changed the longitude");

	is($marker->get_highlighted(), FALSE, "Initial highlighted is false");
	$marker->set_highlighted(TRUE);
	is($marker->get_highlighted(), TRUE, "Changed highlighted to true");
	$marker->set_highlighted(FALSE);
	is($marker->get_highlighted(), FALSE, "Changed highlighted to false");

	# Test the animations by starting them and creating an event loop. The event
	# loop will timeout after a while assuming that the animation is over.
	ok($marker->get('opacity'));
	$marker->animate_out();
	run_event_loop();
	is($marker->get('opacity'), 0, 'animate_out()');

	$marker->animate_in();
	run_event_loop();
	is($marker->get('opacity'), 255, 'animate_in()');

	$marker->animate_out_with_delay(200);
	run_event_loop();
	is($marker->get('opacity'), 0, 'animate_out_with_delay()');

	$marker->animate_in_with_delay(200);
	run_event_loop();
	is($marker->get('opacity'), 255, 'animate_in_with_delay()');

	return 0;
}


#
# Runs a main loop for the purpose of executing one animation. The main loop is
# timed in case where the test doesn't work.
#
sub run_event_loop {
	my ($view) = @_;

	# Give us a bit of time to get there since this is an animation and it
	# requires an event loop. We add an idle timeout in order to make sure that we
	# don't wait forever.
	Glib::Timeout->add(2_000, sub {
		Clutter->main_quit();
		return FALSE;
	});
	Clutter->main();
}
