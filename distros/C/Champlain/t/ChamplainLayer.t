#!/usr/bin/perl

use strict;
use warnings;

use Clutter::TestHelper tests => 12;

use Champlain;

exit tests();

sub tests {
	my $layer = Champlain::Layer->new();
	isa_ok($layer, 'Champlain::Layer');

	my $marker = Champlain::BaseMarker->new();
	is_deeply(
		[$layer->get_children],
		[],
		"No children at start"
	);
	$layer->add_marker($marker);
	is_deeply(
		[$layer->get_children],
		[$marker],
		"Layer has a marker after add_marker"
	);

	ok(!$layer->get('visible'), "Layer is not visible at start");
	$layer->show();
	ok($layer->get('visible'), "show()");
	$layer->hide();
	ok(!$layer->get('visible'), "hide()");

	# Test the animations by starting them and creating an event loop. The event
	# loop will timeout after a while assuming that the animation is over.
	ok($marker->get('opacity'));
	$layer->animate_out_all_markers();
	run_event_loop();
	is($marker->get('opacity'), 0, 'animate_out_all_markers()');

	$layer->animate_in_all_markers();
	run_event_loop();
	is($marker->get('opacity'), 255, 'animate_in_all_markers()');

	# Show/Hide the markers
	ok($marker->get('visible'), "marker is not visible");
	$layer->hide_all_markers();
	run_event_loop();
	ok(!$marker->get('visible'), "hide_all_markers()");

	$layer->show_all_markers();
	run_event_loop();
	ok($marker->get('visible'), "show_all_markers()");

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
