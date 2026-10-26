#!/usr/bin/env perl

# A canvas map card when HTML::OSM is missing or older than 0.12.
#
# t/map.t covers both states for GET /map, and a canvas draws its map cards
# through the same _map_data.  This is the page a reader actually sees: the
# card has to carry the note, the note has to be visible on the page, the
# marker count has to survive, nothing may be drawn, and the other card on the
# canvas has to be untouched.
#
# One browser session shows all three states.  map_renderer_state replaces
# _map_renderer_version in the server child with a wrapper that reads a file
# this test writes before each navigation, so "missing" and "too old" are
# produced without installing or removing HTML::OSM - the same reason t/map.t
# replaces the method in-process.  t/browser-map-page-renderer.t does the same
# for the GET /map page through the same helper.
#
#   AUTHOR_TESTING=1 prove -l t/browser-canvas-map-degraded.t
#
# It skips without AUTHOR_TESTING or without Firefox, like the other
# t/browser-*.t files.

use strict;
use warnings;

use Test::Most;
use File::Spec ();
use File::Temp qw(tempdir);
use JSON::MaybeXS qw(encode_json decode_json);
use Mojo::File qw(path);
use lib 't/lib';
use BI::Test::Browser qw(map_renderer_state);

BI::Test::Browser->plan_browser_tests();

# Two rows with coordinates and one without, so the card has both a marker
# count and a row that was left out of it: the degraded card must report what
# it would have drawn.
my $dir = tempdir(CLEANUP => 1);
my $csv = File::Spec->catfile($dir, 'places.csv');
path($csv)->spurt(
	"name,latitude,longitude\n"
	. "Alpha,51.33,1.42\n"
	. "Beta,51.92,0.75\n"
	. "Gamma,,\n"
);

# What the wrapper in the server answers with.  'current' is a usable
# renderer, which needs the real module; the other two only change the answer
# the controller gets.
my $state_file = File::Spec->catfile($dir, 'renderer-state');
path($state_file)->spurt("current\n");

my $browser = BI::Test::Browser->new(
	app_setup => map_renderer_state($state_file),
);

my $BASE = $browser->base;
my $ua   = $browser->ua;

# ---------------------------------------------------------------------------
# One canvas: a map card and a table card beside it.  The table card is what
# proves the degraded map card does not take the page with it.
# ---------------------------------------------------------------------------
my $created = $ua->post(
	"$BASE/api/analyses" => { 'Content-Type' => 'application/json' } => encode_json({
		name     => 'Renderer states',
		datasets => [ { spec => "path:$csv", alias => 'left' } ],
		visuals  => [
			{
				kind   => 'map',
				encode => { lat => 'latitude', lon => 'longitude' },
				title  => 'Map card',
			},
			{ kind => 'table', encode => {}, title => 'Table card' },
		],
	})
);
is $created->res->code, 201, 'the canvas was saved';
my $id = $created->res->json('/id');
ok $id, 'the canvas has an id' or BAIL_OUT('no canvas id');

sub show_state {
	my ($state) = @_;

	path($state_file)->spurt("$state\n");
	$browser->navigate("/a/$id");

	return $browser->wait_for(sub { $browser->find('#visual-0') }, timeout => 10);
}

# The map card's note about the renderer, as the browser sees it: which note it
# is, what it says, and whether it is on the page rather than merely in the
# markup.  A note that is hidden, collapsed or transparent fails the same way
# as a missing one.  The card has other notes - the count of rows without a
# coordinate is one - so this looks for the renderer note rather than the
# first one.
sub note_on_card {
	my $json = $browser->js(<<'JS');
/* Wrapped in an object: JSON.stringify(null) is the bare value null, which a
   JSON backend may refuse to decode (allow_nonref) and machines disagree
   about.  An object is always decodable. */
return JSON.stringify({ note: (function () {
	var card = document.getElementById('visual-0');
	if (!card) return null;

	var notes = Array.prototype.slice.call(card.querySelectorAll('.map-notes .map-note'));
	var note = notes.filter(function (n) {
		return (n.getAttribute('data-key') || '').indexOf('error_map_renderer_') === 0;
	})[0];
	if (!note) return null;

	var banner = note.closest('.map-notes');

	var box = note.getBoundingClientRect();
	var style = getComputedStyle(note);

	return {
		key: note.getAttribute('data-key'),
		text: note.textContent,
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

sub summary_on_card {
	return $browser->js(
		"var el = document.querySelector('#visual-0 .map-summary');"
		. "return el ? el.textContent : '';"
	);
}

# ---------------------------------------------------------------------------
# The two states the report is about.
# ---------------------------------------------------------------------------
for my $case (
	[
		'missing'                => 'error_map_renderer_missing',
		qr/HTML::OSM 0\.12 or later/, qr/not installed/,
	],
	[
		'old'                    => 'error_map_renderer_old',
		qr/HTML::OSM 0\.12 or later/, qr/installed HTML::OSM is 0\.11/,
	],
) {
	my ($state, $key, $needs, $says) = @$case;

	ok show_state($state), "$state: the canvas rendered";

	my $note = note_on_card();
	ok $note, "$state: the map card carries a note";
	is $note->{key}, $key, "$state: the note is the $key one";

	like $note->{text}, $needs, "$state: the note names the version that is required";
	like $note->{text}, $says,  "$state: the note says which problem it is";

	is $note->{visible}, 1, "$state: the note is visible on the page";
	is $note->{role}, 'status', "$state: the note is announced as a status";

	is $browser->js("return document.getElementById('map-0') ? 1 : 0;"), 0,
		"$state: no map is drawn on the card";

	like summary_on_card(), qr/Plotting 2 markers for 2 of 3 rows/,
		"$state: the card still counts the markers it would have drawn";

	is $browser->js(
		"var el = document.querySelector('#visual-1 td');"
		. "return el ? el.textContent : '';"
	), 'Alpha', "$state: the table card beside it still shows its rows";

	$browser->proved(
		"canvas /a/$id with HTML::OSM " . ($state eq 'missing' ? 'absent' : 'older than 0.12')
		. ': the map card carries the visible note and draws nothing, and the table card beside it keeps its rows'
	);
}

# ---------------------------------------------------------------------------
# The control: with a renderer this machine has, the same card draws the map
# and has no note to make.  Without one there is nothing to compare against,
# so the control is skipped rather than faked.
# ---------------------------------------------------------------------------
my $have_renderer = eval { require HTML::OSM; HTML::OSM->VERSION(0.12); 1 };

SKIP: {
	skip 'HTML::OSM 0.12 is not installed here, so there is no usable renderer to show', 4
		unless $have_renderer;

	ok show_state('current'), 'current: the canvas rendered with a usable renderer';
	ok $browser->wait_for(sub { $browser->find('#map-0') }, timeout => 10),
		'current: the map card draws its Leaflet element';
	is note_on_card(), undef, 'current: there is no note on the card';
	like summary_on_card(), qr/Plotting 2 markers for 2 of 3 rows/,
		'current: the card counts the same markers';

	$browser->proved(
		"canvas /a/$id with a usable renderer: the map card draws its Leaflet element, has no note, and counts the same markers"
	);
}

done_testing();
