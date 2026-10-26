#!/usr/bin/env perl

# New canvas from every chart route, end to end.
#
# For each chart page this drives the real New canvas panel in Firefox: open
# it, name the canvas, save, read the analysis the server stored, then open
# the canvas and read the card.  Three things are checked at each route,
# because each can be lost separately:
#
#   1. the spec the page offers (data-chart) has the route's kind and encoding;
#   2. the stored analysis kept that kind and encoding, and the chart's title;
#   3. the opened canvas has one card, titled as the chart was, whose body
#      carries the chart's own element (vis-0 for D3, map-0 for Leaflet).
#      A map needs HTML::OSM 0.12 or later on the server, so where it is not
#      installed the map case checks the note the card carries instead - one
#      assertion either way, so the route is proved on every machine.
#
# The drawing itself needs D3 or Leaflet from a CDN, which the test browser may
# not reach; the card markup and its init script are server-rendered, so they
# are checked instead.
#
#   AUTHOR_TESTING=1 prove -l t/browser-seed-canvas.t

use strict;
use warnings;

use Test::Most;
use File::Spec ();
use File::Temp qw(tempdir);
use Mojo::File qw(path);
use Mojo::JSON qw(decode_json);
use Mojo::Util qw(url_escape);
use lib 't/lib';
use BI::Test::Browser ();

BI::Test::Browser->plan_browser_tests(required_files => ['data/sales.csv']);

my $browser = BI::Test::Browser->new;
my $BASE    = $browser->base;
my $ua      = $browser->ua;

# A map card carries its Leaflet element only when the server has HTML::OSM 0.12
# or later: without it the card is the note saying so, which is a state of this
# page rather than a failure of it.  The map case below is asserted in whichever
# state the machine is in, so this file proves every route on the keyboard job's
# runner too.
my $have_renderer = eval { require HTML::OSM; HTML::OSM->VERSION(0.12); 1 };

# A map needs coordinates; every other route uses the fixture table.
my $dir    = tempdir(CLEANUP => 1);
my $places = File::Spec->catfile($dir, 'places.csv');
path($places)->spurt(
	"name,latitude,longitude\n"
	. "Alpha,51.33,1.42\n"
	. "Beta,51.92,0.75\n"
);

my @cases = (
	{
		label  => 'bar',
		url    => '/bar?l=table:sales&cat=region&val=amount',
		kind   => 'bar',
		encode => { cat => 'region', value => 'amount' },
		body   => 'vis-0',
	},
	{
		label  => 'pie',
		url    => '/pie?l=table:sales&cat=region&val=amount',
		kind   => 'pie',
		encode => { cat => 'region', value => 'amount' },
		body   => 'vis-0',
	},
	{
		label  => 'graph',
		url    => '/graph?l=table:sales&x=sale_date&y=amount',
		kind   => 'graph',
		encode => { x => 'sale_date', y => 'amount' },
		body   => 'vis-0',
	},
	{
		label  => 'line alias',
		url    => '/line?l=table:sales&x=sale_date&y=amount',
		kind   => 'graph',
		encode => { x => 'sale_date', y => 'amount' },
		body   => 'vis-0',
	},
	{
		label  => 'scatter',
		url    => '/scatter?l=table:sales&x=amount&y=id',
		kind   => 'scatter',
		encode => { x => 'amount', y => 'id' },
		body   => 'vis-0',
	},
	{
		label  => 'heatmap',
		url    => '/heatmap?l=table:sales&x=region&y=product&val=amount',
		kind   => 'heatmap',
		encode => { x => 'region', y => 'product', value => 'amount' },
		body   => 'vis-0',
	},
	{
		label  => 'stacked',
		url    => '/stacked?l=table:sales&cat=region&seg=product&val=amount',
		kind   => 'stacked',
		encode => { cat => 'region', series => 'product', value => 'amount' },
		body   => 'vis-0',
	},
	{
		label  => 'combo',
		url    => '/combo?l=table:sales&cat=region&bar_val=amount&line_val=id',
		kind   => 'combo',
		encode => { x => 'region', bar => 'amount', line => 'id' },
		body   => 'vis-0',
	},
	{
		label  => 'treemap',
		url    => '/treemap?l=table:sales&group=product&size=amount',
		kind   => 'treemap',
		encode => { cat => 'product', value => 'amount' },
		body   => 'vis-0',
	},
	{
		label  => 'histogram',
		url    => '/histogram?l=table:sales&col=amount',
		kind   => 'histogram',
		encode => { value => 'amount' },
		body   => 'vis-0',
	},
	{
		label  => 'map',
		url    => '/map?l=' . url_escape("path:$places") . '&lat=latitude&lon=longitude',
		kind   => 'map',
		encode => { lat => 'latitude', lon => 'longitude' },
		body   => 'map-0',
	},
);

for my $case (@cases) {
	subtest $case->{label} => sub {
		$browser->navigate($case->{url});
		ok $browser->wait_for(sub { $browser->find('#new-canvas-btn') }),
			"$case->{label}: the chart page offers New canvas";

		my $offered_json = $browser->js(
			"var el = document.getElementById('new-canvas-panel');"
			. "return el ? el.getAttribute('data-chart') : '';"
		);
		ok length($offered_json // ''), "$case->{label}: the page carries a chart spec";
		my $offered = length($offered_json // '') ? decode_json($offered_json) : {};

		is $offered->{kind}, $case->{kind},
			"$case->{label}: the spec names the chart kind";
		is_deeply $offered->{encode}, $case->{encode},
			"$case->{label}: the spec carries the chart encoding";

		$browser->click('#new-canvas-btn');
		$browser->send_keys('#new-canvas-name', "Seed: $case->{label}");
		$browser->click('#new-canvas-save');

		my $href = $browser->wait_for(
			sub {
				my $seen = $browser->js(
					"var a = document.getElementById('new-canvas-link');"
					. "return a && !a.hidden ? a.href : '';"
				);
				return $seen if defined $seen && length $seen;
				return undef;
			},
			timeout => 10,
		);

		like $href, qr{/a/[A-Za-z0-9]+},
			"$case->{label}: the page reports where the canvas was saved";
		my ($id) = ($href // '') =~ m{/a/([^/?#]+)};
		ok $id, "$case->{label}: the canvas has an id"
			or BAIL_OUT("$case->{label}: no canvas id");

		my $analysis = $ua->get("$BASE/api/analyses/$id")->res->json;
		is scalar @{ $analysis->{visuals} || [] }, 1,
			"$case->{label}: the canvas starts with one visual";

		my $visual = $analysis->{visuals}[0] || {};
		is $visual->{kind}, $case->{kind},
			"$case->{label}: the stored visual is the chart";
		is_deeply $visual->{encode}, $case->{encode},
			"$case->{label}: the stored encoding is the chart's";
		is $visual->{title}, $offered->{title},
			"$case->{label}: the stored title is the chart's title";

		$browser->navigate("/a/$id");
		my $cards = $browser->wait_for(
			sub {
				my $n = $browser->js("return document.querySelectorAll('.visual-card').length;");
				return (defined($n) && $n == 1) ? $n : undef;
			},
			timeout => 10,
		);
		is $cards, 1, "$case->{label}: the canvas opens with one card";

		is $browser->js(
			"var c = document.querySelector('.visual-card');"
			. "return c ? c.getAttribute('data-visual') : '';"
		), '0', "$case->{label}: the card is the chart, at index 0";

		is $browser->js(
			"var t = document.querySelector('.visual-card-title');"
			. "return t ? t.textContent : '';"
		), $offered->{title}, "$case->{label}: the card is titled as the chart was";

		if ($case->{kind} eq 'map' && !$have_renderer) {
			# The map card is the map's card, and its body is the note saying
			# what is missing rather than a Leaflet element.  Checked rather
			# than skipped, so the map route still proves it made a map card
			# on a machine with no renderer; t/browser-canvas-map-degraded.t
			# is the page test for what the note says and how it looks.
			is $browser->js(
				"var notes = document.querySelectorAll('#visual-0 .map-note');"
				. "for (var i = 0; i < notes.length; i++) {"
				. "  if ((notes[i].getAttribute('data-key') || '').indexOf('error_map_renderer_') === 0) return 1;"
				. "}"
				. "return 0;"
			), 1, "$case->{label}: without HTML::OSM 0.12 the card carries the note instead of the map";
		} else {
			is $browser->js("return document.getElementById('$case->{body}') ? 1 : 0;"), 1,
				"$case->{label}: the card body is the chart's own element";
		}
	};
}

# What this run established, for the job summary: the routes are named, because
# a green run of this file is otherwise indistinguishable from one that drove a
# single chart page.
$browser->proved(
	'New canvas driven from each chart route (' . join(', ', map { $_->{label} } @cases) . '):'
	. ' the panel saved the kind and encoding the page offered, and the canvas it'
	. ' opened has one card, titled as the chart, carrying the chart\'s own element'
	. ($have_renderer ? '' : ' - with the map case carrying the note that says HTML::OSM 0.12 is needed, this machine having none')
);

done_testing();
