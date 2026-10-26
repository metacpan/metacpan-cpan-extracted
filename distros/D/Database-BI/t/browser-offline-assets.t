#!/usr/bin/perl

# Charts and maps with every asset served from the application's own origin.
#
# The other browser tests use the real D3 and Leaflet from their CDNs, and the
# fixture blocks that network so a page without them has to say so.  This test
# is the opposite case: d3_url and the leaflet_* keys point at files served by
# the app itself, and the tile layer points at the same origin.  When the real
# libraries are vendored under public/static (or BI_SELF_HOSTED_ASSETS names
# another root) the test copies those in; otherwise it uses small stand-ins
# kept in this file.  Either way the chart's own inline script draws a bar per
# datum through the asset it loaded, and the map's own inline script creates the
# Leaflet pane and asks the configured tile URL through its asset, so both
# pages have to have loaded their files and run, not merely referenced them.
#
# The vendored run is the one that draws the chart with the library a deployment
# serves, so there it also asserts the bars are that library's - the stand-in has
# no version to report and the real bundle does - and checks the page around the
# generated chart for its <html lang>.  Both charts get that treatment: the /bar
# page, whose svg HTML::D3 names after the kind, and the canvas chart card, whose
# svg is named for its visual index.  t/browser-language.t owns that attribute,
# but its fixture has no network, so none of its chart pages draw.
#
# The run writes down what it proved - which chart was drawn by which D3, and
# the language attribute that came with it - to the file BI_OFFLINE_ASSET_REPORT
# names, because a green run otherwise says only that the file passed: in a
# stand-in run the same assertions pass without the real library.  The workflow
# publishes that file to the job summary.
#
# The fixture already sends external hosts through a closed proxy.  On top of
# that, this test checks the finished page references only same-origin scripts,
# stylesheets and tiles, and that the browser recorded no external resource.
#
#   AUTHOR_TESTING=1 prove -l t/browser-offline-assets.t
#
# Skips without AUTHOR_TESTING or without Firefox, like the other browser tests.

use strict;
use warnings;

use Test::Most;
use File::Copy qw(copy);
use File::Spec ();
use File::Temp qw(tempdir);
use JSON::MaybeXS qw(decode_json encode_json);
use Mojo::Util qw(url_escape);
use lib 't/lib';
use BI::Test::Browser ();

BI::Test::Browser->plan_browser_tests;

sub _write {
	my ($path, $text) = @_;

	open(my $fh, '>', $path) or die "Cannot write $path: $!";
	print {$fh} $text;
	close($fh) or die "Cannot close $path: $!";

	return $path;
}

my $tmp = tempdir(CLEANUP => 1);

my $data_dir = File::Spec->catdir($tmp, 'data');
mkdir($data_dir) or die "mkdir $data_dir: $!";

my $csv = File::Spec->catfile($data_dir, 'sales.csv');
_write($csv,
	"id,region,amount,lat,lon\n"
	. "1,North,10,51.33,1.42\n"
	. "2,South,20,51.92,0.75\n"
);

# The libraries a deployment would copy under public/.  The D3 stand-in
# implements the part the bar chart's generated script calls; the Leaflet one
# creates the pane and records the tile layer the map asks for.
my $asset_dir = File::Spec->catdir($tmp, 'self-hosted');
mkdir($asset_dir) or die "mkdir $asset_dir: $!";

_write(File::Spec->catfile($asset_dir, 'd3.js'), <<'JS');
(function () {
	var SVG = 'http://www.w3.org/2000/svg';
	function value(v, d, i) { return typeof v === 'function' ? v(d, i) : v; }

	function Selection(nodes, parents) {
		this.nodes   = nodes   || [];
		this.parents = parents || this.nodes;
	}
	Selection.prototype.append = function (name) {
		var made = [];
		this.nodes.forEach(function (parent) {
			var el = document.createElementNS(SVG, name);
			parent.appendChild(el);
			made.push(el);
		});
		return new Selection(made);
	};
	Selection.prototype.attr = function (name, v) {
		this.nodes.forEach(function (node, i) {
			node.setAttribute(name, value(v, node.__data__, i));
		});
		return this;
	};
	Selection.prototype.style = function (name, v) {
		this.nodes.forEach(function (node, i) {
			node.style[name] = value(v, node.__data__, i);
		});
		return this;
	};
	Selection.prototype.text = function (v) {
		this.nodes.forEach(function (node, i) {
			node.textContent = value(v, node.__data__, i);
		});
		return this;
	};
	Selection.prototype.html = function (v) {
		this.nodes.forEach(function (node, i) {
			node.innerHTML = value(v, node.__data__, i);
		});
		return this;
	};
	Selection.prototype.on = function (event, cb) {
		this.nodes.forEach(function (node) { node.addEventListener(event, cb); });
		return this;
	};
	Selection.prototype.call = function (fn) {
		this.nodes.forEach(function (node) { fn(new Selection([node], [node])); });
		return this;
	};
	Selection.prototype.selectAll = function (selector) {
		var found = [];
		this.nodes.forEach(function (node) {
			Array.prototype.forEach.call(node.querySelectorAll(selector), function (child) {
				found.push(child);
			});
		});
		return new Selection(found, this.nodes);
	};
	Selection.prototype.data = function (data) {
		return new DataSelection(this.parents, data);
	};
	Selection.prototype.transition = function () { return this; };
	Selection.prototype.duration   = function () { return this; };
	Selection.prototype.delay      = function () { return this; };
	Selection.prototype.node       = function () { return this.nodes[0]; };

	function DataSelection(parents, data) {
		this.parents = parents;
		this.data    = data;
	}
	DataSelection.prototype.join = function (name) {
		var made = [];
		this.parents.forEach(function (parent) {
			this.data.forEach(function (d) {
				var el = document.createElementNS(SVG, name);
				el.__data__ = d;
				parent.appendChild(el);
				made.push(el);
			});
		}, this);
		return new Selection(made);
	};

	function select(selector) {
		if (typeof selector === 'string') {
			return new Selection(Array.prototype.slice.call(document.querySelectorAll(selector)));
		}
		return new Selection([selector], [selector]);
	}

	function scaleOrdinal(colors) {
		var domain = [];
		function scale(v) {
			var i = domain.indexOf(v);
			if (i < 0) { domain.push(v); i = domain.length - 1; }
			return colors[i % colors.length];
		}
		scale.domain = function (d) { if (d) { domain = d; } return scale; };
		return scale;
	}

	function scaleBand() {
		var domain = [], range = [0, 1], padding = 0;
		function step() { return domain.length ? (range[1] - range[0]) / domain.length : 0; }
		function scale(v) {
			var i = domain.indexOf(v);
			return range[0] + (i < 0 ? 0 : i) * step();
		}
		scale.domain    = function (d) { if (d) { domain = d; } return scale; };
		scale.range     = function (r) { if (r) { range = r; } return scale; };
		scale.padding   = function (p) { if (p !== undefined) { padding = p; } return scale; };
		scale.bandwidth = function () { return step() * (1 - padding); };
		return scale;
	}

	function scaleLinear() {
		var domain = [0, 1], range = [0, 1];
		function scale(v) {
			var span = (domain[1] - domain[0]) || 1;
			return range[0] + ((v - domain[0]) / span) * (range[1] - range[0]);
		}
		scale.domain = function (d) { if (d) { domain = d; } return scale; };
		scale.range  = function (r) { if (r) { range = r; } return scale; };
		scale.nice   = function () { return scale; };
		return scale;
	}

	function axis() {
		return function (selection) {
			selection.append('g').attr('class', 'tick');
		};
	}

	window.d3 = {
		select    : select,
		selectAll : function (s) { return select(s); },
		max       : function (data, fn) {
			var values = data.map(function (d, i) { return fn ? fn(d, i) : d; });
			return values.length ? Math.max.apply(null, values) : undefined;
		},
		scaleOrdinal : scaleOrdinal,
		scaleBand    : scaleBand,
		scaleLinear  : scaleLinear,
		axisBottom   : axis,
		axisLeft     : axis
	};
}());
JS

_write(File::Spec->catfile($asset_dir, 'leaflet.js'), <<'JS');
(function () {
	var L = window.L = window.L || {};

	L.map = function (id) {
		var node = document.getElementById(id);
		if (node) {
			var pane = document.createElement('div');
			pane.className = 'leaflet-pane';
			node.appendChild(pane);
		}
		return {
			setView    : function () { return this; },
			addLayer   : function () { return this; },
			removeLayer: function () { return this; }
		};
	};
	L.tileLayer = function (url) {
		window.__tileUrls = window.__tileUrls || [];
		window.__tileUrls.push(url);
		return { addTo: function () { return this; } };
	};
	L.marker = function () {
		return {
			bindPopup: function () { return this; },
			addTo    : function () { return this; }
		};
	};
	L.icon     = function () { return {}; };
	L.geoJSON  = function () { return { addTo: function () { return this; } }; };
	L.heatLayer = function () { return { addTo: function () { return this; } }; };
}());
JS

_write(File::Spec->catfile($asset_dir, 'leaflet.markercluster.js'), <<'JS');
(function () {
	var L = window.L = window.L || {};
	L.markerClusterGroup = function () {
		return { addLayer: function () { return this; } };
	};
}());
JS

_write(File::Spec->catfile($asset_dir, 'leaflet.css'), "#map { height: 560px; }\n");
_write(File::Spec->catfile($asset_dir, 'MarkerCluster.css'), "/* self-hosted cluster styles */\n");
_write(File::Spec->catfile($asset_dir, 'MarkerCluster.Default.css'), "/* self-hosted cluster icons */\n");

# Prefer the real libraries when they are vendored.  The paths match the ones
# the README tells a deployment to use under public/static; a developer who
# keeps them elsewhere can point BI_SELF_HOSTED_ASSETS at that root instead.
# The stand-ins remain the fallback because the test has to run in a checkout
# with no network and no vendored files.
my $vendored_root = $ENV{BI_SELF_HOSTED_ASSETS}
	// File::Spec->catdir('public', 'static');
my %vendored = (
	'd3.js'                          => [ 'd3', 'd3.min.js' ],
	'leaflet.js'                     => [ 'leaflet', 'leaflet.js' ],
	'leaflet.css'                    => [ 'leaflet', 'leaflet.css' ],
	'leaflet.markercluster.js'       => [ 'leaflet', 'leaflet.markercluster.js' ],
	'MarkerCluster.css'              => [ 'leaflet', 'MarkerCluster.css' ],
	'MarkerCluster.Default.css'      => [ 'leaflet', 'MarkerCluster.Default.css' ],
);
my @missing = grep {
	!-f File::Spec->catfile($vendored_root, @{ $vendored{$_} })
} sort keys %vendored;

if (@missing) {
	# A CI job that has just downloaded the libraries must not be able to pass
	# by quietly using the stand-ins.  This is the counterpart of
	# BI_REQUIRE_BROWSER: the run is meant to check the vendored branch, so a
	# missing file is a failure rather than a fallback.
	die "BI_REQUIRE_VENDORED_ASSETS is set but these files are missing from $vendored_root: @missing\n"
		if $ENV{BI_REQUIRE_VENDORED_ASSETS};
	diag "Using local D3/Leaflet stand-ins; not vendored under $vendored_root: @missing";
} else {
	for my $name (sort keys %vendored) {
		my $source = File::Spec->catfile($vendored_root, @{ $vendored{$name} });
		copy($source, File::Spec->catfile($asset_dir, $name))
			or die "Cannot copy $source: $!";
	}
	diag "Using vendored D3/Leaflet from $vendored_root";
}

# Which of the two runs this is.  It matters to the chart: the stand-in is a
# stub written in this file, so bars drawn through it say the page ran, while
# only the vendored files say the real library draws the chart HTML::D3
# generated.  The assertions that claim the real thing are skipped otherwise.
my $vendored_run = @missing ? 0 : 1;

# What the real-D3 assertions below establish, one line each, for the report
# this file writes at the end.  In a stand-in run nothing is added, and the
# report says so rather than leaving the reader to infer it from the skips.
my @proved;

my $browser = BI::Test::Browser->new(
	data_dir     => $data_dir,
	static_paths => [$tmp],
	app_config   => {
		d3_url                          => '/self-hosted/d3.js',
		leaflet_js_url                  => '/self-hosted/leaflet.js',
		leaflet_css_url                 => '/self-hosted/leaflet.css',
		leaflet_cluster_js_url          => '/self-hosted/leaflet.markercluster.js',
		leaflet_cluster_css_url         => '/self-hosted/MarkerCluster.css',
		leaflet_cluster_default_css_url => '/self-hosted/MarkerCluster.Default.css',
		tile_url                        => '/self-hosted/tiles/{z}/{x}/{y}.png',
	},
);

my $base = $browser->base;
my $spec = 'path:' . $csv;

# The page can only draw from these if the app actually serves them, not just
# if it writes their URLs into the markup.
for my $path (qw(
	/self-hosted/d3.js
	/self-hosted/leaflet.js
	/self-hosted/leaflet.css
	/self-hosted/leaflet.markercluster.js
	/self-hosted/MarkerCluster.css
	/self-hosted/MarkerCluster.Default.css
)) {
	is $browser->ua->get($base . $path)->res->code, 200,
		"$path is served from the app origin";
}

# Every script and stylesheet in the page must come from the app, and the
# browser must not have tried anything else.  The fixture's proxy would stop an
# external request anyway; this proves the page never asked.
sub local_assets_only {
	my ($label) = @_;

	my $urls = decode_json($browser->js(<<'JS') // '[]');
return JSON.stringify(Array.from(document.querySelectorAll('script[src],link[href]')).map(function (el) {
	return el.src || el.href;
}));
JS

	ok scalar @$urls, "$label references its scripts and stylesheets";
	for my $url (@$urls) {
		like($url, qr{\A\Q$base\E/}, "$label asset stays on the app origin: $url");
	}

	my $external = decode_json($browser->js(<<'JS') // '[]');
return JSON.stringify(Array.from(performance.getEntriesByType('resource')).map(function (entry) {
	return entry.name;
}).filter(function (url) {
	return url.indexOf(location.origin) !== 0;
}));
JS

	is_deeply($external, [], "$label made no external resource request");
}

# ---------------------------------------------------------------------------
# A chart: the local D3 loads, and the chart's own script draws a bar for each
# category.  The bars are the proof that the page ran, not that it only
# referenced a script.
# ---------------------------------------------------------------------------
$browser->navigate('/bar?l=' . url_escape($spec) . '&cat=region');

ok $browser->wait_for(sub {
	$browser->js('return typeof d3 === "object" && typeof d3.select === "function" ? 1 : 0;')
}, timeout => 10), 'the chart loaded D3 from the app origin';

my $bars = $browser->wait_for(sub {
	my $n = $browser->js("return document.querySelectorAll('#bar_chart .bc-bar').length;");
	return $n == 2 ? $n : undef;
}, timeout => 10);
is($bars, 2, 'the chart script drew a bar per category through the local D3');

is $browser->js(q{return document.querySelector('script[src*="self-hosted/d3.js"]') ? 1 : 0;}),
	1, 'the chart page points at the self-hosted D3 script';
unlike $browser->js('return document.documentElement.outerHTML;'),
	qr{cdnjs\.cloudflare\.com|unpkg\.com}, 'and names no CDN in its markup';

# Bars are drawn only where a D3 loads, and the bars above are the stand-in's
# when this checkout has no vendored files.  The vendored run is the one that
# draws them with the library a deployment serves, so it also says which
# library that was - the stand-in has no version, the real bundle reports its
# own - and checks the page around the generated chart at the same time.  The
# chart's SVG and its drawing script come from HTML::D3 rather than from the
# template, and the layout writes <html lang> before either exists;
# t/browser-language.t owns that attribute but its fixture has no network for
# D3, so its chart page never draws and cannot check the two together.
SKIP: {
	skip 'the self-hosted files are this test\'s stand-ins, so the bars above are not real D3\'s', 3
		unless $vendored_run;

	my $d3_version = $browser->js('return typeof d3.version === "string" ? d3.version : "";');
	like $d3_version, qr/\A\d+\.\d+/,
		'the chart loaded the real D3 bundle, which reports its version';

	my $drawn = $browser->js(q{return document.querySelectorAll('svg#bar_chart rect.bc-bar').length;});
	is $drawn, 2, 'and real D3 drew the generated chart: a bar per category inside its SVG';

	my $lang = $browser->js('return document.documentElement.lang || "";');
	is $lang, 'en',
		'and the page that generated that chart declares its language in <html lang>';

	push @proved, "/bar chart page: $drawn bars in svg#bar_chart, D3 $d3_version, <html lang>=$lang";
}

local_assets_only('the chart page');

# ---------------------------------------------------------------------------
# A map: the local Leaflet loads, creates the pane, and the page asks the
# configured tile URL for its tiles.  The cluster plugin comes from the same
# origin too.
#
# The map itself is drawn by the optional HTML::OSM.  Without it the page says
# so and draws nothing, which is the documented degradation rather than a
# failure of the assets: there is no Leaflet markup for the self-hosted files to
# be served into, so those assertions are N/A here, not failing.  The page's own
# summary and its freedom from CDN references are still checked, because they do
# not depend on the renderer.
# ---------------------------------------------------------------------------
my $have_renderer = eval { require HTML::OSM; HTML::OSM->VERSION(0.12); 1 };

my $TILE_URL_JS = <<'JS';
return (function () {
	if (window.__tileUrls && window.__tileUrls.length) return window.__tileUrls[0];

	/* Real Leaflet keeps the layer in map._layers; the stand-in records the URL
	   directly because it does not build a layer graph. */
	if (window.map && window.map._layers) {
		var ids = Object.keys(window.map._layers);
		for (var i = 0; i < ids.length; i++) {
			var layer = window.map._layers[ids[i]];
			if (layer && layer._url) return layer._url;
		}
	}
	return '';
}());
JS

$browser->navigate('/map?l=' . url_escape($spec) . '&lat=lat&lon=lon');

SKIP: {
	skip 'HTML::OSM 0.12 is not installed here, so the map page has no Leaflet markup to serve offline', 5
		unless $have_renderer;

	ok $browser->wait_for(sub {
		$browser->js("return document.querySelector('#map .leaflet-pane') ? 1 : 0;")
	}, timeout => 10), 'the map page drew its Leaflet pane';

	is $browser->js('
		return typeof L === "object" && typeof L.map === "function" ? 1 : 0;
	'), 1, 'the map loaded Leaflet from the app origin';
	is $browser->js('
		return typeof L === "object" && typeof L.markerClusterGroup === "function" ? 1 : 0;
	'), 1, 'and loaded the cluster plugin from the app origin';
	is $browser->js($TILE_URL_JS),
		'/self-hosted/tiles/{z}/{x}/{y}.png',
		'and asked the configured tile URL for tiles';

	# The page's only script and stylesheet are the map's, so there is nothing
	# self-hosted to account for until a map is drawn.
	local_assets_only('the map page');
}

like $browser->js("return document.querySelector('.map-summary').textContent;"),
	qr/Plotting 2 markers/, 'the map plotted the coordinate rows';
unlike $browser->js('return document.documentElement.outerHTML;'),
	qr{unpkg\.com|tile\.openstreetmap\.org}, 'and names no CDN or OSM tile host in its markup';

# ---------------------------------------------------------------------------
# A canvas with both kinds of card.  The canvas loads D3 before the grid and
# puts the Leaflet head in the layout, so both cards have to find their assets
# from the same origin and draw without the page asking elsewhere.
# ---------------------------------------------------------------------------
my $created = $browser->ua->post(
	$base . '/api/analyses' => { 'Content-Type' => 'application/json' } =>
		encode_json({
			name     => 'Offline canvas',
			datasets => [ { spec => $spec, alias => 'left' } ],
			visuals  => [
				{
					kind   => 'bar',
					encode => { cat => 'region', value => 'amount' },
					title  => 'Offline bars',
				},
				{
					kind   => 'map',
					encode => { lat => 'lat', lon => 'lon' },
					title  => 'Offline map',
				},
			],
		}),
);
is $created->res->code, 201, 'the two-card canvas was created';
my $canvas_id = $created->res->json->{id};
ok($canvas_id, 'the canvas has an id') or BAIL_OUT('no canvas id');

$browser->navigate("/a/$canvas_id");

my $cards = $browser->wait_for(sub {
	my $n = $browser->js("return document.querySelectorAll('.visual-card').length;");
	return $n == 2 ? $n : undef;
}, timeout => 10);
is($cards, 2, 'the canvas opened with a chart card and a map card');

my $canvas_bars = $browser->wait_for(sub {
	my $n = $browser->js("return document.querySelectorAll('#vis-0 .bc-bar').length;");
	return $n == 2 ? $n : undef;
}, timeout => 10);
is($canvas_bars, 2, 'the canvas chart drew through the local D3');

# The same proof the chart page gets, on the card instead of the page: this is a
# second document, a second svg, and HTML::D3 names each card's chart after its
# visual index (#vis-0) rather than after the chart kind, so the id the bars are
# found under is the canvas's own arrangement and not the chart page's.  As
# there, the stand-in reports no version, so only a vendored run can say the
# card was drawn by the library a deployment serves.
SKIP: {
	skip 'the self-hosted files are this test\'s stand-ins, so the canvas chart was not drawn by real D3', 3
		unless $vendored_run;

	my $d3_version = $browser->js('return typeof d3.version === "string" ? d3.version : "";');
	like $d3_version, qr/\A\d+\.\d+/,
		'the canvas loaded the real D3 bundle, which reports its version';

	my $drawn = $browser->js(q{return document.querySelectorAll('svg#vis-0 rect.bc-bar').length;});
	is $drawn, 2,
		'and real D3 drew that card: a bar per category inside the svg named for its index';

	my $lang = $browser->js('return document.documentElement.lang || "";');
	is $lang, 'en',
		'and the canvas carrying that card declares its language in <html lang>';

	push @proved, "canvas chart card: $drawn bars in svg#vis-0, D3 $d3_version, <html lang>=$lang";
}

# The map card is drawn by the same optional renderer, so the same rule: with
# no HTML::OSM the card reports it and draws nothing, and there is no Leaflet
# markup to check the self-hosted files against.  The chart card above and the
# canvas page itself are still checked.
SKIP: {
	skip 'HTML::OSM 0.12 is not installed here, so the canvas map card has no Leaflet markup to serve offline', 3
		unless $have_renderer;

	ok $browser->wait_for(sub {
		$browser->js("return document.querySelector('#map-1 .leaflet-pane') ? 1 : 0;")
	}, timeout => 10), 'the canvas map drew its Leaflet pane';

	is $browser->js(q{return typeof L === 'object' && typeof L.markerClusterGroup === 'function' ? 1 : 0;}),
		1, 'the canvas loaded Leaflet and the cluster plugin from the app origin';
	like $browser->js("var s = document.querySelector('#visual-1 .visual-card-body script'); return s ? s.textContent : '';"),
		qr!L\.tileLayer\('/self-hosted/tiles/\{z\}/\{x\}/\{y\}\.png'!,
		'and the canvas map asks the configured tile URL for tiles';
}
unlike $browser->js('return document.documentElement.outerHTML;'),
	qr{unpkg\.com|cdnjs\.cloudflare\.com|tile\.openstreetmap\.org},
	'and names no CDN or OSM tile host in its markup';

local_assets_only('the canvas');

# What this run established, for the job summary.  A green run of this file on
# its own says only that it passed: in a stand-in run the drawn-bar assertions
# pass too, and nothing in the log says which library drew them.  The lines are
# Markdown because the CI job appends them to $GITHUB_STEP_SUMMARY unchanged,
# and they are diag'd so a local run says the same thing.
my @report = (
	'## Offline-asset charts',
	'',
	$vendored_run
		? "- libraries: vendored, from `$vendored_root`"
		: "- libraries: the stand-ins in t/browser-offline-assets.t (nothing vendored under `$vendored_root`)",
);
push @report, @proved
	? map { "- $_" } @proved
	: '- charts proved: none - the stand-in drew them, so the real-D3 assertions were skipped';

diag($_) for @report;

# The keyboard job runs this file too, and reads the fixture's report rather
# than the one above, which belongs to the job that pins the library versions.
$browser->proved(
	'GET /bar and a canvas holding a chart card and a map card, with every'
	. ' external host refused: each page names only same-origin scripts, stylesheets'
	. ' and tiles, and the browser fetched nothing from outside'
);

if (defined(my $report_path = $ENV{BI_OFFLINE_ASSET_REPORT})) {
	open(my $fh, '>', $report_path) or die "Cannot write $report_path: $!";
	print {$fh} map { "$_\n" } @report;
	close($fh) or die "Cannot close $report_path: $!";
}

$browser->stop;

done_testing();
