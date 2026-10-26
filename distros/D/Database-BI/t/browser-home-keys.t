#!/usr/bin/perl

# The home page's cards, driven from the keyboard, in a real browser.
#
# Two things on the home page were reachable with a pointer only:
#
#   - the details of a file (its type, size and modified date) were shown by a
#     tooltip on hover, and nowhere else, so a keyboard reader tabbing through
#     the same cards was told nothing about them;
#   - the trash-can button that removes an entry from the recent or saved list
#     was drawn only while the list item was hovered, but it is a real button in
#     the tab order: it could be focused while invisible.
#
# t/model.t asserts the page carries the handlers and the styles.  This test
# checks that the browser does what the page says: a card takes focus, the tip
# appears with the fetched size in it, Tab moves focus away and the tip goes,
# and focusing anywhere inside a list item draws the button that was hover-only.
#
# The fixture (t/lib/BI/Test/Browser.pm) starts the app, Firefox and Marionette;
# the whole suite runs as
#   prove -l t/browser-*.t
# and skips when there is no Firefox, or when BI_SKIP_BROWSER_TESTS is set.

use strict;
use warnings;

use Test::Most;
use FindBin qw($Bin);
use lib "$Bin/lib";
use JSON::MaybeXS qw(decode_json encode_json);

use BI::Test::Browser ();

BI::Test::Browser->plan_browser_tests(required_files => ['data/sales.csv']);

my $browser = BI::Test::Browser->new;

# ---------------------------------------------------------------------------
# A file card shows its details when it takes focus, not only when it is
# pointed at, and the details are the card's description.
# ---------------------------------------------------------------------------

$browser->navigate('/');
ok $browser->wait_for(sub { $browser->js("return !!document.querySelector('.db-card[data-path]');") }),
	'the file list rendered';

my $card = $browser->js(<<'JS');
var card = document.querySelector('.db-card[data-path]');
var tip  = card.parentNode.querySelector('.file-tooltip');
return JSON.stringify({
	describedby : card.getAttribute('aria-describedby'),
	tipId       : tip ? tip.id : '',
	role        : tip ? tip.getAttribute('role') : '',
	display     : tip ? getComputedStyle(tip).display : '',
});
JS
$card = decode_json($card);

ok $card->{tipId},           'the card has a tooltip beside it';
is $card->{describedby}, $card->{tipId}, 'and is described by that tooltip';
is $card->{role}, 'tooltip', 'which says what it is to a screen reader';
is $card->{display}, 'none', 'it is not shown before the card is reached';

$browser->focus('.db-card[data-path]');
is $browser->js("return document.activeElement.className;"), 'db-card',
	'the card takes focus';

is $browser->js(<<'JS'), 'block', 'and focusing it shows the details a pointer would see';
var card = document.querySelector('.db-card[data-path]');
return getComputedStyle(card.parentNode.querySelector('.file-tooltip')).display;
JS

# The modified date and size are fetched after the tip is shown, so they are
# what the browser announces rather than what the markup contained.
is $browser->wait_for(sub {
	my $text = $browser->js(<<'JS');
var card = document.querySelector('.db-card[data-path]');
return card.parentNode.querySelector('.file-tooltip').textContent;
JS
	return $text if defined $text && $text =~ /Modified:/;
	return undef;
}, timeout => 10) ? 1 : 0, 1, 'the fetched modified date arrives in the tip';

is $browser->js("return document.activeElement.getAttribute('aria-describedby');"),
	$card->{tipId}, 'and the focused card is still described by the tip it fills in';

# Tab away: the tip goes, as it does when the pointer leaves.
$browser->press('Tab');
is $browser->js(<<'JS'), 'none', 'Tab away hides the details again';
var card = document.querySelector('.db-card[data-path]');
return getComputedStyle(card.parentNode.querySelector('.file-tooltip')).display;
JS

# ---------------------------------------------------------------------------
# The hover-only remove button is not invisible while it has focus.
# ---------------------------------------------------------------------------

# A recent entry, written where the page reads it, so the section and its
# button exist.  The path is never fetched: the tip is lazy and this test does
# not hover the card.
# The entry as JSON text, quoted as a JavaScript string literal by the
# fixture's own quoter, so the page stores the array rather than a Perl array's
# stringification.  The quoting cannot be left to encode_json(): given the text
# it is serialising it is handed a bare scalar, which a backend without
# allow_nonref refuses with "hash- or arrayref expected (not a simple scalar)" -
# the keyboard job's failure - and given a reference to the text it refuses a
# scalar reference.  t/browser-fixture.t checks the quoter's escaping.
my $seed = encode_json([ {
	name   => 'sales',
	path   => 'data/sales.csv',
	href   => '/view/sales',
	opened => '2026-10-01 12:00:00',
} ]);

$browser->js("localStorage.setItem('bi:recent', "
	. BI::Test::Browser::_js_string($seed) . '); return 1;');
$browser->navigate('/');

ok $browser->wait_for(sub {
	$browser->js("return !!document.querySelector('#bi-recent .recent-remove');")
}, timeout => 10), 'the recent section rendered its remove button';

is $browser->js(<<'JS'), '0', 'the button is invisible while the list item is not focused';
return getComputedStyle(document.querySelector('#bi-recent .recent-remove')).opacity;
JS

$browser->focus('#bi-recent .db-card');
ok $browser->wait_for(sub {
	my $opacity = $browser->js(<<'JS');
return getComputedStyle(document.querySelector('#bi-recent .recent-remove')).opacity;
JS
	return $opacity if defined $opacity && $opacity ne '0';
	return undef;
}, timeout => 5), 'focus inside the list item reveals the button';

is $browser->js("return document.activeElement.className;"), 'db-card',
	'and the focus is the card, so the button is revealed for a reason';

# The button is still a real button, reachable and named: the point is that it
# is drawn when focus is in the item, not that it was replaced by something.
my $button = decode_json($browser->js(<<'JS'));
var b = document.querySelector('#bi-recent .recent-remove');
return JSON.stringify({
	tag   : b.tagName,
	type  : b.getAttribute('type'),
	label : b.getAttribute('aria-label'),
});
JS
is $button->{tag},   'BUTTON', 'the remove control is a button';
is $button->{type},  'button', 'which does not submit a form';
like $button->{label}, qr/sales/, 'and is named for the entry it removes';

# What this run established, for the job summary: the two things on the home
# page that used to need a pointer.
$browser->proved(
	'GET /: Tab to a file card shows the tip carrying its size, Tab away takes it'
	. ' down, and focusing anywhere inside a recent entry draws the remove button'
	. ' that is otherwise hover-only - so both are reachable without a pointer'
);

done_testing;
