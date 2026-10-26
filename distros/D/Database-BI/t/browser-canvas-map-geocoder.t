#!/usr/bin/env perl

# A canvas map card that plots places, when Geo::Coder::Free is missing or
# older than the floor the application asks for.
#
# t/browser-canvas-map-degraded.t does this for the other optional module, the
# map renderer's HTML::OSM; t/browser-map-geocoder.t does it for the GET /map
# page.  This is the combination neither covers: a card on a canvas that has to
# geocode its column, on a machine where the geocoder cannot do it.  The card
# has to carry the note, the note has to be visible on the page, nothing may be
# drawn, and the map card beside it - the same file plotted by coordinate -
# must be untouched, which is also the control that makes the absence
# assertions able to fail rather than being satisfied by any page that mentions
# Geo::Coder::Free.
#
# One browser session shows both states.  geocoder_state replaces the model's
# _load_geocoder in the server child with a wrapper that reads a file this test
# writes before each navigation, so "missing" and "too old" are produced
# without installing, downgrading or removing the module.
#
#   AUTHOR_TESTING=1 prove -l t/browser-canvas-map-geocoder.t
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
use BI::Test::Browser qw(geocoder_state);

BI::Test::Browser->plan_browser_tests();

# Three rows: two with both a place and a coordinate, one with neither.  The
# place card therefore has nothing it could plot without a geocoder, while the
# coordinate card beside it has two markers and a row it left out - so the two
# cards differ in what they contain, not only in their encoding.
my $dir = tempdir(CLEANUP => 1);
my $csv = File::Spec->catfile($dir, 'places.csv');
path($csv)->spurt(
	"name,city,latitude,longitude\n"
	. "Alpha,Ramsgate,51.33,1.42\n"
	. "Beta,Dover,51.13,1.31\n"
	. "Gamma,,,\n"
);

# What the stand-in in the server answers with.  The file decides, so the same
# server and the same canvas show every state.
my $state_file = File::Spec->catfile($dir, 'geocoder-state');
path($state_file)->spurt("missing\n");

my $browser = BI::Test::Browser->new(
	app_setup => geocoder_state($state_file),
);

my $BASE = $browser->base;
my $ua   = $browser->ua;

# ---------------------------------------------------------------------------
# One canvas with the card under test and its control: card 0 asks the
# geocoder for the city column, card 1 plots the coordinates already in the
# file and never asks it anything.
# ---------------------------------------------------------------------------
my $created = $ua->post(
	"$BASE/api/analyses" => { 'Content-Type' => 'application/json' } => encode_json({
		name     => 'Geocoder states',
		datasets => [ { spec => "path:$csv", alias => 'left' } ],
		visuals  => [
			{
				kind   => 'map',
				encode => { loc => 'city' },
				title  => 'Place card',
			},
			{
				kind   => 'map',
				encode => { lat => 'latitude', lon => 'longitude' },
				title  => 'Coordinate card',
			},
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

# The notes on one card, by key.  Reading the card rather than the page matters
# here: the page has a second map card with notes of its own, and a note
# rendered into the wrong card, or into a hidden list, would satisfy a page
# level check.
sub note_keys_on_card {
	my ($index) = @_;

	my $keys = $browser->js(
		"var card = document.getElementById('visual-$index');"
		. "if (!card) return null;"
		. "var notes = card.querySelectorAll('.map-notes .map-note');"
		. "return Array.prototype.map.call(notes, function (n) {"
		. "  return n.getAttribute('data-key') || ''; }).join('|');"
	);

	return $keys;
}

# The geocoder note on one card, as the browser sees it: which note it is, what
# it says, and whether it is on the page rather than merely in the markup.  A
# note that is hidden, collapsed or transparent fails the same way as a missing
# one.
sub geocoder_note_on_card {
	my ($index) = @_;

	my $json = $browser->js(<<JS);
/* Wrapped in an object: JSON.stringify(null) is the bare value null, which a
   JSON backend may refuse to decode (allow_nonref) and machines disagree
   about.  An object is always decodable. */
return JSON.stringify({ note: (function () {
	var card = document.getElementById('visual-$index');
	if (!card) return null;

	var notes = Array.prototype.slice.call(card.querySelectorAll('.map-notes .map-note'));
	var note = notes.filter(function (n) {
		return (n.getAttribute('data-key') || '').indexOf('error_map_geocoder_') === 0;
	})[0];
	if (!note) return null;

	var banner = note.closest('.map-notes');
	var box = note.getBoundingClientRect();
	var style = getComputedStyle(note);

	return {
		key: note.getAttribute('data-key'),
		text: (note.textContent || '').replace(/\\s+/g, ' ').trim(),
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
	my ($index) = @_;

	return $browser->js(
		"var el = document.querySelector('#visual-$index .map-summary');"
		. "return el ? el.textContent.replace(/\\s+/g, ' ').trim() : '';"
	);
}

# ---------------------------------------------------------------------------
# The two states the card has to report: no geocoder, and one below the floor.
# Neither can plot a place, and both say so on the card itself.
# ---------------------------------------------------------------------------
for my $case (
	[
		'missing' => 'error_map_geocoder_missing',
		qr/Geo::Coder::Free 0\.48 or later/, qr/not installed/,
	],
	[
		'old'     => 'error_map_geocoder_missing',
		qr/Geo::Coder::Free 0\.48 or later/, qr/0\.47 is installed/,
	],
) {
	my ($state, $key, $needs, $says) = @$case;

	ok show_state($state), "$state: the canvas rendered";

	my $note = geocoder_note_on_card(0);
	ok $note, "$state: the place card carries a note about the geocoder";

	# A missing note is the failure above; describing one that is not there
	# would only add warnings to the report.  The other checks still run, so
	# one broken state does not hide the second state or the control.
	SKIP: {
		skip "$state: there is no note to describe", 6 unless $note;

		is $note->{key}, $key, "$state: the note is the $key one";
		like $note->{text}, $needs, "$state: the note names the version that is required";
		like $note->{text}, $says,  "$state: the note says which problem it is";

		# The point of loading the card rather than reading the response body:
		# this is the browser saying the reader can see the note.
		is $note->{visible}, 1, "$state: the note is visible on the card";
		is $note->{role}, 'status', "$state: the note is announced as a status";

		like note_keys_on_card(0) // '', qr/warn_map_rows_skipped/,
			"$state: the note is one of the card's notes, not its only content";
	}

	is $browser->js("return document.getElementById('map-0') ? 1 : 0;"), 0,
		"$state: no map is drawn on the card";

	unlike summary_on_card(0), qr/Plotting [1-9]/,
		"$state: the card does not claim to have plotted markers";

	# The control card, on the same page and in the same state: it plots the
	# coordinates and never asks the geocoder, so the note above is the place
	# card's own rather than one the canvas paints on every map.
	is geocoder_note_on_card(1), undef,
		"$state: the card beside it has no geocoder note";

	like note_keys_on_card(1) // '', qr/warn_map_coordinate_rows/,
		"$state: though it carries the note about the row without a coordinate";

	like summary_on_card(1), qr/Plotting 2 markers for 2 of 3 rows/,
		"$state: and still counts the markers it plotted";

	$browser->proved(
		"canvas /a/$id place card with Geo::Coder::Free " . ($state eq 'missing' ? 'absent' : '0.47')
		. ': the card carries the visible geocoder note and draws nothing, while the coordinate card beside it plots 2 markers'
	);
}

done_testing();
