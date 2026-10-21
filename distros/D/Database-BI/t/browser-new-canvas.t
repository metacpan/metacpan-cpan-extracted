#!/usr/bin/env perl

# New canvas takes the current table with it.
#
# A canvas with no visuals is not a canvas.  This test drives the real New
# canvas panel from a table page, waits for the link the page offers after a
# successful save, reads the stored analysis, and opens the canvas.  The card
# must be there, titled for the table, with the columns the reader was looking
# at.
#
# The app, Firefox and Marionette come from BI::Test::Browser (t/lib/BI/Test/
# Browser.pm), so this runs on any machine with Firefox and skips otherwise.
#
#   AUTHOR_TESTING=1 prove -l t/browser-new-canvas.t

use strict;
use warnings;

use Test::Most;
use FindBin qw($Bin);
use lib "$Bin/lib";

use BI::Test::Browser ();

BI::Test::Browser->plan_browser_tests(required_files => ['data/sales.csv']);

my $browser = BI::Test::Browser->new;
my $BASE    = $browser->base;
my $ua      = $browser->ua;

$browser->navigate('/view/sales');

ok $browser->wait_for(sub { $browser->find('#btn-save-analysis') }),
	'the table page has a New canvas button';

$browser->click('#btn-save-analysis');
$browser->send_keys('#save-analysis-name-inp', 'Browser New Canvas');
$browser->click('#btn-do-save-analysis');

my $href = $browser->wait_for(sub {
	my $seen = $browser->js(
		"var a = document.getElementById('save-analysis-link');"
		. "return a && !a.hidden ? a.href : '';"
	);
	return $seen if defined $seen && length $seen;
	return undef;
}, timeout => 10);

like($href, qr{/a/[A-Za-z0-9]+}, 'the page reports where the canvas was saved');
my ($id) = ($href // '') =~ m{/a/([^/?#]+)};
ok($id, 'the canvas has an id') or BAIL_OUT('no canvas id');

my $analysis = $ua->get("$BASE/api/analyses/$id")->res->json;
is(ref $analysis->{visuals}, 'ARRAY', 'the saved canvas has a visuals list');
is(scalar @{ $analysis->{visuals} || [] }, 1,
	'a new canvas starts with one visual');

my $visual = $analysis->{visuals}[0] || {};
is($visual->{kind}, 'table', 'the first visual is the current table');
is($visual->{title}, 'Sales', 'the card is titled for the table');
is_deeply(
	$visual->{encode}{columns},
	[qw(id product region sales_rep amount sale_date)],
	'the card keeps the columns that were on screen',
);

$browser->navigate("/a/$id");

my $cards = $browser->wait_for(
	sub { $browser->js("return document.querySelectorAll('.visual-card').length;") },
	timeout => 10,
);
is($cards, 1, 'the canvas opens with one card, not an empty page');

my $title = $browser->js(
	"var el = document.querySelector('.visual-card-title');"
	. "return el ? el.textContent : '';"
);
is($title, 'Sales', 'the card names the table');

my $body = $browser->js(
	"var el = document.querySelector('.visual-card-body');"
	. "return el ? el.textContent : '';"
);
like($body, qr/Widget A/, 'the card renders the table rows');
like($body, qr/sales_rep/, 'the card renders the table headings');

# ---------------------------------------------------------------------------
# A chart page creates a chart card, not a table card.
# ---------------------------------------------------------------------------
$browser->navigate('/pie?l=table:sales&cat=region&val=amount');

ok $browser->wait_for(sub { $browser->find('#new-canvas-btn') }),
	'the chart page has a New canvas button';

$browser->click('#new-canvas-btn');
$browser->send_keys('#new-canvas-name', 'Browser Pie Canvas');
$browser->click('#new-canvas-save');

my $chart_href = $browser->wait_for(sub {
	my $seen = $browser->js(
		"var a = document.getElementById('new-canvas-link');"
		. "return a && !a.hidden ? a.href : '';"
	);
	return $seen if defined $seen && length $seen;
	return undef;
}, timeout => 10);

like($chart_href, qr{/a/[A-Za-z0-9]+}, 'the chart page reports where the canvas was saved');
my ($chart_id) = ($chart_href // '') =~ m{/a/([^/?#]+)};
ok($chart_id, 'the chart canvas has an id') or BAIL_OUT('no chart canvas id');

my $chart_analysis = $ua->get("$BASE/api/analyses/$chart_id")->res->json;
is(scalar @{ $chart_analysis->{visuals} || [] }, 1,
	'the chart canvas starts with one visual');

my $chart_visual = $chart_analysis->{visuals}[0] || {};
is($chart_visual->{kind}, 'pie', 'the first visual is the chart, not a table');
is($chart_visual->{title}, 'amount by region', 'the card keeps the chart title');
is_deeply($chart_visual->{encode}, { cat => 'region', value => 'amount' },
	'the chart keeps its category and value columns');
is($chart_visual->{options}{scheme}, 'tableau10', 'the chart keeps its colour scheme');

$browser->navigate("/a/$chart_id");

my $chart_cards = $browser->wait_for(
	sub { $browser->js("return document.querySelectorAll('.visual-card').length;") },
	timeout => 10,
);
is($chart_cards, 1, 'the chart canvas opens with one card');

my $chart_title = $browser->js(
	"var el = document.querySelector('.visual-card-title');"
	. "return el ? el.textContent : '';"
);
is($chart_title, 'amount by region', 'the card names the chart');

my $chart_body = $browser->js(
	"var el = document.querySelector('.visual-card-body');"
	. "return el ? el.textContent : '';"
);
like($chart_body, qr/North/, 'the pie card renders its categories');

like(
	$browser->js("return !!document.querySelector('.visual-card-body svg');"),
	qr/^(?:1|true)$/,
	'the card renders a chart, not a table',
);

# ---------------------------------------------------------------------------
# Add current view: a second table or chart is appended on the canvas itself.
# ---------------------------------------------------------------------------
ok $browser->wait_for(sub { $browser->find('#btn-add-current') }),
	'the canvas has an Add current view button';

$browser->click('#btn-add-current');
is($browser->js("var p = document.getElementById('ac-panel'); return p && !p.hidden ? 1 : 0;"), 1,
	'the button opens the add panel');

$browser->js(
	"var k = document.getElementById('ac-kind');"
	. "k.value = 'bar'; k.dispatchEvent(new Event('change'));"
	. "return k.value;"
);
is($browser->js("var f = document.getElementById('ac-cat').closest('.ac-field'); return f.hidden ? 0 : 1;"), 1,
	'choosing a bar chart shows the bar columns');

$browser->js(
	"document.getElementById('ac-cat').value = 'region';"
	. "document.getElementById('ac-value').value = 'amount';"
	. "document.getElementById('ac-title-inp').value = 'Regions added here';"
	. "window.__canvasStayed = 1;"
	. "return 1;"
);
$browser->js(
	"window.__announcements = [];"
	. "var live = document.getElementById('canvas-live');"
	. "new MutationObserver(function () {"
	. "  window.__announcements.push(live.textContent);"
	. "}).observe(live, { childList: true, subtree: true, characterData: true });"
	. "return 1;"
);
$browser->click('#ac-add-btn');

my $added_cards = $browser->wait_for(
	sub {
		my $n = $browser->js("return document.querySelectorAll('.visual-card').length;");
		return (defined($n) && $n == 2) ? $n : undef;
	},
	timeout => 15,
);
is($added_cards, 2, 'the canvas comes back with the new card appended');
like($browser->js("return window.location.pathname;"), qr{^/a/}, 'the reader stays on the same canvas');

is $browser->js("return window.__canvasStayed || 0;"), 1,
	'the card was added without reloading the canvas';
is $browser->js("return document.getElementById('canvas-grid').lastElementChild.id;"),
	'visual-1', 'the new card is the last one in the grid';
is $browser->js("return document.activeElement && document.activeElement.id;"),
	'visual-1', 'focus moved to the new card';
is $browser->js(
	"var c = document.activeElement;"
	. "var t = document.getElementById(c.getAttribute('aria-labelledby'));"
	. "return c.getAttribute('aria-labelledby') + '|' + (t ? t.textContent : '');"
), 'visual-title-1|Regions added here', 'and is named by the card title for a screen reader';

like(
	$browser->js("return (window.__announcements || []).join('\\n');"),
	qr/Bar chart "Regions added here" added at the end of the canvas\. 2 visuals on the canvas\./,
	'the status region announces the card and the new count',
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

is $browser->js(
	"var s = document.querySelector('#visual-1 svg'); return s ? s.id : '';"
), 'vis-1', 'the appended chart draws into an element of its own';is $browser->js(
	"var s = document.querySelector('#visual-1 .visual-card-body script');"
	. "return s && s.textContent.indexOf('#vis-1') >= 0 ? 1 : 0;"
), 1, 'the card carries the init script for its own element';

# The chart is D3, loaded from a CDN.  With it the page can say the drawing is
# finished, and the SVG has shapes to prove it; without it the page has to name
# the missing library rather than leave the reader waiting for a drawing.
my $have_d3 = $browser->js("return typeof d3;") eq 'object';
if ($have_d3) {
	like($outcome, qr/Bar chart "Regions added here" finished drawing\./,
		'the status region says when the chart has finished drawing');
	is $browser->js("return document.querySelectorAll('#visual-1 svg rect').length > 0 ? 1 : 0;"), 1,
		'and the chart is drawn, not an empty card';
} else {
	like($outcome,
		qr/Bar chart "Regions added here" was added, but D3, the chart library, did not load, so nothing was drawn\./,
		'without D3 the status region names the library that did not load');
}

my $titles = $browser->js(
	"return Array.prototype.map.call(document.querySelectorAll('.visual-card-title'),"
	. "function (e) { return e.textContent; }).join('|');"
);
like($titles, qr/Regions added here/, 'the appended card is titled as chosen');

my $with_chart = $ua->get("$BASE/api/analyses/$chart_id")->res->json;
is(scalar @{ $with_chart->{visuals} || [] }, 2, 'the chart was appended to the saved canvas');
is($browser->js("return document.querySelectorAll('.visual-count')[0].textContent.trim();"),
	'2 visuals', 'the toolbar count was updated in place');
is($with_chart->{visuals}[1]{kind}, 'bar', 'the appended visual is a bar chart');
is_deeply($with_chart->{visuals}[1]{encode},
	{ cat => 'region', value => 'amount' },
	'the appended chart keeps the chosen columns');
is($with_chart->{visuals}[1]{title}, 'Regions added here',
	'the appended chart keeps its title');

# A chart appended when D3 is not there says so by name, instead of being
# announced as added and then never appearing.  Forced only when the CDN was
# reachable in the first place; otherwise the first append already took this
# path and was checked above.
SKIP: {
	skip 'the CDN was already missing for the first append', 4 unless $have_d3;

	$browser->js("window.__d3 = window.d3; window.d3 = undefined; return 1;");
	$browser->click('#btn-add-current');
	$browser->js(
		"var k = document.getElementById('ac-kind');"
		. "k.value = 'bar'; k.dispatchEvent(new Event('change'));"
		. "document.getElementById('ac-cat').value = 'region';"
		. "document.getElementById('ac-value').value = 'amount';"
		. "document.getElementById('ac-title-inp').value = 'No D3 here';"
		. "return 1;"
	);
	$browser->click('#ac-add-btn');

	my $failed = $browser->wait_for(
		sub {
			my $said = $browser->js("return (window.__announcements || []).join('\\n');");
			return (defined($said) && $said =~ /No D3 here.*did not load/s) ? $said : undef;
		},
		timeout => 15,
	);
	like($failed,
		qr/Bar chart "No D3 here" was added, but D3, the chart library, did not load, so nothing was drawn\./,
		'a chart whose library is missing is announced by name');
	is($browser->js("return document.querySelectorAll('.visual-card').length;"), 3,
		'and the card is still on the canvas, unbroken');
	$browser->js("window.d3 = window.__d3; return 1;");
}

# Offline, the finished-drawing announcement is still checked: stand in for D3
# so the card passes the library check, then put a shape where the chart would
# have drawn one.  The page must notice the shape and say the drawing finished.
SKIP: {
	skip 'the real D3 was available and the drawing was checked above', 3 if $have_d3;

	$browser->js("window.d3 = {}; return 1;");
	$browser->click('#btn-add-current');
	$browser->js(
		"var k = document.getElementById('ac-kind');"
		. "k.value = 'bar'; k.dispatchEvent(new Event('change'));"
		. "document.getElementById('ac-cat').value = 'region';"
		. "document.getElementById('ac-value').value = 'amount';"
		. "document.getElementById('ac-title-inp').value = 'Stub drawn';"
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
	is($stub_card, 3, 'the card with a stand-in library is appended');

	is($browser->js(
		"var svg = document.querySelector('#visual-2 svg');"
		. "if (!svg) return 0;"
		. "var r = document.createElementNS('http://www.w3.org/2000/svg', 'rect');"
		. "r.setAttribute('width', '10'); r.setAttribute('height', '10');"
		. "svg.appendChild(r); return 1;"
	), 1, 'a drawn shape appears in the card');

	my $drawn = $browser->wait_for(
		sub {
			my $said = $browser->js("return (window.__announcements || []).join('\\n');");
			return (defined($said) && $said =~ /Stub drawn" finished drawing/) ? $said : undef;
		},
		timeout => 15,
	);
	like($drawn, qr/Bar chart "Stub drawn" finished drawing\./,
		'and the page announces that the drawing has finished');
}

done_testing();
