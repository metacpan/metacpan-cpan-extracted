#!/usr/bin/env perl

# GET /map in a real browser, with Geo::Coder::Free missing and with one too
# old to use.
#
# The geocoder is the other optional module the map page depends on, and its
# warning has the same shape as the renderer's: a note above the map saying
# which version is needed and what is there instead.  t/geocode.t proves the
# model produces the sentence, and t/map.t proves the route's records and
# summary; neither opens the page, so nothing has checked that a reader gets the
# note - a message rendered into a hidden list, or left out of the template,
# would satisfy a body-string test.
#
# So the page is loaded in the browser in both states, and each one checks the
# note's text and visibility as the browser computes them: a box, not clipped,
# rendered text, inside the notes list that is announced as a status.  The
# geocoder is replaced in the server, not removed from the machine: the model's
# _load_geocoder is answered from a file the test writes, so one server and one
# browser session show every state without installing anything.
#
# The control is a map of the same file by coordinate, while the state file still
# says the geocoder is too old: the page has notes of its own - the rows without
# a coordinate - and no geocoder note, because it never asks the geocoder.  That
# is what makes the assertions above able to fail rather than being satisfied by
# any page that mentions Geo::Coder::Free.
#
#   AUTHOR_TESTING=1 prove -l t/browser-map-geocoder.t
#
# It skips without AUTHOR_TESTING or without Firefox, like the other
# t/browser-*.t files.

use strict;
use warnings;

use Test::Most;
use File::Spec ();
use File::Temp qw(tempdir);
use JSON::MaybeXS qw(decode_json);
use Mojo::File qw(path);
use Mojo::Util qw(url_escape);
use lib 't/lib';
use BI::Test::Browser qw(geocoder_state);

BI::Test::Browser->plan_browser_tests();

# Three rows: two with a place and a coordinate, one with neither.  The place
# map then has nothing that could be plotted without a geocoder, and the
# coordinate map has two markers and a note about the third row - so the two
# pages differ in what they contain, not only in the URL.
my $dir = tempdir(CLEANUP => 1);
my $csv = File::Spec->catfile($dir, 'places.csv');
path($csv)->spurt(
	"name,city,latitude,longitude\n"
	. "Alpha,Ramsgate,51.33,1.42\n"
	. "Beta,Dover,51.13,1.31\n"
	. "Gamma,,,\n"
);

# What the stand-in in the server answers with: "missing" for a Geo::Coder::Free
# that is not installed, "old" for one below the floor the application asks for.
# Both are the states the model reports as an unavailable geocoder, with the
# reason the message quotes - the same reason the real code builds.
my $state_file = File::Spec->catfile($dir, 'geocoder-state');
path($state_file)->spurt("missing\n");

my $browser = BI::Test::Browser->new(
	app_setup => geocoder_state($state_file),
);

my $PLACES   = '/map?l=' . url_escape("path:$csv") . '&loc=city';
my $COORDS   = '/map?l=' . url_escape("path:$csv") . '&lat=latitude&lon=longitude';
my $NO_PLACE = qr/Plotting 0 markers for 0 of 3 rows from column city/;
my $TWO_ROWS = qr/Plotting 2 markers for 2 of 3 rows from columns latitude and longitude/;

sub show_page {
	my ($state, $url) = @_;

	path($state_file)->spurt("$state\n");
	$browser->navigate($url // $PLACES);

	return $browser->wait_for(sub { $browser->find('h2.graph-title') }, timeout => 10);
}

# The geocoder note as the browser sees it.  A note that exists but is not on
# screen is reported as not visible rather than as missing, so a clipped or
# hidden note fails as the reader would experience it.
sub geocoder_note {
	my $json = $browser->js(<<'JS');
/* Wrapped in an object: JSON.stringify(null) is the bare value null, which a
   JSON backend may refuse to decode (allow_nonref) and the tester's machine
   and each CPAN smoker disagree about.  An object is always decodable. */
return JSON.stringify({ note: (function () {
	var notes = Array.prototype.slice.call(document.querySelectorAll('.map-notes .map-note'));
	var note = notes.filter(function (n) {
		return (n.getAttribute('data-key') || '').indexOf('error_map_geocoder_') === 0;
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
# The two states the page has to report: no geocoder, and one too old for the
# floor the application asks for.  Neither can plot a place, and both say why.
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

	ok show_page($state), "$state: the map page rendered";

	is title_text(), 'Map of city', "$state: the page is titled after the column it geocodes";

	my $note = geocoder_note();
	ok $note, "$state: the page carries a note about the geocoder";
	is $note->{key}, $key, "$state: the note is the $key one";
	like $note->{text}, $needs, "$state: the note names the version that is required";
	like $note->{text}, $says,  "$state: the note says which problem it is";

	# The point of loading the page rather than reading the body: this is the
	# browser saying the reader can see it.
	is $note->{visible}, 1, "$state: the note is visible on the page";
	is $note->{role}, 'status', "$state: the note is announced as a status";

	like summary_text(), $NO_PLACE,
		"$state: the summary says nothing could be plotted rather than pretending";
	is $browser->js("return document.getElementById('map') ? 1 : 0;"), 0,
		"$state: no map element is drawn with no place resolved";

	is $browser->js(
		"var el = document.querySelector('.back-link');"
		. "return el ? (/Home/.test(el.textContent) ? 1 : 0) : 0;"
	), 1, "$state: the page chrome around it is intact";

	$browser->proved(
		'GET /map geocoding a place column with Geo::Coder::Free '
		. ($state eq 'missing' ? 'absent' : '0.47')
		. ': the geocoder note is visible and announced, nothing is plotted, and the page chrome is intact'
	);
}

# ---------------------------------------------------------------------------
# The control: the same file, the same server and the same state file - which
# still says the geocoder is too old - plotted by coordinate.  That page never
# asks the geocoder, so it must carry no geocoder note while carrying notes of
# its own: the absence is the page's, not the template's.
# ---------------------------------------------------------------------------
ok show_page('old', $COORDS), 'control: the coordinate map rendered';

is title_text(), 'latitude and longitude',
	'control: the page is titled after the columns it plots';

is geocoder_note(), undef, 'control: there is no note about the geocoder';

like summary_text(), $TWO_ROWS, 'control: the page counts the rows it plotted';

like $browser->js(
	"var notes = document.querySelectorAll('.map-notes .map-note');"
	. "return Array.prototype.map.call(notes, function (n) {"
	. "  return n.getAttribute('data-key') || ''; }).join('|');"
) // '', qr/warn_map_coordinate_rows/,
	'control: the notes list is rendered, carrying the note about the row without a coordinate';

$browser->proved(
	'GET /map plotting coordinates while the geocoder is too old: no geocoder note, the rows are counted, and the note about the row without a coordinate is still there'
);

done_testing();
