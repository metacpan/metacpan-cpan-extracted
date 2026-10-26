#!/usr/bin/env perl

# GET /map in a real browser, with a usable renderer and without one.
#
# t/map.t proves what the route sends back -- the warning is in the body, the
# map body is left out -- and t/browser-canvas-map-degraded.t proves the canvas
# card degrades.  Neither opens /map in a browser, so nothing has checked the
# page a reader actually gets: a note inside a hidden container, or with its
# text clipped away, would satisfy a body-string test and still leave the reader
# looking at a summary with no map and no explanation.
#
# So the page is loaded in the browser in both states, and each one checks the
# note's visibility as the browser computes it (a box, not clipped, rendered
# text), whether the map element is there, the marker summary, and that the rest
# of the page -- title and breadcrumb -- is the same in both.  The control is
# the usable-renderer state: it must not carry the warning, which is what proves
# the note assertions can fail rather than being satisfied by any page that
# mentions HTML::OSM somewhere.
#
#   AUTHOR_TESTING=1 prove -l t/browser-map-page-renderer.t
#
# It skips without AUTHOR_TESTING or without Firefox, like the other
# t/browser-*.t files.  The control is skipped on a machine without
# HTML::OSM 0.12, since that state cannot be produced there.

use strict;
use warnings;

use Test::Most;
use File::Spec ();
use File::Temp qw(tempdir);
use JSON::MaybeXS qw(decode_json);
use Mojo::File qw(path);
use Mojo::Util qw(url_escape);
use lib 't/lib';
use BI::Test::Browser qw(map_renderer_state);

BI::Test::Browser->plan_browser_tests();

# Two rows with usable coordinates and one without: the summary then reports a
# marker count and a plotted-row count that differ from the row count, so it
# cannot pass by echoing the file's size.
my $dir = tempdir(CLEANUP => 1);
my $csv = File::Spec->catfile($dir, 'places.csv');
path($csv)->spurt(
	"name,latitude,longitude\n"
	. "Alpha,51.33,1.42\n"
	. "Beta,51.92,0.75\n"
	. "Gamma,,\n"
);

# What the stand-in in the server answers with.  The real probe loads
# HTML::OSM as a side effect, so the wrapper does too when the file says the
# renderer is usable; the other two values only change the answer the
# controller gets.
my $state_file = File::Spec->catfile($dir, 'renderer-state');
path($state_file)->spurt("current\n");

my $browser = BI::Test::Browser->new(
	app_setup => map_renderer_state($state_file),
);

my $MAP  = '/map?l=' . url_escape("path:$csv") . '&lat=latitude&lon=longitude';
my $SOME = qr/Plotting 2 markers for 2 of 3 rows from columns latitude and longitude/;

sub show_page {
	my ($state) = @_;

	path($state_file)->spurt("$state\n");
	$browser->navigate($MAP);

	return $browser->wait_for(sub { $browser->find('h2.graph-title') }, timeout => 10);
}

# The map page's note about the renderer, as the browser sees it.  The page has
# other notes -- the count of rows without a coordinate is one -- so this picks
# the renderer note by its key rather than taking the first one, and reports a
# note that exists but is not on screen as a note that is not visible, not as a
# missing note.
sub renderer_note {
	my $json = $browser->js(<<'JS');
/* Wrapped in an object: JSON.stringify(null) is the bare value null, which a
   JSON backend may refuse to decode (allow_nonref) and machines disagree
   about.  An object is always decodable. */
return JSON.stringify({ note: (function () {
	var notes = Array.prototype.slice.call(document.querySelectorAll('.map-notes .map-note'));
	var note = notes.filter(function (n) {
		return (n.getAttribute('data-key') || '').indexOf('error_map_renderer_') === 0;
	})[0];
	if (!note) return null;

	var banner = note.closest('.map-notes');
	var box = note.getBoundingClientRect();
	var style = getComputedStyle(note);

	return {
		key: note.getAttribute('data-key'),
		text: (note.textContent || '').replace(/\s+/g, ' ').trim(),
		role: banner.getAttribute('role'),
		visible: box.width > 0 && box.height > 0
			&& note.offsetParent !== null
			&& style.display !== 'none'
			&& style.visibility !== 'hidden'
			&& style.opacity !== '0'
	};
})() });
JS

	return undef unless defined $json;
	return decode_json($json)->{note};
}

sub title_text {
	return $browser->js(
		"var el = document.querySelector('h2.graph-title');"
		. "return el ? el.textContent.replace(/\\s+/g, ' ').trim() : '';"
	);
}

sub summary_text {
	return $browser->js(
		"var el = document.querySelector('.map-summary');"
		. "return el ? el.textContent.replace(/\\s+/g, ' ').trim() : '';"
	);
}

# ---------------------------------------------------------------------------
# The two states the page has to survive: no renderer, and one too old for the
# options the page passes.  Both must report and draw nothing.
# ---------------------------------------------------------------------------
for my $case (
	[
		'missing' => 'error_map_renderer_missing',
		qr/HTML::OSM 0\.12 or later/, qr/not installed/,
	],
	[
		'old'     => 'error_map_renderer_old',
		qr/HTML::OSM 0\.12 or later/, qr/installed HTML::OSM is 0\.11/,
	],
) {
	my ($state, $key, $needs, $says) = @$case;

	ok show_page($state), "$state: the map page rendered";

	is title_text(), 'latitude and longitude',
		"$state: the page is titled after the columns it plots";

	my $note = renderer_note();
	ok $note, "$state: the page carries a note about the renderer";
	is $note->{key}, $key, "$state: the note is the $key one";
	like $note->{text}, $needs, "$state: the note names the version that is required";
	like $note->{text}, $says,  "$state: the note says which problem it is";

	# The point of loading the page rather than reading the body: this is the
	# browser saying the reader can see it.
	is $note->{visible}, 1, "$state: the note is visible on the page";
	is $note->{role}, 'status', "$state: the note is announced as a status";

	is $browser->js("return document.getElementById('map') ? 1 : 0;"), 0,
		"$state: no map element is drawn";
	is $browser->js("return document.querySelectorAll('.map-panel').length;"), 0,
		"$state: the empty map panel is left out rather than shown blank";

	like summary_text(), $SOME,
		"$state: the page still counts the markers it would have drawn";

	is $browser->js(
		"var el = document.querySelector('.back-link');"
		. "return el ? (/Home/.test(el.textContent) ? 1 : 0) : 0;"
	), 1, "$state: the page chrome around it is intact";

	$browser->proved(
		'GET /map with HTML::OSM ' . ($state eq 'missing' ? 'absent' : 'older than 0.12')
		. ': the renderer note is visible and announced, no map panel is drawn, and the markers are still counted'
	);
}

# ---------------------------------------------------------------------------
# The control: with a renderer this machine has, the same URL draws the map and
# has no note to make.  Without one there is nothing to compare against, so it
# is skipped rather than faked.
# ---------------------------------------------------------------------------
my $have_renderer = eval { require HTML::OSM; HTML::OSM->VERSION(0.12); 1 };

SKIP: {
	skip 'HTML::OSM 0.12 is not installed here, so there is no usable renderer to show', 6
		unless $have_renderer;

	ok show_page('current'), 'current: the map page rendered with a usable renderer';

	ok $browser->wait_for(sub { $browser->find('.map-panel #map') }, timeout => 10),
		'current: the map is drawn inside the panel';

	is $browser->js(
		"var el = document.getElementById('map');"
		. "if (!el) return 0;"
		. "var box = el.getBoundingClientRect();"
		. "return box.width > 0 && box.height > 0 ? 1 : 0;"
	), 1, 'current: the map element has a size, so it is on the page';

	is renderer_note(), undef, 'current: there is no note about the renderer';

	like summary_text(), $SOME,
		'current: the page counts the same markers as the degraded state';

	is title_text(), 'latitude and longitude',
		'current: the title is the same as the degraded state';

	$browser->proved(
		'GET /map with a usable renderer: the map is drawn inside the panel and has a size, there is no renderer note, and the same markers are counted'
	);
}

done_testing();
