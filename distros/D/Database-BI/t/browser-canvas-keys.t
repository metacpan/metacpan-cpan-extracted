#!/usr/bin/env perl

# The canvas, driven from the keyboard, in a real browser.
#
# t/model.t proves the template wires the handlers and writes the help text;
# that is a test of the page's source.  This test presses real keys and reads
# what the browser did: the grid position and span it computed, the size
# written on the card and in the Size menu, the handle's slider attributes, the
# live region, and the layout the app stored.
#
# Every press goes through the browser's input stack (WebDriver key actions),
# not through a KeyboardEvent made up in the page.  That is the part a source
# test cannot reach: whether the arrow keys arrive at the focused handle at all,
# whether Shift is seen with them, and whether focus is where the page thinks
# it is.
#
# The three controls this covers are the three ways to size a card:
#   - the header handle moves the card one cell at a time; Shift goes to the
#     edge of the canvas;
#   - the corner grip resizes it: left and right for the width, up and down for
#     the height, Home and End for the narrowest and widest;
#   - the Size menu sets both dimensions from its presets, and its entries are
#     reached with the same arrow keys and letters a native select uses.
#
# The fixture (t/lib/BI/Test/Browser.pm) starts the app, Firefox and Marionette;
# the whole suite runs as
#   prove -l t/browser-*.t
# and skips when there is no Firefox, or when BI_SKIP_BROWSER_TESTS is set.

use strict;
use warnings;

use Test::Most;
use File::Spec ();
use FindBin qw($Bin);
use lib "$Bin/lib";
use JSON::MaybeXS qw(encode_json decode_json);

use BI::Test::Browser ();

BI::Test::Browser->plan_browser_tests(required_files => ['data/sales.csv']);

my $SALES   = File::Spec->rel2abs('data/sales.csv');
my $browser = BI::Test::Browser->new(record_patches => 1);
my $BASE    = $browser->base;
my $ua      = $browser->ua;

# ---------------------------------------------------------------------------
# Two table visuals.  The second is in row 4, leaving rows 2 and 3 free: the
# moves below have somewhere to go, and a resize that grows the first card
# three rows high does not have to push the second one out of the way.  That
# keeps the announcements - which name anything that was displaced - readable
# in the assertions.
# ---------------------------------------------------------------------------
my $created = $ua->post(
	"$BASE/api/analyses" => { 'Content-Type' => 'application/json' } => encode_json({
		name     => 'CanvasKeys',
		datasets => [ { spec => "path:$SALES", alias => 'left' } ],
		visuals  => [
			{ kind => 'table', encode => {}, title => 'Left'  },
			{ kind => 'table', encode => {}, title => 'Right' },
		],
	})
);
is $created->res->code, 201, 'analysis created for the keyboard test';
my $cid = $created->res->json->{id};
ok $cid, 'analysis has an id' or BAIL_OUT('no analysis id');

my $setup = $ua->patch(
	"$BASE/api/analyses/$cid" => { 'Content-Type' => 'application/json' } => encode_json({
		layout => [
			{ visual => 0, x => 1, y => 1, w => 6, h => 1 },
			{ visual => 1, x => 1, y => 4, w => 6, h => 1 },
		],
	})
);
is $setup->res->code, 200, 'the starting layout is stored';
is $browser->patch_count, 1, 'one PATCH recorded before the browser starts';

$browser->navigate("/a/$cid");

my $READY = <<'JS';
var s = document.getElementById('visual-size-0');
return s ? (s.options[s.selectedIndex].textContent || '') : '';
JS

is $browser->wait_for(sub { $browser->js($READY) }, timeout => 10),
	'Half width, 1 row high', 'the canvas rendered at the saved size';

# The multiplication sign on the card, spelled with chr() so the file means the
# same character with or without a UTF-8 layer.
my $TIMES = chr(0xD7);

# Everything the page shows about the first card, read back after each press.
# The probe escapes non-ASCII before JSON-encoding, as the browser has already
# decoded the string by the time the test sees it.
my $STATE = <<'JS';
function asciiSafe(text) {
	return String(text).replace(/[^\x20-\x7e]/g, function (c) {
		return '\\u' + ('0000' + c.charCodeAt(0).toString(16)).slice(-4);
	});
}
var card  = document.getElementById('visual-0');
var sel   = document.getElementById('visual-size-0');
var badge = card.querySelector('[data-size-badge="1"]');
var grip  = card.querySelector('.visual-resize-handle');
var cs    = getComputedStyle(card);
return asciiSafe(JSON.stringify({
	colStart  : cs.gridColumnStart,
	colEnd    : cs.gridColumnEnd,
	rowStart  : cs.gridRowStart,
	badge     : badge ? badge.textContent : '',
	badgeTitle: badge ? badge.getAttribute('title') : '',
	value     : sel.value,
	summary   : sel.options[sel.selectedIndex].textContent,
	valuenow  : grip ? grip.getAttribute('aria-valuenow') : '',
	valuemax  : grip ? grip.getAttribute('aria-valuemax') : '',
	valuetext : grip ? grip.getAttribute('aria-valuetext') : '',
	live      : document.getElementById('canvas-live').textContent,
	active    : document.activeElement
		? (document.activeElement.id || document.activeElement.getAttribute('class') || '')
		: '',
}));
JS

sub state {
	return decode_json($browser->js($STATE));
}

sub wait_state {
	my ($code, $why) = @_;
	my $seen = $browser->wait_for(sub {
		my $st = eval { state() };
		return $st if $st && $code->($st);
		return undef;
	}, timeout => 10);

	return $seen || state();
}

# Read the layout the server stored, for the card under test.
sub stored_card {
	my $layout = $ua->get("$BASE/api/analyses/$cid")->res->json->{layout} || [];
	my ($card) = grep { ($_->{visual} // '') eq '0' } @$layout;
	return $card || {};
}

my $start = state();
is $start->{colStart}, '1',        'the card starts in column 1';
is $start->{colEnd},   'span 6',   'six columns wide';
is $start->{rowStart}, '1',        'in row 1';
is $start->{badge},    "6 ${TIMES} 1", 'with its size written on it';
is $start->{value},    '',         'and the menu on its summary entry';

# ---------------------------------------------------------------------------
# Moving: the header handle takes focus, the arrow keys move the card one cell,
# Shift with an arrow key goes to that edge.  Every move is announced.
# ---------------------------------------------------------------------------
$browser->focus('#visual-0 .drag-handle[role="button"]');
like $browser->js("return document.activeElement.getAttribute('class') || '';"),
	qr/drag-handle/, 'the header handle takes focus';

$browser->press('ArrowRight');
my $moved = wait_state(sub { $_[0]{colStart} eq '2' });
is $moved->{colStart}, '2', 'ArrowRight moved the card one column right';
is $moved->{rowStart}, '1', 'and left it in its row';
is $moved->{colEnd},   'span 6', 'at the width it had';
is $moved->{live}, 'Left moved to column 2, row 1: 6 columns wide and 1 row tall',
	'the move is announced with the new position and the size it did not change';

$browser->press('ArrowRight', shift => 1);
my $edge = wait_state(sub { $_[0]{colStart} eq '7' });
is $edge->{colStart}, '7',
	'Shift+ArrowRight moved it to the last column a six-column card can start in';
is $edge->{live}, 'Left moved to column 7, row 1: 6 columns wide and 1 row tall',
	'and that move is announced too';

$browser->press('ArrowDown');
my $down = wait_state(sub { $_[0]{rowStart} eq '2' });
is $down->{rowStart}, '2', 'ArrowDown moved the card down one row';
is $down->{live}, 'Left moved to column 7, row 2: 6 columns wide and 1 row tall',
	'the row it moved to is announced';

$browser->press('ArrowUp', shift => 1);
my $top = wait_state(sub { $_[0]{rowStart} eq '1' });
is $top->{rowStart}, '1', 'Shift+ArrowUp sent it to the top edge';

$browser->press('ArrowLeft');
my $left = wait_state(sub { $_[0]{colStart} eq '6' });
is $left->{colStart}, '6', 'ArrowLeft moved it back one column';

# The moves are one debounced write, like a drag's; what is stored is where the
# card ended up, and the card that was not touched has not moved.
my $after_moves = $browser->wait_for(sub {
	$browser->patch_count > 1 ? 1 : undef;
}, timeout => 10);
ok $after_moves, 'the moves sent a PATCH';
is $browser->patch_count, 2, 'one PATCH for the whole burst of key presses';

my $moved_card = stored_card();
is $moved_card->{x}, 6, 'the stored layout has the column the card was left in';
is $moved_card->{y}, 1, 'and the row it was left in';
is $moved_card->{w}, 6, 'at the width it had';
is $moved_card->{h}, 1, 'and the height it had';

# ---------------------------------------------------------------------------
# Resizing: the corner grip.  Left and right change the width, up and down the
# height, Home and End go to the limits.  The size on the card, the menu's
# summary and the grip's own slider attributes all follow, which is what a
# screen reader and a glance have to agree on.
# ---------------------------------------------------------------------------
$browser->focus('#visual-0 .visual-resize-handle');
is $browser->js("return document.activeElement.getAttribute('class') || '';"),
	'visual-resize-handle', 'the corner grip takes focus';
is $left->{valuenow}, '6', 'the grip carries the width it started at';
is $left->{valuemax}, '7',
	'the widest it can be from column 6: seven columns';

$browser->press('ArrowLeft');
my $narrower = wait_state(sub { $_[0]{valuenow} eq '5' });
is $narrower->{colEnd},   'span 5', 'ArrowLeft narrowed the card by one column';
is $narrower->{valuenow}, '5',      'the grip reports the width it now has';
is $narrower->{badge},    "5 ${TIMES} 1", 'the card says the width it now has';
is $narrower->{badgeTitle}, '5 columns wide, 1 row high',
	'and says it in words, because five columns is no preset';
is $narrower->{summary}, '5 columns wide, 1 row high',
	'the menu summary follows the keyboard as it follows a drag';

$browser->press('Home');
my $narrowest = wait_state(sub { $_[0]{valuenow} eq '1' });
is $narrowest->{colEnd},   'span 1', 'Home took the card to its narrowest';
is $narrowest->{valuetext}, '1 column wide, 1 row high',
	'the grip reads out one column, not one columns';

$browser->press('End');
my $widest = wait_state(sub { $_[0]{valuenow} eq '7' });
is $widest->{colEnd},   'span 7', 'End took it to the widest it can be';
is $widest->{valuemax}, '7', 'which is the value the grip advertises';
is $widest->{badge},    "7 ${TIMES} 1", 'and the card says so';

$browser->press('ArrowDown');
my $taller = wait_state(sub { $_[0]{valuetext} =~ /2 rows high/ });
is $taller->{badge},    "7 ${TIMES} 2", 'ArrowDown made the card two rows high';
is $taller->{valuetext}, '7 columns wide, 2 rows high',
	'both dimensions read out together';

$browser->press('ArrowUp');
my $shorter = wait_state(sub { $_[0]{valuetext} =~ /1 row high/ });
is $shorter->{badge}, "7 ${TIMES} 1", 'ArrowUp took the height back to one row';

my $after_resize = $browser->wait_for(sub {
	$browser->patch_count > 2 ? 1 : undef;
}, timeout => 10);
ok $after_resize, 'the resize sent a PATCH';
is $browser->patch_count, 3, 'one PATCH for the whole burst of resize keys';

my $resized_card = stored_card();
is $resized_card->{x}, 6, 'the card was not moved by being resized';
is $resized_card->{w}, 7, 'the stored width is the one End chose';
is $resized_card->{h}, 1, 'and the stored height is the one ArrowUp left';

# ---------------------------------------------------------------------------
# The Size menu: a native select, reached with the keys a native select has.
# Typeahead picks a preset by its first letter; ArrowDown steps to the next one
# in the list and fires change, the same as it does when the menu is opened by
# a person.  The card's column is clamped so a wider card stays on the canvas.
# ---------------------------------------------------------------------------
# Tab reaches the menu from the handle in the header, which is the control a
# reader arriving at the card is on first.
$browser->focus('#visual-0 .drag-handle[role="button"]');
$browser->press('Tab');
is $browser->js("return document.activeElement.id;"), 'visual-size-0',
	'Tab moves focus from the header handle to the Size menu';

$browser->press('f');
my $full = wait_state(sub { $_[0]{colEnd} eq 'span 12' });
is $full->{colEnd},  'span 12', 'typing f chose Full width';
is $full->{value},   '12',      'the menu is on that preset';
is $full->{summary}, 'Full width', 'and reads as that preset';
is $full->{colStart}, '1',
	'the card moved left to column 1, the only column it fits in full width';
is $full->{badge},   "12 ${TIMES} 1", 'the card says the size it was given';
is $full->{live}, 'Left is now full width, 1 row high in column 1',
	'and the change is announced with the column it had to take';

$browser->press('ArrowDown');
my $half = wait_state(sub { $_[0]{value} eq '6' });
is $half->{colEnd},  'span 6', 'ArrowDown moved the menu to Half width';
is $half->{summary}, 'Half width', 'and the card is half width';
is $half->{badge},   "6 ${TIMES} 1", 'on the card as well';

$browser->press('ArrowDown');
my $third = wait_state(sub { $_[0]{value} eq '4' });
is $third->{colEnd},  'span 4', 'another ArrowDown reached Third width';
is $third->{summary}, 'Third width',
	'with the menu word for a third';

# "3" is typeahead for "3 rows high" - the height group, not the width one.
$browser->press('3');
my $three_high = wait_state(sub { $_[0]{badge} eq "4 ${TIMES} 3" });
is $three_high->{badge},    "4 ${TIMES} 3", 'typing 3 chose three rows high';
is $three_high->{summary},  '3 rows high',
	'the menu is on the height preset that was chosen';
is $three_high->{valuetext}, '4 columns wide, 3 rows high',
	'and the grip reports the same size';
is $three_high->{live}, 'Left is now third width, 3 rows high in column 1',
	'the height change is announced like the width one, both dimensions and the column';

# Tab from the menu goes to the grip in the card, which is the next control on
# the card: the badge is not focusable and the download button is hidden for a
# table.
$browser->press('Tab');
is $browser->js("return document.activeElement.closest('.visual-card').id;"),
	'visual-0', 'Tab moves focus off the menu to the next control in the card';

my $after_menu = $browser->wait_for(sub {
	$browser->patch_count > 3 ? 1 : undef;
}, timeout => 10);
ok $after_menu, 'the menu choices sent a PATCH';
is $browser->patch_count, 4, 'one PATCH for the whole menu sequence';

my $menu_card = stored_card();
is $menu_card->{x}, 1, 'the stored column is the clamped one';
is $menu_card->{w}, 4, 'the stored width is the third width';
is $menu_card->{h}, 3, 'and the stored height is the three rows';

# ---------------------------------------------------------------------------
# A reload renders the same sizes server-side, with no JavaScript involved,
# and does not write the layout back.
# ---------------------------------------------------------------------------
$browser->navigate("/a/$cid");

my $reloaded = wait_state(sub { $_[0]{badge} eq "4 ${TIMES} 3" });
is $reloaded->{colEnd},  'span 4', 'a reload renders the saved width';
is $reloaded->{rowStart}, '1', 'in the row it was saved in';
is $reloaded->{badge},   "4 ${TIMES} 3", 'with the size on the card';
is $reloaded->{summary}, 'Third width, 3 rows high',
	'and the menu summary names both saved dimensions';
is $browser->patch_count, 4, 'and rendering it back does not PATCH it';

done_testing();
