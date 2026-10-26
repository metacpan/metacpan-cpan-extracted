#!/usr/bin/perl

# The chart resize grip's accessibility contract, in a headless browser.
#
# t/browser-chart-keys.t drives the grip among the other chart controls; this
# file is only about what a reader who cannot see the chart is given.  It opens
# a chart page, reaches the grip with Tab rather than by script (so the tab
# order itself is under test), and then resizes the chart one press at a time.
# After every press it reads back two things: the size the SVG is actually
# drawn at, and the value the grip announces (aria-valuenow and the
# aria-valuetext a screen reader speaks).  An announcement that drifts from the
# drawing, or a key that changes the size without saying so, fails here.
#
# The keys are WebDriver key actions through Firefox's own input stack, so the
# page's keydown handler runs because the grip has focus, not because the test
# constructed an event.  Firefox runs headless, in a child process with a
# throwaway profile, started by BI::Test::Browser (t/lib/BI/Test/Browser.pm).
#
#   prove -l t/browser-chart-a11y.t
#
# Skips when there is no Firefox, or when BI_SKIP_BROWSER_TESTS is set.

use strict;
use warnings;

use Test::Most;
use FindBin qw($Bin);
use lib "$Bin/lib";
use JSON::MaybeXS qw(decode_json);

use BI::Test::Browser ();

BI::Test::Browser->plan_browser_tests(required_files => ['data/sales.csv']);

my $browser = BI::Test::Browser->new;

$browser->navigate('/bar?l=table:sales&cat=region');
ok $browser->wait_for(sub {
	$browser->js("return !!document.querySelector('.chart-resize-handle');") ? 1 : undef;
}, timeout => 10), 'the chart page loaded and its resize grip was created';

# Everything the grip says about itself, plus the size it is describing, in one
# round trip.  Reading them together is the point: the attributes and the SVG
# are only useful as a pair.
sub grip {
	return decode_json($browser->js(<<'JS'));
var g    = document.querySelector('.chart-resize-handle');
var s    = document.getElementById('bar_chart');
var a    = document.activeElement;
var id   = g.getAttribute('aria-describedby') || '';
var help = document.getElementById(id);
var head = document.querySelector('.graph-title');

/* The chart container's content box, which is the space the chart is drawn
   in.  Its left edge is the chart's left offset on the page. */
var wrap = document.querySelector('.chart-svg-wrap');
var box  = wrap && wrap.closest ? wrap.closest('.graph-container, .pie-container, .bar-container, .heatmap-container, .scatter-container, .stacked-container, .combo-container, .treemap-container, .histogram-container') : null;
var bs   = box ? window.getComputedStyle(box) : null;
var br   = box ? box.getBoundingClientRect() : null;
var boxLeft  = br ? br.left  + (parseFloat(bs.paddingLeft)  || 0) : 0;
var boxRight = br ? br.right - (parseFloat(bs.paddingRight) || 0) : document.documentElement.clientWidth;
boxRight = Math.min(boxRight, document.documentElement.clientWidth);
var expectedMax = Math.max(200, Math.floor(boxRight - boxLeft));
return JSON.stringify({
	role        : g.getAttribute('role'),
	tabindex    : g.getAttribute('tabindex'),
	label       : g.getAttribute('aria-label'),
	describedby : id,
	helpExists  : !!help,
	helpText    : help ? help.textContent.replace(/\s+/g, ' ').trim() : '',
	orientation : g.getAttribute('aria-orientation'),
	min         : g.getAttribute('aria-valuemin'),
	max         : g.getAttribute('aria-valuemax'),
	now         : g.getAttribute('aria-valuenow'),
	text        : g.getAttribute('aria-valuetext'),
	width       : parseFloat(s.getAttribute('width')),
	height      : parseFloat(s.getAttribute('height')),
	title       : head && head.textContent ? head.textContent.replace(/\s+/g, ' ').trim() : '',
	viewport    : Math.max(200, Math.round(document.documentElement.clientWidth)),
	chartLeft   : wrap ? wrap.getBoundingClientRect().left : 0,
	boxLeft     : boxLeft,
	boxRight    : boxRight,
	expectedMax : expectedMax,
	focused     : !!a && !!a.classList && a.classList.contains('chart-resize-handle'),
});
JS
}

my $before = grip();

# ---------------------------------------------------------------------------
# The semantics, before a key is pressed.  A slider has to say what it is, what
# it controls, how far it goes and what its value means; a div with a mousedown
# handler says none of that.
# ---------------------------------------------------------------------------
is $before->{role}, 'slider', 'the grip is a slider to the accessibility tree';
is $before->{tabindex}, '0', 'and it is a focusable control';
is $before->{orientation}, 'horizontal',
	'it declares the axis left and right move along';
is $before->{min}, '200', 'the narrowest width is announced as the minimum';

is $before->{max}, "$before->{expectedMax}",
	'and the widest is the width between the chart container edges, not the window';
cmp_ok $before->{max}, '<', $before->{viewport},
	'which leaves room for the container offset that used to put the grip off screen';
cmp_ok $before->{chartLeft}, '>', 0, 'the chart starts in from the window edge, as the maximum assumes';
is $before->{now}, "$before->{width}",
	'its value is the width the chart is drawn at';
is $before->{text}, "$before->{width} pixels wide, $before->{height} pixels high",
	'and its value text names both dimensions, so the height is spoken too';

is $before->{label}, 'Resize ' . ($before->{title} || 'this chart'),
	'the grip is named for the chart it resizes';
is $before->{describedby}, 'chart-resize-help',
	'and points at the page\'s instructions';
ok $before->{helpExists}, 'which are on the page';
like $before->{helpText}, qr/arrow keys/,
	'and tell a reader that the arrow keys resize the chart';
like $before->{helpText}, qr/Home and End/,
	'including Home and End for the narrowest and widest';

# ---------------------------------------------------------------------------
# Reaching it.  The grip is appended to the page by script, so whether it is in
# the tab order is a property of the finished page, not of the markup.  Tab
# from wherever the page starts and stop when it lands on the grip; if it never
# does, the names of what was passed say where focus went instead.
# ---------------------------------------------------------------------------
my @passed;
my $reached;
for (1 .. 80) {
	$browser->press('Tab');
	my $active = eval { decode_json($browser->active()) } || {};
	my $name   = $active->{class} || $active->{id} || $active->{tag};
	push @passed, defined $name && length $name ? $name : '?';
	if (($active->{class} // '') =~ /\bchart-resize-handle\b/) {
		$reached = $active;
		last;
	}
}

ok $reached, 'Tab reaches the grip, so the keyboard can get to it'
	or diag 'focus passed: ' . join(', ', @passed);

$browser->focus('.chart-resize-handle');
ok grip()->{focused}, 'the grip holds focus before a key is pressed';

# The arrow keys on a scroll container would scroll it; on a slider they must
# resize and leave the page where it was.
my $scroll = $browser->js('return window.scrollY;');

my $start = grip();
my $w     = $start->{width};
my $h     = $start->{height};
my $max   = $start->{max} + 0;

# One press, then the size and the announcement read back together.  The wait
# is for the page's handler to have run, not for an animation.
sub resized_to {
	my ($want_w, $want_h, $note) = @_;

	my $seen = $browser->wait_for(sub {
		my $g = grip();
		return undef unless $g->{focused};
		return undef unless $g->{width} == $want_w && $g->{height} == $want_h;
		return undef unless defined $g->{now} && $g->{now} == $want_w;
		return undef unless ($g->{text} // '')
			eq "$want_w pixels wide, $want_h pixels high";
		return 1;
	}, timeout => 5);

	ok $seen, $note;
	return $seen;
}

# Home establishes a width the server never sent, so a pass cannot be the
# default being read back again.
$browser->press('Home');
resized_to(200, $h, 'Home takes the chart to its narrowest and announces both dimensions');

$browser->press('ArrowRight');
resized_to(210, $h, 'ArrowRight widens it by ten pixels and announces the new width');

$browser->press('ArrowLeft');
resized_to(200, $h, 'ArrowLeft narrows it again, with the height unchanged');

# At the narrowest the chart may be, the key has nowhere to go: the size must
# stay inside the announced range rather than becoming 190 and contradicting
# aria-valuemin.
$browser->press('ArrowLeft');
resized_to(200, $h, 'a further ArrowLeft stops at the minimum it announced');

$browser->press('ArrowDown');
resized_to(200, $h + 10, 'ArrowDown makes it ten pixels taller and says the new height');

$browser->press('ArrowUp');
resized_to(200, $h, 'ArrowUp takes the height back');

$browser->press('ArrowRight', shift => 1);
resized_to(250, $h, 'Shift+ArrowRight moves a bigger step, fifty pixels');

is $browser->js('return window.scrollY;'), $scroll,
	'and no press scrolled the page while resizing';

# ---------------------------------------------------------------------------
# The far end.  End goes to the widest the chart can be, which is the value
# aria-valuemax promised; the grip must say so rather than a width past it.
# ---------------------------------------------------------------------------
$browser->press('End');
resized_to($max, $h, 'End takes it to the full width of the window and announces that width');

is grip()->{now}, grip()->{max},
	'which is the maximum the grip had already declared';

# The point of the maximum: the grip at the widest size is on screen and is
# the element a pointer would hit there, rather than being clipped by the
# page's scroll container or sitting past the window's right edge.
my $edge = decode_json($browser->js(<<'JS'));
var g = document.querySelector('.chart-resize-handle');
var r = g.getBoundingClientRect();
var hit = document.elementFromPoint(Math.round(r.left + r.width / 2), Math.round(r.top + r.height / 2));
return JSON.stringify({
	left     : r.left,
	right    : r.right,
	viewport : document.documentElement.clientWidth,
	hit      : hit ? (hit.getAttribute('class') || hit.tagName) : '',
});
JS

cmp_ok $edge->{right}, '<=', $edge->{viewport},
	'the grip is inside the viewport at the widest size';
cmp_ok $edge->{left}, '>=', 0, 'and its left edge is on screen as well';
like $edge->{hit}, qr/\bchart-resize-handle\b/,
	'with nothing clipping the grip: it is what a pointer lands on there';

$browser->press('ArrowRight');
resized_to($max, $h, 'and ArrowRight at that end leaves the announced value truthful');

# What this run established, for the job summary: the tab order, the drawing and
# the announcement are one thing, checked press by press.
$browser->proved(
	'GET /bar: Tab reaches the chart grip, and every arrow, Home and End press'
	. ' draws the size it announces - aria-valuenow and aria-valuetext - with the'
	. ' grip still inside the viewport and on top where it is clicked'
);

done_testing();
