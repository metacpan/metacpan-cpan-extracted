#!/usr/bin/env perl

# The canvas Size menu in a real browser.
#
# t/model.t proves the template emits the menu, the presets and the PATCH
# call; that is a test of the page's source, not of the page.  This test opens
# the canvas in Firefox, focuses one card's Size menu, presses a key, and
# reads back what the browser actually did: the card's computed grid-column
# span, the announcement, the PATCH the page sent, and the layout the server
# stored.
#
# The app, the browser and the Marionette connection come from
# BI::Test::Browser (t/lib/BI/Test/Browser.pm), which is the fixture the whole
# browser suite shares; this file is one of its tests, and the suite runs as
#   prove -l t/browser-*.t
#
# The PATCH is recorded by the app itself, in the server child, before the
# request reaches the controller.  The test makes no request between the page
# loading and the PATCH being counted - the only PATCH it sends is the setup
# layout, before Firefox starts - so a PATCH in the file after that point can
# only have come from the page under test, not from the test pretending to be
# the page.
#
# The app runs in a child process on an ephemeral port with a throwaway
# model_dir, so no analysis is left in the developer's .bi/ store.  Firefox
# runs headless in another child with a throwaway profile, and Marionette on
# an ephemeral port.  The proxy prefs point at a closed port so the page's CDN
# script fails at once instead of waiting on a network this test does not need.
#
#   prove -l t/browser-size.t
#   BI_FIREFOX=/path/to/firefox prove -l t/browser-size.t
#
# Skips when no Firefox is installed.  A Firefox that is installed but will
# not answer on its Marionette port fails the test, printing the browser's
# log, so a broken browser is not mistaken for a machine without one.
# BI_SKIP_BROWSER_TESTS=1 skips the test deliberately.

use strict;
use warnings;

use Test::Most;
use File::Spec ();
use FindBin qw($Bin);
use lib "$Bin/lib";
use JSON::MaybeXS qw(encode_json decode_json);

use BI::Test::Browser ();

BI::Test::Browser->plan_browser_tests(required_files => ['data/sales.csv']);

my $SALES = File::Spec->rel2abs('data/sales.csv');

my $browser = BI::Test::Browser->new(record_patches => 1);
my $BASE    = $browser->base;
my $ua      = $browser->ua;

# ---------------------------------------------------------------------------
# The canvas: two table visuals, the first half width in row 1, so a single
# step down the Width group is a width the card does not already have.
# ---------------------------------------------------------------------------
my $created = $ua->post(
	"$BASE/api/analyses" => { 'Content-Type' => 'application/json' } => encode_json({
		name     => 'BrowserSize',
		datasets => [ { spec => "path:$SALES", alias => 'left' } ],
		visuals  => [
			{ kind => 'table', encode => {}, title => 'Left'  },
			{ kind => 'table', encode => {}, title => 'Right' },
		],
	})
);
is $created->res->code, 201, 'analysis created for the browser';
my $cid = $created->res->json->{id};
ok $cid, 'analysis has an id' or BAIL_OUT('no analysis id');

my $setup = $ua->patch(
	"$BASE/api/analyses/$cid" => { 'Content-Type' => 'application/json' } => encode_json({
		layout => [
			{ visual => 0, x => 1, y => 1, w => 6, h => 1 },
			{ visual => 1, x => 1, y => 2, w => 6, h => 1 },
		],
		# A hierarchy, so the same canvas can also be visited as a drill path
		# below: the sizes have to survive that visit too.
		hierarchies => [ { name => 'Geo', levels => [qw(region product)] } ],
	})
);
is $setup->res->code, 200, 'initial half-width layout stored';

# The setup PATCH is the baseline.  Anything in the record after this line was
# sent by the browser.
my @patches = $browser->patches;
is scalar @patches, 1, 'one PATCH recorded before the browser starts';

$browser->navigate("/a/$cid");

my $READY = <<'JS';
var s = document.getElementById('visual-size-0');
return s ? (s.options[s.selectedIndex].textContent || '') : '';
JS

my $ready = $browser->wait_for(sub { js_value($READY) }, timeout => 10);
is $ready, 'Half width, 1 row high',
	'the menu shows the size the card was saved at';

like js_value('return navigator.userAgent;'), qr/Firefox/,
	'the page is running in a real Firefox';

# The page's own view of the card: the span the browser laid out, and the
# option the menu is showing.  The browser resolves the saved style attribute
# and the auto-placement, so this is what the user sees, not what the
# template wrote.
# The multiplication sign the size on the card is written with, spelled with
# chr() rather than as a literal in this file: it is the same character whether
# or not the file has been read as UTF-8.
my $TIMES = chr(0xD7);

# The probes return JSON, which the test decodes.  WebDriver has already turned
# the script's string into characters by the time it gets here - and the size on
# the card is "6 × 1" - so the probe escapes everything outside ASCII before
# stringifying: JSON either way, and no second UTF-8 decoding of a string that
# is already decoded.
my $ASCII_SAFE = <<'JS';
function asciiSafe(text) {
	return String(text).replace(/[^\x20-\x7e]/g, function (c) {
		return '\\u' + ('0000' + c.charCodeAt(0).toString(16)).slice(-4);
	});
}
JS

my $STATE = $ASCII_SAFE . <<'JS';
var card  = document.getElementById('visual-0');
var sel   = document.getElementById('visual-size-0');
var cs    = getComputedStyle(card);
var badge = card.querySelector('[data-size-badge="1"]');
return asciiSafe(JSON.stringify({
	colStart  : cs.gridColumnStart,
	colEnd    : cs.gridColumnEnd,
	rowStart  : cs.gridRowStart,
	value     : sel.value,
	summary   : sel.options[sel.selectedIndex].textContent,
	badge     : badge ? badge.textContent : '',
	badgeTitle: badge ? badge.getAttribute('title') : '',
	focused   : document.activeElement ? document.activeElement.id : '',
}));
JS

my $before = decode_json(js_value($STATE));
is $before->{colEnd},   'span 6',               'card starts half width in the grid';
is $before->{summary},  'Half width, 1 row high', 'the summary describes that span';
is $before->{value},    '',                     'the summary option is the one selected';
is $before->{badge},    "6 ${TIMES} 1",        'and the size is written on the card as well';
is $before->{badgeTitle}, 'Half width, 1 row high',
	'with the menu words for that size';

# The setup PATCH is still the only one: nothing the page does on load writes
# a layout, so the next PATCH can only come from the choice below.
is $browser->patch_count, 1, 'loading the canvas did not PATCH anything';

# ---------------------------------------------------------------------------
# The one user action: focus the menu and press ArrowDown, which in a closed
# native select moves to the next option and fires change.  One step from
# "Half width" is "Full width", a span the card does not have yet.  The press
# is a real one, sent through the browser's input stack by the fixture.
# ---------------------------------------------------------------------------
$browser->focus('#visual-size-0');
ok js_value("return document.activeElement.id;") eq 'visual-size-0',
	'focus is on the Size menu';
$browser->press('ArrowDown');

my $after = $browser->wait_for(sub {
	my $seen = eval { decode_json(js_value($STATE)) };
	return $seen if $seen && ($seen->{colEnd} // '') eq 'span 12';
	return undef;
}, timeout => 10) || {};
is $after->{colEnd},   'span 12',  'choosing Full width changed the computed grid-column span';
is $after->{value},    '12',       'the menu stayed on the preset that was chosen';
is $after->{summary},  'Full width', 'the menu reads as the preset';
is $after->{focused},  'visual-size-0', 'focus stayed on the menu';
is $after->{badge},    "12 ${TIMES} 1",  'the card on the page says the size it was given';
is $after->{badgeTitle}, 'Full width, 1 row high', 'in the preset words';

my $live = js_value("return document.getElementById('canvas-live').textContent;");
like $live, qr/\QLeft is now full width, 1 row high in column 1\E/,
	'the new size is announced as it is made';

# ---------------------------------------------------------------------------
# The write.  saveLayout() debounces by 400ms, so the PATCH is waited for
# rather than assumed; the file is the app's record, written before routing.
# ---------------------------------------------------------------------------
my $sent = $browser->wait_for(sub {
	my @rows = $browser->patches;
	return @rows > 1 ? \@rows : undef;
}, timeout => 10) || [];

is scalar @$sent, 2, 'the page sent exactly one PATCH after the choice'
	or diag 'PATCHes recorded: ' . $browser->patch_count;

my $patch = $sent->[1] || {};
is $patch->{path} // '', "/api/analyses/$cid", 'the PATCH went to this canvas';

my $body = defined $patch->{body} ? eval { decode_json($patch->{body}) } : undef;
ok ref $body eq 'HASH' && ref $body->{layout} eq 'ARRAY',
	'the PATCH body is a layout' or BAIL_OUT('the recorded body is not a layout');

my ($v0) = grep { ($_->{visual} // '') eq '0' } @{ $body->{layout} };
ok $v0, 'the PATCHed layout includes the card that was resized' or BAIL_OUT('card missing');
is $v0->{w}, 12, 'the PATCHed layout has the card full width';
is $v0->{h}, 1,  'the PATCHed layout kept the row height';

# ---------------------------------------------------------------------------
# And the server accepted it: the stored layout, then a reload, which renders
# the size server-side with no JavaScript involved.
# ---------------------------------------------------------------------------
my $stored = $ua->get("$BASE/api/analyses/$cid")->res->json->{layout} || [];
my ($stored_v0) = grep { ($_->{visual} // '') eq '0' } @$stored;
$stored_v0 ||= {};
is $stored_v0->{w}, 12, 'the server stored the width the browser chose';
is $stored_v0->{h}, 1,  'the server stored the row height unchanged';

$browser->navigate("/a/$cid");

my $reloaded = $browser->wait_for(sub {
	my $seen = eval { decode_json(js_value($STATE)) };
	return $seen if $seen && ($seen->{colEnd} // '') eq 'span 12';
	return undef;
}, timeout => 10) || {};

is $reloaded->{colEnd},  'span 12',               'a reload renders the saved width';
is $reloaded->{summary}, 'Full width, 1 row high', 'a reload reads the saved size back';
is $reloaded->{badge},   "12 ${TIMES} 1",         'and renders the size on the card as well';

is $browser->patch_count, 2,
	'rendering the saved layout does not PATCH it back';

# The size on the card is in the page the server sends, not only in the one the
# script has filled in: this is the body of a GET, with no browser involved.
my $raw = $ua->get("$BASE/a/$cid")->res->body;
like $raw, qr{<span class="visual-size-badge" data-size-badge="1" title="12 columns wide, 1 row high">12 &times; 1</span>},
	'the server writes the saved size on the card, before any script runs';

# ---------------------------------------------------------------------------
# The same canvas opened as a filtered visit: cross-filtered, and then drilled
# one level.  Both have to lay the card out at the size the canvas was given,
# and neither may write a layout of its own: a page that saved the arrangement
# it can see would be recording the filtered render's arrangement, which is not
# the one the canvas was given.
# ---------------------------------------------------------------------------
require Mojo::Util;

for my $visit (
	[ 'cross-filter' => '?cf=' . Mojo::Util::url_escape('region:eq:North') . '&cv=0' ],
	[ 'drill-through' => '?dd=Geo&dl=1&cf=' . Mojo::Util::url_escape('region:eq:North') ],
) {
	my ($label, $query) = @$visit;

	$browser->navigate("/a/$cid$query");

	my $seen = $browser->wait_for(sub {
		my $state = eval { decode_json(js_value($STATE)) };
		return $state if $state && ($state->{summary} // '') eq 'Full width, 1 row high';
		return undef;
	}, timeout => 10) || {};

	is($seen->{colEnd}, 'span 12', "a $label visit renders the saved width")
		or diag 'recorded PATCHes: ' . $browser->patch_count;
	is $seen->{summary}, 'Full width, 1 row high',
		"a $label visit shows the saved size in the menu";
	is $seen->{badge}, "12 ${TIMES} 1",
		"and writes it on the card too";

	is $browser->patch_count, 2,
		"a $label visit does not PATCH a layout of its own";
}

# ---------------------------------------------------------------------------
# The size on the card, from a drag (3.2).  The corner grip is the one way to
# leave a card at a width no preset names, and the number on the card is what
# says so - while the grip is being dragged, not only once it is let go.  The
# drag is dispatched from the page through the handlers the grip is wired to,
# at the coordinates the browser reports for it: Firefox's own input stack is
# not what is in question here, the page's answer to a drag is - the keyboard
# suite (t/browser-canvas-keys.t) is where the input stack is the subject.
# ---------------------------------------------------------------------------
$browser->navigate("/a/$cid");

my $saved = $browser->wait_for(sub {
	my $seen = eval { decode_json(js_value($STATE)) };
	return $seen if $seen && ($seen->{badge} // '') eq "12 ${TIMES} 1";
	return undef;
}, timeout => 10) || {};

is $saved->{badge}, "12 ${TIMES} 1",
	'back on the canvas, the card says the size it is saved at';

my $DRAG = $ASCII_SAFE . <<'JS';
var card   = document.getElementById('visual-0');
var handle = card.querySelector('.visual-resize-handle');
var badge  = card.querySelector('[data-size-badge="1"]');
var grid   = document.getElementById('canvas-grid');
var cs     = getComputedStyle(grid);
var tracks = (cs.gridTemplateColumns || '').split(/\s+/).filter(function (t) { return t; });
var pitch  = parseFloat(tracks[0]) + parseFloat(cs.columnGap || 0);
var r      = handle.getBoundingClientRect();
var x      = r.left + (r.width / 2);
var y      = r.top + (r.height / 2);

function pe(type, px, py) {
	return new PointerEvent(type, {
		button: 0, clientX: px, clientY: py, bubbles: true, cancelable: true,
	});
}

handle.dispatchEvent(pe('pointerdown', x, y));
document.dispatchEvent(pe('pointermove', x - (2 * pitch), y));
var during = { badge: badge.textContent, title: badge.getAttribute('title') };
document.dispatchEvent(pe('pointerup', x - (2 * pitch), y));

return asciiSafe(JSON.stringify({
	during    : during.badge,
	title     : during.title,
	after     : badge.textContent,
	valuetext : handle.getAttribute('aria-valuetext'),
	valuenow  : handle.getAttribute('aria-valuenow'),
	colEnd    : getComputedStyle(card).gridColumnEnd,
}));
JS

my $dragged = decode_json(js_value($DRAG));
is $dragged->{during},  "10 ${TIMES} 1",
	'the card says the width the grip left it at, mid-drag';
is $dragged->{after},   "10 ${TIMES} 1", 'and still says it when the grip is let go';
is $dragged->{title},   '10 columns wide, 1 row high',
	'both dimensions in words, for a width no preset names';
is $dragged->{colEnd},  'span 10', 'the grid span followed the drag';
# A drag is not announced in the live region - the person dragging it is looking
# at it - but the handle carries the same size for anyone reading the slider.
is $dragged->{valuetext}, '10 columns wide, 1 row high',
	'the handle reports both dimensions to a screen reader';
is $dragged->{valuenow}, '10', 'as the value the slider carries';

# The drag is a write like the menu, and it is the whole of what the card says:
# one more PATCH, with the width the grip was left at.
my $drag_patches = $browser->wait_for(sub {
	my @rows = $browser->patches;
	return @rows > 2 ? \@rows : undef;
}, timeout => 10) || [];

is scalar(@$drag_patches), 3, 'the drag sent one PATCH'
	or diag 'PATCHes recorded: ' . $browser->patch_count;

my $drag_body = $drag_patches->[2] && defined $drag_patches->[2]{body}
	? eval { decode_json($drag_patches->[2]{body}) } : undef;
ok ref $drag_body eq 'HASH' && ref $drag_body->{layout} eq 'ARRAY',
	'the PATCH body is a layout' or BAIL_OUT('the recorded drag body is not a layout');

my ($dv0) = grep { ($_->{visual} // '') eq '0' } @{ $drag_body->{layout} };
$dv0 ||= {};
is $dv0->{w}, 10, 'with the width the drag left the card at';
is $dv0->{h}, 1,  'and the row height it did not change';

my $stored_drag = $ua->get("$BASE/api/analyses/$cid")->res->json->{layout} || [];
my ($sd0) = grep { ($_->{visual} // '') eq '0' } @$stored_drag;
$sd0 ||= {};
is $sd0->{w}, 10, 'the server stored the dragged width';

$browser->navigate("/a/$cid");

my $again = $browser->wait_for(sub {
	my $seen = eval { decode_json(js_value($STATE)) };
	return $seen if $seen && ($seen->{badge} // '') eq "10 ${TIMES} 1";
	return undef;
}, timeout => 10) || {};

is $again->{badge},   "10 ${TIMES} 1", 'a reload shows the dragged width on the card';
is $again->{summary}, '10 columns wide, 1 row high', 'and in the menu';
is $again->{colEnd},  'span 10', 'at the span the drag left it at';
is $browser->patch_count, 3,
	'and rendering that width back does not PATCH it either';

# What this run established, for the job summary: the menu and the drag are
# checked against the same reads - the card, the announcement, the PATCH and
# what the server stored.
$browser->proved(
	'canvas card size: the Size menu sets the span from a key press, announces it'
	. ' and PATCHes once, and a drag of the corner grip reports the width it leaves'
	. ' and stores it; a reload renders the saved width without PATCHing again'
);

done_testing();

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub js_value {
	my ($script) = @_;
	return $browser->js($script);
}
