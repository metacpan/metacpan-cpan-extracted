#!/usr/bin/env perl

# The Map option in the table toolbar, driven from the keyboard.
#
# The map page has always been reachable by URL; this test is about the way a
# reader reaches it from the table they are looking at.  It opens a fixture
# with latitude and longitude columns, opens the Map panel with the toolbar
# button, watches the panel choose those columns, switches to the place-name
# mode and back, and submits with Enter.
#
# Drawing the card needs the optional HTML::OSM, so the checks that need a drawn
# map are skipped where it is not installed rather than failed: the panel flow
# they sit in is what this file is for, and it holds in either state.  The assertions are on what the
# browser did: the panel's visibility, the controls' disabled state, and the
# URL and page that followed the form.
#
#   AUTHOR_TESTING=1 prove -l t/browser-map-panel.t
#
# It skips without AUTHOR_TESTING or without Firefox, like the other
# t/browser-*.t files.

use strict;
use warnings;

use Test::Most;
use File::Spec ();
use File::Temp qw(tempdir);
use Mojo::File qw(path);
use Mojo::Util qw(url_escape);
use lib 't/lib';
use BI::Test::Browser ();

BI::Test::Browser->plan_browser_tests(required_files => ['data/sales.csv']);

my $dir = tempdir(CLEANUP => 1);
my $csv = File::Spec->catfile($dir, 'places.csv');
path($csv)->spurt(
	"name,latitude,longitude,lat2,lon2,kind\n"
	. "Alpha,51.33,1.42,52.5,-1.5,one\n"
	. "Beta,51.92,0.75,53.5,-2.5,two\n"
);

my $browser = new_ok('BI::Test::Browser');
my $ua      = $browser->ua();
my $BASE    = $browser->base();

# Drawing a map card needs HTML::OSM 0.12 or later on the server.  Without it
# the card carries the note saying so and no map element at all - which is a
# different state from Leaflet's script not arriving, where the card has its
# element and its own script and only the drawing is missing, and which is why
# the checks below are guarded on this rather than on typeof L.
# t/browser-canvas-map-degraded.t is the page test for the state without a
# renderer; here it is skipped, so the panel flow is still proved on a machine
# that has none - the keyboard job's runner is one.
my $have_renderer = eval { require HTML::OSM; HTML::OSM->VERSION(0.12); 1 };

$browser->navigate('/open?path=' . url_escape($csv));
ok $browser->wait_for(sub { $browser->js("return !!document.getElementById('btn-map');") }),
	'the table view loaded with a Map button';

# ---------------------------------------------------------------------------
# Open the panel.  The obvious latitude and longitude columns are chosen for
# the reader, and the panel is ready to submit.
# ---------------------------------------------------------------------------
$browser->click('#btn-map');

is $browser->js("return document.getElementById('map-panel').hidden;"), 0,
	'the Map panel opens in the chart panel area';
is $browser->js("return document.getElementById('map-lat-sel').value;"), 'latitude',
	'latitude was chosen from the column names';
is $browser->js("return document.getElementById('map-lon-sel').value;"), 'longitude',
	'longitude was chosen from the column names';
is $browser->js("return document.getElementById('btn-do-map').disabled;"), 0,
	'Open map is enabled once both coordinates are chosen';
is $browser->js("return document.activeElement.id;"), 'map-mode-sel',
	'focus starts on the way places are stored';

# ---------------------------------------------------------------------------
# A place-name column is the other way to place a row.  Switching mode must
# hide and disable the coordinate selects, so only one set is submitted.
# ---------------------------------------------------------------------------
$browser->press('ArrowDown');
is $browser->js("return document.getElementById('map-mode-sel').value;"), 'loc',
	'ArrowDown chose the place-name mode';
is $browser->js("return document.getElementById('map-lat-field').hidden;"), 1,
	'the latitude field is hidden in place-name mode';
is $browser->js("return getComputedStyle(document.getElementById('map-lat-field')).display;"), 'none',
	'and it is not left on screen by a flex display';
is $browser->js("return document.getElementById('map-lon-field').hidden;"), 1,
	'the longitude field is hidden in place-name mode';
is $browser->js("return getComputedStyle(document.getElementById('map-lon-field')).display;"), 'none',
	'and neither is the longitude field';
is $browser->js("return document.getElementById('map-lat-sel').disabled;"), 1,
	'latitude is disabled, so it is not submitted';
is $browser->js("return document.getElementById('map-lon-sel').disabled;"), 1,
	'longitude is disabled, so it is not submitted';
is $browser->js("return document.getElementById('map-loc-field').hidden;"), 0,
	'the place-name field is shown';
is $browser->js("return document.getElementById('map-loc-sel').required;"), 1,
	'and it is required';
is $browser->js("return document.getElementById('btn-do-map').disabled;"), 1,
	'Open map waits for a place column';

$browser->press('ArrowUp');
is $browser->js("return document.getElementById('map-mode-sel').value;"), 'coords',
	'ArrowUp went back to coordinate columns';
is $browser->js("return document.getElementById('map-lat-sel').disabled;"), 0,
	'latitude is enabled again';
is $browser->js("return getComputedStyle(document.getElementById('map-lat-field')).display;"), 'flex',
	'and the latitude field is visible again';
is $browser->js("return document.getElementById('map-lat-sel').value;"), 'latitude',
	'with the column it had chosen';
is $browser->js("return document.getElementById('btn-do-map').disabled;"), 0,
	'and Open map is ready again';

# ---------------------------------------------------------------------------
# Submit with the keyboard and read the page it opened.
# ---------------------------------------------------------------------------
$browser->focus('#btn-do-map');
$browser->press('Enter');

my $seen = $browser->wait_for(sub {
	my $page = $browser->js("return location.pathname;");
	return $page if defined $page && $page eq '/map';
	return undef;
}, timeout => 10);

is $seen, '/map', 'Enter on Open map opened the map page';

my $query = $browser->js("return location.search;");
like $query, qr/[?&]lat=latitude(?:&|\z)/, 'the map was asked for the latitude column';
like $query, qr/[?&]lon=longitude(?:&|\z)/, 'and the longitude column';
unlike $query, qr/[?&]loc=/, 'and not the place column from the other mode';
like $query, qr/[?&]l=path%3A/, 'for the table the panel was opened from';
like $query, qr/[?&]back=/, 'with a way back to that table';

my $summary = $browser->wait_for(sub {
	my $t = $browser->js("return document.querySelector('.map-summary') ? document.querySelector('.map-summary').textContent.trim() : '';");
	return $t if defined $t && length $t;
	return undef;
}, timeout => 10) // '';
like($summary, qr/Plotting 2 markers for 2 of 2 rows from columns latitude and longitude/,
	'the map page plotted the two coordinate rows');

# ---------------------------------------------------------------------------
# New canvas on a map page keeps the map, not just its data source.
# ---------------------------------------------------------------------------
ok $browser->wait_for(sub { $browser->find('#new-canvas-btn') }),
	'the map page has a New Canvas button';

$browser->click('#new-canvas-btn');
$browser->send_keys('#new-canvas-name', 'Browser map canvas');
$browser->click('#new-canvas-save');

my $href = $browser->wait_for(sub {
	my $seen = $browser->js(
		"var a = document.getElementById('new-canvas-link');"
		. "return a && !a.hidden ? a.href : '';"
	);
	return $seen if defined $seen && length $seen;
	return undef;
}, timeout => 10);

like($href, qr{/a/[A-Za-z0-9]+}, 'the map page reports where the canvas was saved');
my ($id) = ($href // '') =~ m{/a/([^/?#]+)};
ok($id, 'the map canvas has an id') or BAIL_OUT('no map canvas id');

my $analysis = $ua->get("$BASE/api/analyses/$id")->res->json;
my $visual   = $analysis->{visuals}[0] || {};
is($visual->{kind}, 'map', 'the first visual is a map');
is($visual->{title}, 'latitude and longitude', 'the card keeps the map title');
is_deeply($visual->{encode}, { lat => 'latitude', lon => 'longitude' },
	'the map keeps its coordinate columns');
$browser->navigate("/a/$id");
SKIP: {
	skip 'HTML::OSM 0.12 or later is needed to draw the map card', 1
		unless $have_renderer;

	ok $browser->wait_for(sub { $browser->find('#map-0') }),
		'the canvas renders the map card with its own Leaflet element';
}

is scalar @{ $analysis->{visuals} || [] }, 1, 'the canvas starts with one map visual';

# ---------------------------------------------------------------------------
# Add current view can append a second map from the canvas itself.
# ---------------------------------------------------------------------------
ok $browser->wait_for(sub { $browser->find('#btn-add-current') }),
	'the canvas offers Add current view';
$browser->click('#btn-add-current');

is $browser->js(
	"return Array.prototype.some.call(document.getElementById('ac-kind').options,"
	. "function (o) { return o.value === 'map'; });"
), 1, 'the Add current view panel offers Map as a kind';

$browser->js(
	"var k = document.getElementById('ac-kind');"
	. "k.value = 'map'; k.dispatchEvent(new Event('change'));"
	. "document.getElementById('ac-map-lat').value = 'latitude';"
	. "document.getElementById('ac-map-lon').value = 'longitude';"
	. "document.getElementById('ac-title-inp').value = 'Second map';"
	. "window.__canvasStayed = 1;"
	. "return k.value;"
);
is $browser->js("var f = document.getElementById('ac-map-lat').closest('.ac-field'); return f.hidden ? 0 : 1;"), 1,
	'choosing Map shows the map columns';
is $browser->js("var f = document.getElementById('ac-cat').closest('.ac-field'); return f.hidden ? 0 : 1;"), 0,
	'and hides the chart columns';

$browser->js(
	"window.__announcements = [];"
	. "var live = document.getElementById('canvas-live');"
	. "new MutationObserver(function () {"
	. "  window.__announcements.push(live.textContent);"
	. "}).observe(live, { childList: true, subtree: true, characterData: true });"
	. "return 1;"
);
$browser->click('#ac-add-btn');

my $cards = $browser->wait_for(
	sub {
		my $n = $browser->js("return document.querySelectorAll('.visual-card').length;");
		return $n == 2 ? $n : undef;
	},
	timeout => 15,
);
is($cards, 2, 'the canvas comes back with the appended map card');

is $browser->js("return window.__canvasStayed || 0;"), 1,
	'the map card was added without reloading the canvas';
is $browser->js("return document.getElementById('canvas-grid').lastElementChild.id;"),
	'visual-1', 'the new map card is the last one in the grid';
is $browser->js("return document.activeElement && document.activeElement.id;"),
	'visual-1', 'focus moved to the new map card';
like(
	$browser->js("return (window.__announcements || []).join('\\n');"),
	qr/Map "Second map" added at the end of the canvas\. 2 visuals on the canvas\./,
	'the status region announces the map and the new count',
);

my $outcome = $browser->wait_for(
	sub {
		my $said = $browser->js("return (window.__announcements || []).join('\\n');");
		return undef unless defined $said;
		return $said if $said =~ /finished drawing|did not load|did not finish drawing/;
		return undef;
	},
	timeout => 15,
);

SKIP: {
	skip 'HTML::OSM 0.12 or later is needed to draw the map card', 1
		unless $have_renderer;

	ok $browser->js("return !!document.querySelector('#map-1');"),
		'the appended map element is on the page';
}

# Leaflet comes from a CDN.  With it the page can say the map has finished
# drawing, and the panes are there to prove it; without it the page names the
# missing library instead of promising a drawing that will not come.
my $have_leaflet = $browser->js("return typeof L;") eq 'object';
if ($have_leaflet) {
	like($outcome, qr/Map "Second map" finished drawing\./,
		'the status region says when the map has finished drawing');
	ok $browser->wait_for(
		sub { $browser->js("return !!document.querySelector('#map-1 .leaflet-pane');") },
		timeout => 10,
	), 'the appended map was drawn in place, not left as an empty element';
	is $browser->js("return !!document.querySelector('#map-0 .leaflet-pane');"), 1,
		'and the first map is still drawn';
} else {
	like($outcome,
		qr/Map "Second map" was added, but Leaflet, the map library, did not load, so nothing was drawn\./,
		'without Leaflet the status region names the library that did not load');
	is $browser->js("return !!document.querySelector('#map-1 .leaflet-pane');"), 0,
		'and the card is left undrawn rather than broken';
}

my $updated = $ua->get("$BASE/api/analyses/$id")->res->json;
is(scalar @{ $updated->{visuals} || [] }, 2, 'the second map was stored');
is($updated->{visuals}[1]{kind}, 'map', 'the appended visual is a map');
is_deeply($updated->{visuals}[1]{encode}, { lat => 'latitude', lon => 'longitude' },
	'the appended map keeps its coordinate columns');

SKIP: {
	skip 'HTML::OSM 0.12 or later is needed to draw the map card', 1
		unless $have_renderer;

	ok $browser->wait_for(sub { $browser->find('#map-1') }),
		'the appended map has its own Leaflet element';
}

# ---------------------------------------------------------------------------
# A saved map card's columns can be changed where it sits: no delete, no
# append, no reload, and the card keeps its index, title and place.
# ---------------------------------------------------------------------------
is $browser->js("return document.querySelectorAll('#visual-0 .visual-edit-btn').length;"),
	1, 'the card saved with the canvas offers an edit control';
is $browser->js("return document.querySelectorAll('#visual-1 .visual-edit-btn').length;"),
	1, 'and so does the map card appended in place';

$browser->js("window.__editStayed = 1; return 1;");
$browser->click('#visual-1 .visual-edit-btn');

ok $browser->wait_for(
	sub { $browser->js("return document.getElementById('me-panel').hidden ? 0 : 1;") },
	timeout => 5,
), 'the edit panel opens';
is $browser->js("return document.querySelector('#visual-1 .visual-edit-btn').getAttribute('aria-expanded');"),
	'true', 'the control says the panel is open';

ok $browser->wait_for(
	sub { $browser->js("return document.querySelectorAll('#me-lat option').length > 2 ? 1 : 0;") },
	timeout => 5,
), 'the panel fills in the canvas columns';

is $browser->js("return document.getElementById('me-lat').value;"), 'latitude',
	'it starts on the latitude the card is using';
is $browser->js("return document.getElementById('me-lon').value;"), 'longitude',
	'and on its longitude';
is $browser->js("return document.getElementById('me-loc').value;"), '',
	'no place column, because the card plots coordinates';

# Half a coordinate pair is refused in the panel, before anything is sent.
$browser->js("document.getElementById('me-lon').value = ''; return 1;");
$browser->click('#me-save');
is $browser->js("return document.getElementById('me-error').hidden ? 0 : 1;"), 1,
	'a missing longitude is reported in the panel';
like $browser->js("return document.getElementById('me-error').textContent;"),
	qr/both a latitude and a longitude/,
	'with what the form needs';
is $browser->js("return document.getElementById('me-panel').hidden ? 0 : 1;"), 1,
	'and the panel stays open';

# Switch the card to the other coordinate columns and save.
$browser->js(
	"document.getElementById('me-lat').value = 'lat2';"
	. "document.getElementById('me-lon').value = 'lon2';"
	. "return 1;"
);
$browser->click('#me-save');

my $closed = $browser->wait_for(
	sub { $browser->js("return document.getElementById('me-panel').hidden ? 1 : 0;") },
	timeout => 10,
);
is $closed, 1, 'saving closes the panel';

is $browser->js("return window.__editStayed || 0;"), 1,
	'the card was changed without reloading the canvas';
is $browser->js("return document.activeElement && document.activeElement.className;"),
	'visual-edit-btn', 'focus went back to the control that opened the panel';
is $browser->js("return document.querySelectorAll('.visual-card').length;"), 2,
	'no card was added or removed';
is $browser->js("return document.getElementById('visual-1').querySelector('.visual-card-title').textContent;"),
	'Second map', 'the card keeps its title';

SKIP: {
	skip 'HTML::OSM 0.12 or later is needed to draw the map card', 3
		unless $have_renderer;

	ok $browser->js("return !!document.querySelector('#map-1');"),
		'the map element was redrawn in place';
	# Read through a local: a card without its script is a failure to report,
	# not an exception that ends the file before its plan is written.
	my $redrawn_script = $browser->js(
		"var s = document.querySelector('#visual-1 .visual-card-body script');"
		. "return s ? s.textContent : '';"
	);
	like $redrawn_script, qr/L\.marker\(\[52\.5, -1\.5\]/,
		'with a marker from the newly chosen columns';
	like $redrawn_script, qr/L\.markerClusterGroup\(\)/,
		'and the redrawn map still clusters its markers';
}
like $browser->js("return (window.__announcements || []).join('\\n');"),
	qr/Map columns updated: latitude lat2 and longitude lon2\./,
	'and the status region says what changed';

my $redrawn = $browser->wait_for(
	sub {
		my $said = $browser->js("return (window.__announcements || []).join('\\n');");
		return undef unless defined $said;
		return $said if $said =~ /finished redrawing|could not be redrawn|did not finish redrawing/;
		return undef;
	},
	timeout => 15,
);

my $edited_store = $ua->get("$BASE/api/analyses/$id")->res->json;
is_deeply($edited_store->{visuals}[1]{encode}, { lat => 'lat2', lon => 'lon2' },
	'the new columns are stored on the same visual');
is scalar @{ $edited_store->{visuals} || [] }, 2, 'the visual list did not grow';

if ($have_leaflet) {
	like($redrawn, qr/Map "Second map" finished redrawing\./,
		'the status region says when the edited map has finished redrawing');
	ok $browser->wait_for(
		sub { $browser->js("return !!document.querySelector('#map-1 .leaflet-pane');") },
		timeout => 10,
	), 'the edited map was drawn, not left as an empty element';
} else {
	like($redrawn,
		qr/Map "Second map" could not be redrawn: Leaflet, the map library, did not load, so nothing was drawn\./,
		'without Leaflet the edit names the library that did not load');
	is $browser->js("return !!document.querySelector('#map-1 .leaflet-pane');"), 0,
		'and the card is left undrawn rather than broken';

	# Stand in for Leaflet for a second edit, so the finished-redrawing
	# announcement is checked even on a machine that cannot reach the CDN.
	$browser->js("window.L = {}; return 1;");
	$browser->click('#visual-1 .visual-edit-btn');
	ok $browser->wait_for(
		sub { $browser->js("return document.querySelectorAll('#me-lat option').length > 2 ? 1 : 0;") },
		timeout => 5,
	), 'the edit panel fills in the columns again';
	$browser->click('#me-save');
	ok $browser->wait_for(
		sub { $browser->js("return document.getElementById('me-panel').hidden ? 1 : 0;") },
		timeout => 10,
	), 'the second edit closes the panel';

	is($browser->js(
		"var body = document.querySelector('#visual-1 .visual-card-body');"
		. "if (!body) return 0;"
		. "var d = document.createElement('div');"
		. "d.className = 'leaflet-container';"
		. "body.appendChild(d); return 1;"
	), 1, 'a Leaflet container appears in the edited card');

	my $finished = $browser->wait_for(
		sub {
			my $said = $browser->js("return (window.__announcements || []).join('\\n');");
			return (defined($said) && $said =~ /Map "Second map" finished redrawing\./) ? $said : undef;
		},
		timeout => 15,
	);
	like($finished, qr/Map "Second map" finished redrawing\./,
		'and the page announces that the edited map has finished redrawing');
}

# Offline, the finished-drawing announcement is still checked: stand in for
# Leaflet so the card passes the library check, then put the container Leaflet
# would have made where the map draws it.  The page must notice and say so.
SKIP: {
	skip 'the real Leaflet was available and the drawing was checked above', 3
		if $have_leaflet;

	$browser->js("window.L = {}; return 1;");
	$browser->click('#btn-add-current');
	$browser->js(
		"var k = document.getElementById('ac-kind');"
		. "k.value = 'map'; k.dispatchEvent(new Event('change'));"
		. "document.getElementById('ac-map-lat').value = 'latitude';"
		. "document.getElementById('ac-map-lon').value = 'longitude';"
		. "document.getElementById('ac-title-inp').value = 'Stub map';"
		. "return 1;"
	);
	$browser->click('#ac-add-btn');

	my $stub_card = $browser->wait_for(
		sub {
			my $n = $browser->js("return document.querySelectorAll('.visual-card').length;");
			return (defined($n) && $n == 3) ? $n : undef;
		},
		timeout => 15,
	);
	is($stub_card, 3, 'the map card with a stand-in library is appended');

	is($browser->js(
		"var body = document.querySelector('#visual-2 .visual-card-body');"
		. "if (!body) return 0;"
		. "var d = document.createElement('div');"
		. "d.className = 'leaflet-container';"
		. "body.appendChild(d); return 1;"
	), 1, 'a Leaflet container appears in the card');

	my $drawn = $browser->wait_for(
		sub {
			my $said = $browser->js("return (window.__announcements || []).join('\\n');");
			return (defined($said) && $said =~ /Stub map" finished drawing/) ? $said : undef;
		},
		timeout => 15,
	);
	like($drawn, qr/Map "Stub map" finished drawing\./,
		'and the page announces that the map has finished drawing');
}

# What this run established, for the job summary: the route a reader takes to
# the map from the table they are looking at, rather than the map page's URL.
$browser->proved(
	'GET /open on a table with coordinates: the toolbar\'s Map panel opens, chooses'
	. ' the latitude and longitude columns, switches to the place-name mode and'
	. ' back, and Enter submits to GET /map with the columns it named'
);

done_testing();
