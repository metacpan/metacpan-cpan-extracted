#!/usr/bin/env perl

# Phase 6.1/6.2 of BI-Phase6.md: GET /map renders a map either from coordinate
# columns or from a location column geocoded with Geo::Coder::Free.
#
# The geocoder here is a stub handed in through the app config, so the test
# needs no geocoder, no geocoding data and no network: it can watch what the
# page asked, and it can check that a second request over the same column asks
# nothing because the answers were remembered in the model store.
#
#   prove -l t/map.t

use strict;
use warnings;

use Test::Most;
use Test::Mojo;
use File::Spec ();
use File::Temp qw(tempdir);
use Mojo::JSON  qw(decode_json encode_json);
use Mojo::Util  qw(html_unescape url_escape);

# ---------------------------------------------------------------------------
# A geocoder stub: the two methods Database::BI::Model::Geocode asks of one,
# recording every call and answering from a table of points.
# ---------------------------------------------------------------------------

{
	package Stub::Point;

	sub new {
		my ($class, %args) = @_;
		return bless { %args }, $class;
	}
	sub latitude  { $_[0]{'latitude'} }
	sub longitude { $_[0]{'longitude'} }
	sub database  { $_[0]{'database'} }

	package Stub::Geocoder;

	sub new {
		my ($class, %args) = @_;
		return bless {
			'results' => $args{'results'} // {},
			'asked'   => [],
			'calls'   => [],
		}, $class;
	}

	sub valid_location {
		my ($self, $value) = @_;
		push @{ $self->{'asked'} }, $value;

		return 0 unless defined($value) && !ref($value) && length($value);
		return ($value =~ /\D/) ? 1 : 0;
	}

	sub geocode_many {
		my ($self, $values, %opts) = @_;

		push @{ $self->{'calls'} }, { 'values' => [ @{ $values } ], 'opts' => { %opts } };

		my %out;
		for my $value (@{ $values }) {
			$out{$value} = $self->{'results'}{$value};
		}

		return { %out, 'lookups' => scalar @{ $values } };
	}
}

# ---------------------------------------------------------------------------
# Fixtures: places with coordinates for the loc= path, and a second file of
# coordinates for the lat=/lon= path.  Rows 4 and 5 have no usable place.
# ---------------------------------------------------------------------------

sub _write_file {
	my ($path, $content) = @_;

	open(my $fh, '>', $path) or die "Cannot write $path: $!";
	print {$fh} $content;
	close($fh) or die "Cannot close $path: $!";

	return $path;
}

my $dir = tempdir(CLEANUP => 1);

my $places_csv = _write_file(File::Spec->catfile($dir, 'places.csv'),
	"id,place,amount,lat,lon\n"
	. "1,Ramsgate,10,51.33,1.42\n"
	. "2,Ramsgate,5,51.33,1.42\n"
	. "3,Earls Colne,3,51.92,0.75\n"
	. "4,,1,,\n"
	. "5,12345,2,,\n"
);

my $markup_csv = _write_file(File::Spec->catfile($dir, 'markup.csv'),
	"id,place\n"
	. "1,<b>Thing</b>\n"
);

my $range_csv = _write_file(File::Spec->catfile($dir, 'range.csv'),
	"id,place,lat,lon\n"
	. "1,A,200,1\n"
	. "2,B,201,2\n"
);

# Places that no earlier subtest has looked up, so appending a map for this
# column has to geocode rather than read the cache.
my $towns_csv = _write_file(File::Spec->catfile($dir, 'towns.csv'),
	"id,town,amount\n"
	. "1,Deal,7\n"
	. "2,Faversham,9\n"
);

# The same two places in two files, under different column names: the second
# request must be answered from the cache the first one wrote, not from the
# geocoder.
my $shared_a_csv = _write_file(File::Spec->catfile($dir, 'shared-a.csv'),
	"id,place\n"
	. "1,Hastings\n"
	. "2,Rye\n"
);

my $shared_b_csv = _write_file(File::Spec->catfile($dir, 'shared-b.csv'),
	"id,town\n"
	. "1,Rye\n"
	. "2,Hastings\n"
);

my $places_spec = 'path:' . $places_csv;
my $markup_spec = 'path:' . $markup_csv;
my $range_spec  = 'path:' . $range_csv;
my $towns_spec  = 'path:' . $towns_csv;

sub _url {
	my (%params) = @_;

	return '/map?' . join('&',
		map { $_ . '=' . url_escape($params{$_}) } sort keys %params
	);
}

# ---------------------------------------------------------------------------
# The app, with the geocode cache in a temp directory and the stub geocoder
# standing in for Geo::Coder::Free.
# ---------------------------------------------------------------------------

my $t = Test::Mojo->new('Database::BI');
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

my $model_store = File::Spec->catfile($t->app->config->{model_dir}, 'models.json');

my $stub = Stub::Geocoder->new(results => {
	'Ramsgate'            => Stub::Point->new(latitude => 51.33, longitude => 1.42, database => 'OpenAddresses'),
	'Earls Colne'         => Stub::Point->new(latitude => 51.92, longitude => 0.75, database => 'OpenAddresses'),
	'<b>Thing</b>'        => Stub::Point->new(latitude => 51.10, longitude => -0.10, database => 'Local'),
	'Deal'                => Stub::Point->new(latitude => 51.22, longitude => 1.40, database => 'OpenAddresses'),
	'Faversham'           => Stub::Point->new(latitude => 51.31, longitude => 0.89, database => 'OpenAddresses'),
	'Hastings'            => Stub::Point->new(latitude => 50.85, longitude => 0.57, database => 'OpenAddresses'),
	'Rye'                 => Stub::Point->new(latitude => 50.95, longitude => 0.73, database => 'OpenAddresses'),
});

$t->app->config->{geocoder} = $stub;

# HTML::OSM is a recommends dep; skip when absent so CI does not fail just
# because the optional renderer is not installed.
#
# 0.12 is the floor, not just installation: below it the application reports
# the renderer in the page and draws nothing, so every assertion here about
# markers, popups and Leaflet assets would fail for a reason the file cannot
# test.  The degraded page is covered by the in-process stand-in instead.
my $have_map_renderer = eval { require HTML::OSM; HTML::OSM->VERSION(0.12); 1 };
plan skip_all => 'HTML::OSM 0.12 or later is needed to draw a map'
	unless $have_map_renderer;

# ===========================================================================
# loc=<column> -- a dataset with places but no coordinates
# ===========================================================================

subtest 'GET /map?loc= renders a map from a geocoded place column' => sub {
	$t->get_ok(_url(l => $places_spec, loc => 'place'))
		->status_is(200)
		->content_type_like(qr{text/html});

	my $body = $t->tx->res->body;

	like($body, qr/<title>Map of place/, 'the page is titled after the column');
	like($body, qr/<strong>Ramsgate/, 'a resolved place is a marker popup');
	like($body, qr/<strong>Earls Colne/, 'so is the other resolved place');
	like($body, qr/2 rows/, 'a repeated place is one marker standing for two rows');
	like($body, qr/L\.marker\(\[51\.33, 1\.42\]/, 'the marker carries the resolved coordinates');
	like($body, qr/L\.marker\(\[51\.92, 0\.75\]/, 'and so does the second one');
	like($body, qr/Plotting 2 markers for 3 of 5 rows/, 'the rows without a place are counted, not plotted');
	like($body, qr/\Q51.33\E/, 'the map is drawn');

	# Leaflet's CSS and JS come from onload_render's head part, which belongs in
	# the layout's <head> and not in the body of the page.
	like($body, qr{<head>.*leaflet(?:\@[\d.]+)?/dist/leaflet\.css.*</head>}s,
		'Leaflet CSS is in the document head');

	like($body, qr/resolved by OpenAddresses/, 'the backend that answered is named');
};

subtest 'The answers are remembered, so a second request asks nothing' => sub {
	my $before = scalar @{ $stub->{'calls'} };

	is($before, 1, 'the first request made one batch call');

	$t->get_ok(_url(l => $places_spec, loc => 'place'))
		->status_is(200);

	is(scalar @{ $stub->{'calls'} }, $before,
		'the second request made no geocoder call at all');
	like($t->tx->res->body, qr/<strong>Ramsgate/,
		'and the places are still plotted, from the cache');

	ok(-f $model_store, 'the model store was written');
	my $json = do { open(my $fh, '<', $model_store) or die $!; local $/; <$fh> };
	like($json, qr/Ramsgate/, 'the resolved place is remembered in it');
	like($json, qr/"built"\s*:\s*"\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ"/, 'with when it was built');
};

subtest 'A place is geocoded once, even when another dataset names it' => sub {
	# The answers belong to the place, not to the file whose column held it:
	# the shared cache is consulted before the geocoder, so a second file gets
	# the coordinates for free even when its column has a different name.
	my $before = scalar @{ $stub->{'calls'} };

	$t->get_ok(_url(l => 'path:' . $shared_a_csv, loc => 'place'))->status_is(200);
	like($t->tx->res->body, qr/Plotting 2 markers for 2 of 2 rows/,
		'the first file plots both places');
	is(scalar @{ $stub->{'calls'} }, $before + 1,
		'and geocodes them in one batch');

	$t->get_ok(_url(l => 'path:' . $shared_b_csv, loc => 'town'))->status_is(200);
	like($t->tx->res->body, qr/Plotting 2 markers for 2 of 2 rows/,
		'the second file plots the same two places');
	is(scalar @{ $stub->{'calls'} }, $before + 1,
		'without asking the geocoder again');

	my $json   = do { open(my $fh, '<', $model_store) or die $!; local $/; <$fh> };
	my $models = decode_json($json);
	my $shared = $models->{geo}{'shared'}{'places'} || {};
	is_deeply($shared->{'Hastings'}, [50.85, 0.57], 'Hastings is in the shared cache');
	is_deeply($shared->{'Rye'},      [50.95, 0.73], 'and so is Rye');
	ok(!exists $models->{geo}{ 'path:' . $shared_b_csv . '|loc=town' },
		'no per-dataset entry was written for the second file');
};

subtest 'An older per-dataset cache is used, then moved into the shared cache' => sub {
	# A store written before the cache was shared still answers its own dataset
	# without a lookup.  Viewing it once moves those answers into the shared
	# entry, so the next dataset does not have to wait for a new lookup to
	# happen in this one.
	my $dir = tempdir(CLEANUP => 1);
	local $t->app->config->{model_dir} = $dir;

	my $spec = 'path:' . $shared_a_csv;
	_write_file(File::Spec->catfile($dir, 'models.json'), encode_json({
		version => 1,
		geo     => {
			"$spec|loc=place" => {
				places  => { 'Hastings' => [50.85, 0.57], 'Rye' => [50.95, 0.73] },
				backend => 'OpenAddresses',
				built   => '2026-10-01T00:00:00',
			},
		},
	}));

	my $before = scalar @{ $stub->{calls} };

	$t->get_ok(_url(l => $spec, loc => 'place'))->status_is(200);
	like($t->tx->res->body, qr/Plotting 2 markers for 2 of 2 rows/,
		'the old per-dataset answers are plotted');
	is(scalar @{ $stub->{calls} }, $before, 'without asking the geocoder');

	my $models = decode_json(Mojo::File->new("$dir/models.json")->slurp);
	is_deeply($models->{geo}{shared}{places}{Hastings}, [50.85, 0.57],
		'and the view moved them into the shared cache');

	$t->get_ok(_url(l => 'path:' . $shared_b_csv, loc => 'town'))->status_is(200);
	like($t->tx->res->body, qr/Plotting 2 markers for 2 of 2 rows/,
		'another dataset plots the same places');
	is(scalar @{ $stub->{calls} }, $before, 'still without a lookup');
};

subtest 'popup= adds a column to the marker popup' => sub {
	$t->get_ok(_url(l => $places_spec, loc => 'place', popup => 'amount'))
		->status_is(200);

	my $body = $t->tx->res->body;
	like($body, qr/amount: 10/, 'the popup names the requested column and its value');
};

subtest 'A place value is escaped, never injected as markup' => sub {
	$t->get_ok(_url(l => $markup_spec, loc => 'place'))
		->status_is(200);

	my $body = $t->tx->res->body;
	like($body, qr/&lt;b&gt;Thing&lt;\/b&gt;/, 'the value is escaped in the popup');
	unlike($body, qr/<strong><b>/, 'and is not emitted as markup');
	like($body, qr/&lt;b&gt;Thing/, 'the heading is escaped too');
};

# ===========================================================================
# The errors a user can actually make
# ===========================================================================

subtest 'A map with no column to map is a 400 that says what is expected' => sub {
	$t->get_ok(_url(l => $places_spec))
		->status_is(400)
		->content_like(qr/loc=<column>/, 'the message names loc=');

	$t->get_ok(_url(l => $places_spec, lat => 'lat'))
		->status_is(400)
		->content_like(qr/lon=/, 'half a coordinate pair names the missing half');

	$t->get_ok(_url(l => $places_spec, loc => 'no_such_column'))
		->status_is(400)
		->content_like(qr/Column "no_such_column"/, 'an unknown location column is named');
};

# ===========================================================================
# lat= / lon= -- coordinates already in the data
# ===========================================================================

subtest 'GET /map?lat=&lon= maps coordinate columns' => sub {
	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon'))
		->status_is(200)
		->content_type_like(qr{text/html});

	my $body = $t->tx->res->body;
	like($body, qr/L\.marker\(\[51\.33, 1\.42\]/, 'the coordinates are plotted');
	like($body, qr/L\.marker\(\[51\.92, 0\.75\]/, 'and the second point too');
	like($body, qr/Plotting 2 markers for 3 of 5 rows/, 'rows at one coordinate are one marker');
	like($body, qr/2 rows/, 'the popup says how many rows share the point');
	like($body, qr/Plotted 3 of 5 rows/, 'and the rows without a coordinate are reported');
	unlike($body, qr/resolved by/, 'no geocoder answered, so none is credited');
};

subtest 'Map pages offer New Canvas with a map spec' => sub {
	for my $case (
		[ latlon => { lat => 'lat', lon => 'lon' }, { lat => 'lat', lon => 'lon' } ],
		[ loc    => { loc => 'place' },          { loc => 'place' } ],
	) {
		my ($label, $params, $expected) = @$case;
		$t->get_ok(_url(l => $places_spec, %$params))->status_is(200);
		my $page = $t->tx->res->body;
		like($page, qr/id="new-canvas-btn"/, "$label: the New Canvas button is on the map page");

		my ($attr) = $page =~ /id="new-canvas-panel" data-chart="([^"]*)"/;
		ok(defined $attr, "$label: the map page exposes its chart spec");
		my $spec = decode_json(html_unescape($attr));
		is($spec->{kind}, 'map', "$label: the spec kind is map");
		is_deeply($spec->{encode}, $expected, "$label: the spec keeps its columns");
	}
};

subtest 'A saved map visual renders on a canvas with unique Leaflet ids' => sub {
	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Map canvas',
			datasets => [ { spec => $places_spec, alias => 'left' } ],
			visuals  => [
				{ kind => 'map', encode => { lat => 'lat', lon => 'lon' }, title => 'First map' },
				{ kind => 'map', encode => { lat => 'lat', lon => 'lon' }, title => 'Second map' },
			],
		})
	)->status_is(201)->tx->res->json->{id};

	$t->post_ok("/api/analyses/$cid/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({ kind => 'map', encode => { lat => 'lat', lon => 'lon' }, title => 'Third map' }),
	)->status_is(201)->json_is('/visual' => 2);

	$t->get_ok("/a/$cid")->status_is(200);
	my $body = $t->tx->res->body;
	like($body, qr{leaflet(?:\@[\d.]+)?/dist/leaflet\.css}, 'Leaflet CSS is in the canvas head');
	like($body, qr/id="map-0"/, 'the first map has a unique element id');
	like($body, qr/id="map-1"/, 'the second map has a unique element id');
	like($body, qr/id="map-2"/, 'a map added after saving has a unique element id');
	like($body, qr/L\.map\('map-0'\)/, 'the first map initialises its own element');
	like($body, qr/L\.map\('map-1'\)/, 'the second map initialises its own element');
	like($body, qr/L\.map\('map-2'\)/, 'the appended map initialises its own element');
	like($body, qr/class="canvas-map"/, 'the map element carries the card class');
	unlike($body, qr/L\.map\('map'\)/, 'the shared HTML::OSM id is not left behind');
	like($body, qr/Plotting 2 markers for 3 of 5 rows/, 'the card reports its plotted rows');
};

subtest 'Markers are clustered, so dense maps stay readable at low zoom' => sub {
	# A map card may plot up to map_max_markers (2000 by default).  At a low
	# zoom that many separate pins are noise, so the map page and every canvas
	# map put them in a markercluster group: a count where they overlap,
	# split as the reader zooms in, and individual markers when they are far
	# enough apart.
	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon'))->status_is(200);
	my $page = $t->tx->res->body;

	like($page, qr{unpkg\.com/leaflet\.markercluster(?:\@[\d.]+)?/dist/leaflet\.markercluster\.js},
		'the map page loads the cluster plugin');
	like($page, qr{unpkg\.com/leaflet\.markercluster(?:\@[\d.]+)?/dist/MarkerCluster\.css},
		'with its stylesheet');
	like($page, qr{unpkg\.com/leaflet\.markercluster(?:\@[\d.]+)?/dist/MarkerCluster\.Default\.css},
		'and the default cluster icons');
	like($page, qr/var clusterGroup = L\.markerClusterGroup\(\);/,
		'a cluster group holds the markers');
	like($page, qr/clusterGroup\.addLayer\(L\.marker\(\[51\.33, 1\.42\]\)/,
		'each marker is added to the group');
	like($page, qr/map\.addLayer\(clusterGroup\)/, 'and the group is added to the map');
	unlike($page, qr/L\.marker\(\[51\.33, 1\.42\]\)\.addTo\(map\)/,
		'no marker bypasses the group');

	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Clustered canvas',
			datasets => [ { spec => $places_spec, alias => 'left' } ],
			visuals  => [
				{ kind => 'map', encode => { lat => 'lat', lon => 'lon' }, title => 'First map' },
				{ kind => 'map', encode => { lat => 'lat', lon => 'lon' }, title => 'Second map' },
			],
		})
	)->status_is(201)->tx->res->json->{id};

	$t->get_ok("/a/$cid")->status_is(200);
	my $canvas = $t->tx->res->body;
	like($canvas, qr{leaflet\.markercluster}, 'a canvas with maps loads the plugin');
	my $groups = () = $canvas =~ /var clusterGroup = L\.markerClusterGroup\(\);/g;
	is($groups, 2, 'each map card has a cluster group of its own');
	like($canvas, qr/map\.addLayer\(clusterGroup\)/, 'and adds it to its own map');
	unlike($canvas, qr/L\.marker\(\[51\.33, 1\.42\]\)\.addTo\(map\)/,
		'no card bypasses clustering');
};

subtest 'A geocoded map can be appended to a canvas' => sub {
	# Appending is the one place a canvas asks the geocoder: the card is
	# rendered before it is stored, so the place column has to resolve now
	# rather than on the next page load.  The answers land in the shared place
	# cache, the same one the map page reads and writes.
	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Towns canvas',
			datasets => [ { spec => $towns_spec, alias => 'left' } ],
			visuals  => [
				{ kind => 'table', encode => { columns => [qw(id town amount)] }, title => 'Towns' },
			],
		})
	)->status_is(201)->tx->res->json->{id};

	my $before = scalar @{ $stub->{'calls'} };

	$t->post_ok("/api/analyses/$cid/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({ kind => 'map', encode => { loc => 'town' }, title => 'Towns mapped' }),
	)->status_is(201)->json_is('/visual' => 1)
		->json_is('/cf_col' => '')
		->json_like('/head' => qr{leaflet(?:\@[\d.]+)?/dist/leaflet\.js},
			'the response carries the map assets for a canvas that has no map yet')
		->json_like('/html' => qr/Plotting 2 markers for 2 of 2 rows/,
			'the appended card plots the geocoded places')
		->json_like('/html' => qr/<strong>Deal/, 'and its popup names the place');

	is(scalar @{ $stub->{'calls'} }, $before + 1,
		'appending the card geocoded the place column once');

	$t->get_ok("/a/$cid")->status_is(200);
	my $body = $t->tx->res->body;
	like($body, qr/L\.map\('map-1'\)/, 'the appended place map has its own element');
	like($body, qr/<strong>Deal/, 'and the geocoded place is on the canvas');
	like($body, qr/<strong>Faversham/, 'so is the second place');
	is(scalar @{ $stub->{'calls'} }, $before + 1,
		'rendering the canvas read the remembered answers instead of asking again');

	my $analysis = $t->ua->get("/api/analyses/$cid")->res->json;
	is($analysis->{visuals}[1]{kind}, 'map', 'the stored visual is a map');
	is_deeply($analysis->{visuals}[1]{encode}, { loc => 'town' },
		'and it keeps the place column');

	my $json = do { open(my $fh, '<', $model_store) or die $!; local $/; <$fh> };
	my $models = decode_json($json);
	my $entry  = $models->{geo}{'shared'} || {};
	is_deeply($entry->{places}{Deal}, [51.22, 1.40],
		'the answer is cached in the shared place cache');
	is_deeply($entry->{places}{Faversham}, [51.31, 0.89],
		'and so is the other place from the same canvas');
};

subtest 'A saved map card can have its columns changed in place' => sub {
	# The card keeps its index, and with it its place in the layout and its
	# title; only the encoding changes.  Both directions the map page offers
	# are covered: coordinates to a place column (geocoded here) and back.
	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Editable map canvas',
			datasets => [ { spec => $places_spec, alias => 'left' } ],
			layout   => [
				{ visual => 0, x => 1, y => 1, w => 6, h => 3 },
				{ visual => 1, x => 7, y => 1, w => 6, h => 2 },
			],
			visuals  => [
				{ kind => 'map', encode => { lat => 'lat', lon => 'lon' } },
				{ kind => 'table', encode => { columns => [qw(id place)] }, title => 'Rows' },
			],
		})
	)->status_is(201)->tx->res->json->{id};

	# Coordinates -> place column.  The card had no title of its own, so the
	# response carries the one the map derives from its new column.
	$t->patch_ok("/api/analyses/$cid/visuals/0",
		{ 'Content-Type' => 'application/json' },
		encode_json({ encode => { loc => 'place' } }),
	)->status_is(200)
		->json_is('/visual' => 0)
		->json_is('/title' => 'Map of place')
		->json_is('/kind' => 'map');

	my $loc_html = $t->tx->res->json->{html};
	like($loc_html, qr/<strong>Ramsgate/, 'the replacement plots the geocoded places');
	like($loc_html, qr/Plotting 2 markers for 3 of 5 rows/,
		'and counts the rows the places stand for');

	my $stored = $t->ua->get("/api/analyses/$cid")->res->json;
	is(scalar @{ $stored->{visuals} }, 2, 'the card was changed, not removed and appended');
	is($stored->{visuals}[0]{kind}, 'map', 'the first visual is still a map');
	is_deeply($stored->{visuals}[0]{encode}, { loc => 'place' },
		'and it keeps the place column');
	ok(!exists $stored->{visuals}[0]{title}, 'a title the reader never gave it is not invented');
	is_deeply($stored->{visuals}[1]{encode}, { columns => [qw(id place)] },
		'the card beside it is untouched');
	is_deeply($stored->{layout}, [
		{ visual => 0, x => 1, y => 1, w => 6, h => 3 },
		{ visual => 1, x => 7, y => 1, w => 6, h => 2 },
	], 'and its place on the canvas is the one it had');

	$t->get_ok("/a/$cid")->status_is(200);
	my $page = $t->tx->res->body;
	like($page, qr/Map of place/, 'the canvas titles the card after its new column');
	like($page, qr/<strong>Ramsgate/, 'and draws the places');

	# Place column -> coordinates.  The old popup names are gone with the old
	# encoding, not left beside the new markers.
	$t->patch_ok("/api/analyses/$cid/visuals/0",
		{ 'Content-Type' => 'application/json' },
		encode_json({ encode => { lat => 'lat', lon => 'lon' } }),
	)->status_is(200)
		->json_is('/title' => 'lat and lon');

	my $coord_html = $t->tx->res->json->{html};
	like($coord_html, qr/L\.marker\(\[51\.92, 0\.75\]/, 'the replacement plots the coordinates');
	unlike($coord_html, qr/<strong>Ramsgate/, 'and no longer plots places');

	$stored = $t->ua->get("/api/analyses/$cid")->res->json;
	is_deeply($stored->{visuals}[0]{encode}, { lat => 'lat', lon => 'lon' },
		'the coordinate columns are stored');

	# Refusals leave the saved card as it was.
	$t->patch_ok("/api/analyses/$cid/visuals/9",
		{ 'Content-Type' => 'application/json' },
		encode_json({ encode => { loc => 'place' } }),
	)->status_is(404);

	$t->patch_ok("/api/analyses/$cid/visuals/x",
		{ 'Content-Type' => 'application/json' },
		encode_json({ encode => { loc => 'place' } }),
	)->status_is(400);

	$t->patch_ok("/api/analyses/$cid/visuals/0",
		{ 'Content-Type' => 'application/json' },
		encode_json({ encode => { loc => 'no_such_column' } }),
	)->status_is(400);

	$t->patch_ok("/api/analyses/$cid/visuals/0",
		{ 'Content-Type' => 'application/json' },
		encode_json({ encode => { lat => 'lat' } }),
	)->status_is(400);

	$t->patch_ok("/api/analyses/$cid/visuals/0",
		{ 'Content-Type' => 'application/json' },
		encode_json({ encode => 'place' }),
	)->status_is(400);

	$t->patch_ok('/api/analyses/nosuchcanvas/visuals/0',
		{ 'Content-Type' => 'application/json' },
		encode_json({ encode => { loc => 'place' } }),
	)->status_is(404);

	$stored = $t->ua->get("/api/analyses/$cid")->res->json;
	is_deeply($stored->{visuals}[0]{encode}, { lat => 'lat', lon => 'lon' },
		'a refused change left the stored columns alone');
};

subtest 'A coordinate column wholly out of range is named, not mapped' => sub {
	$t->get_ok(_url(l => $range_spec, lat => 'lat', lon => 'lon'))
		->status_is(400)
		->content_like(qr/Column "lat"/, 'the offending column is named')
		->content_like(qr/latitude/, 'and what its values are outside of');
};

subtest 'Columns that hold no numbers are a 400, not an empty map' => sub {
	$t->get_ok(_url(l => $markup_spec, lat => 'place', lon => 'place'))
		->status_is(400)
		->content_like(qr/numeric coordinate pairs/, 'the message says what a map needs');
};

subtest 'Leaflet assets and tiles can be self-hosted for an offline deployment' => sub {
	# A deployment with no outbound network access serves the library and the
	# tiles itself.  Every asset is a config key, and both the map page and a
	# map card on a canvas have to use the configured copies rather than the CDN.
	# These config keys were added in HTML::OSM 0.11; skip on older installs
	# (0.12 is the new minimum, so this guard is now effectively always true).
	plan skip_all => 'HTML::OSM >= 0.12 required for asset URL overrides'
		unless $HTML::OSM::VERSION >= 0.12;
	local $t->app->config->{leaflet_js_url}                  = '/static/leaflet/leaflet.js';
	local $t->app->config->{leaflet_css_url}                 = '/static/leaflet/leaflet.css';
	local $t->app->config->{leaflet_cluster_js_url}          = '/static/leaflet/leaflet.markercluster.js';
	local $t->app->config->{leaflet_cluster_css_url}         = '/static/leaflet/MarkerCluster.css';
	local $t->app->config->{leaflet_cluster_default_css_url} = '/static/leaflet/MarkerCluster.Default.css';
	local $t->app->config->{tile_url} = 'https://tiles.example.test/{z}/{x}/{y}.png';

	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon'))->status_is(200);
	my $page = $t->tx->res->body;
	like($page, qr{href="/static/leaflet/leaflet\.css"}, 'the map page uses the local stylesheet');
	like($page, qr{src="/static/leaflet/leaflet\.js"}, 'and the local script');
	like($page, qr{src="/static/leaflet/leaflet\.markercluster\.js"},
		'with the local cluster plugin');
	like($page, qr{href="/static/leaflet/MarkerCluster\.css"}, 'and its stylesheet');
	like($page, qr{href="/static/leaflet/MarkerCluster\.Default\.css"},
		'and the local default cluster icons');
	like($page, qr{L\.tileLayer\('https://tiles\.example\.test/\{z\}/\{x\}/\{y\}\.png'},
		'and the configured tile server');
	unlike($page, qr{tile\.openstreetmap\.org}, 'no tile request goes to OpenStreetMap');
	unlike($page, qr{unpkg\.com}, 'nothing on the page still asks the CDN');

	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Offline map canvas',
			datasets => [ { spec => $places_spec, alias => 'left' } ],
			visuals  => [
				{ kind => 'map', encode => { lat => 'lat', lon => 'lon' }, title => 'Offline map' },
			],
		})
	)->status_is(201)->tx->res->json->{id};

	$t->get_ok("/a/$cid")->status_is(200);
	my $canvas = $t->tx->res->body;
	like($canvas, qr{src="/static/leaflet/leaflet\.js"},
		'a canvas map card uses the local script');
	like($canvas, qr{href="/static/leaflet/leaflet\.css"},
		'and the local stylesheet');
	like($canvas, qr{L\.tileLayer\('https://tiles\.example\.test/\{z\}/\{x\}/\{y\}\.png'},
		'and the configured tile server');
	unlike($canvas, qr{tile\.openstreetmap\.org}, 'and asks OpenStreetMap for no tiles');
	unlike($canvas, qr{unpkg\.com}, 'and asks the CDN for nothing');
};

subtest 'Nominatim search box is suppressed (search => 0 set by _map_data)' => sub {
	# HTML::OSM >= 0.12 added the search => 0 constructor param; _map_data always
	# passes it so no keystrokes leave the server.
	plan skip_all => 'HTML::OSM >= 0.12 required for search => 0'
		unless $HTML::OSM::VERSION >= 0.12;

	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon'))->status_is(200);
	my $body = $t->tx->res->body;
	unlike($body, qr/id="search-box"/, 'no search input in the map page');
	unlike($body, qr/id="clear-search-button"/, 'no clear-search button either');
	unlike($body, qr/nominatim\.openstreetmap\.org/, 'no Nominatim fetch in the JS');
	like($body, qr/id="reset-button"/, 'the Reset Map button is still there');
};

subtest 'max_zoom= caps the tile layer zoom' => sub {
	plan skip_all => 'HTML::OSM >= 0.12 required for max_zoom'
		unless $HTML::OSM::VERSION >= 0.12;

	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon', max_zoom => 16))
		->status_is(200);
	like($t->tx->res->body, qr/maxZoom:\s*16/, '?max_zoom=16 sets maxZoom: 16 on the tile layer');

	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon', max_zoom => 0))
		->status_is(200);
	like($t->tx->res->body, qr/maxZoom:\s*0/, '?max_zoom=0 is a legal value (zero is valid)');

	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon'))
		->status_is(200);
	unlike($t->tx->res->body, qr/maxZoom/, 'absent max_zoom= means no maxZoom option emitted');
};

subtest 'max_zoom= can come from config (map_max_zoom)' => sub {
	plan skip_all => 'HTML::OSM >= 0.12 required for max_zoom'
		unless $HTML::OSM::VERSION >= 0.12;

	local $t->app->config->{map_max_zoom} = 18;
	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon'))->status_is(200);
	like($t->tx->res->body, qr/maxZoom:\s*18/,
		'map_max_zoom config key sets maxZoom when no URL param is supplied');

	# URL param overrides config
	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon', max_zoom => 14))
		->status_is(200);
	like($t->tx->res->body, qr/maxZoom:\s*14/,
		'URL ?max_zoom= takes precedence over the config value');
};

subtest 'An unopenable source is a 404' => sub {
	$t->get_ok(_url(l => 'path:/nonexistent/nothing.csv', loc => 'place'))
		->status_is(404);
};

subtest 'Dashboard map panel exposes heat layer and zoom controls' => sub {
	# The map panel in dashboard.html.tt should contain the new options row
	# with the heatmap checkbox, weight column select, and zoom input.
	$t->get_ok('/open?path=' . url_escape($places_csv))->status_is(200);
	my $dash = $t->tx->res->body;
	like($dash, qr/id="map-opts-row"/, 'map options row is in the panel');
	like($dash, qr/id="map-heat-chk"/, 'heatmap layer checkbox is present');
	like($dash, qr/id="map-weight-sel"/, 'heatmap weight column select is present');
	like($dash, qr/id="map-zoom-inp"/, 'initial zoom input is present');
	# Weight field starts hidden; it is shown when heatmap is checked
	like($dash, qr/id="map-weight-field" hidden/, 'weight field starts hidden');
};

subtest 'Map panel colour-by select includes categorical columns' => sub {
	# Before the fix, buildColorSelect filtered to numeric-only columns.
	# Categorical columns (region) should now appear so eq/ne rules work.
	# virginia_counties.csv has a non-numeric "region" column.
	my $vc = File::Spec->catfile('data', 'virginia_counties.csv');
	SKIP: {
		skip 'data/virginia_counties.csv not found', 2 unless -f $vc;
		$t->get_ok('/open?path=' . url_escape($vc))->status_is(200);
		my $page = $t->tx->res->body;
		# The color select options are built dynamically in JS from table headers,
		# but the panel HTML must exist with the correct structure.
		like($page, qr/id="map-color-sel"/, 'colour-by select is in the page');
		# The JS function no longer filters to numeric-only: verify the
		# numeric-guard line is absent from buildColorSelect specifically.
		my $tpl = do { local $/; open(my $fh, '<', 'templates/web/en/dashboard.html.tt') or die; <$fh> };
		# Extract just the buildColorSelect function body by finding it and
		# the closing brace of the function's forEach callback.
		my ($color_fn) = ($tpl =~ /(function buildColorSelect.*?^  \})/ms);
		unlike($color_fn // '', qr/isNaN.*parseAccounting/,
			'buildColorSelect no longer has the numeric-only filter');
	}
};

subtest 'size= draws circle markers with a radius scaled from the column' => sub {
	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon', size => 'amount'))
		->status_is(200)
		->content_like(qr/L\.circleMarker\(/, 'bubble map uses L.circleMarker')
		->content_unlike(qr/data:image\/svg/, 'pins are not also drawn')
		->content_like(qr/radius:\s*30\b/, 'largest amount gets the largest radius')
		->content_like(qr/radius:\s*6\b/,  'smallest amount gets the smallest radius');
};

subtest 'size= with an unknown column is a 400' => sub {
	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon', size => 'nope'))
		->status_is(400)
		->content_like(qr/Column not found: nope/);
};

subtest 'series= colours markers by category from the named scheme' => sub {
	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon',
		series => 'place', scheme => 'set2'))
		->status_is(200)
		->content_like(qr/data:image\/svg/, 'per-marker coloured icons are emitted')
		->content_like(qr/map-legend/, 'a colour legend is shown')
		->content_like(qr/Ramsgate/, 'the legend names a category')
		->content_like(qr/#66c2a5/, 'the first set2 colour is used');

	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon',
		series => 'place', scheme => 'not-a-scheme'))
		->status_is(400)
		->content_like(qr/Unknown colour scheme/);
};

subtest 'color= and series= are mutually exclusive' => sub {
	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon',
		color => 'place', series => 'place'))
		->status_is(400)
		->content_like(qr/color= or series=/);
};

subtest 'color rules colour the markers' => sub {
	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon',
		color => 'amount', color_rule => 'gt:6:#ff0000', color_default => '#00ff00'))
		->status_is(200)
		->content_like(qr/data:image\/svg/, 'coloured marker icons are emitted')
		->content_like(qr/%23ff0000/, 'the matching rule colour is used');
};

subtest 'an absolute data_dir still resolves table: specs' => sub {
	my $dd = tempdir(CLEANUP => 1);
	_write_file(File::Spec->catfile($dd, 'places.csv'),
		"id,place,lat,lon\n1,Ramsgate,51.33,1.42\n");

	local $t->app->config->{data_dir} = $dd;

	$t->get_ok(_url(l => 'table:places', lat => 'lat', lon => 'lon'))
		->status_is(200)
		->content_like(qr/L\.marker\(/, 'the table is found under an absolute data_dir');
};

# The renderer probe is a method so both states can be produced here without
# installing or removing HTML::OSM: (0, undef) is "not installed" and
# (0, '0.11') is "installed but too old".  Hiding the module does not work -
# Test::Without::Module's @INC hook is bypassed during in-process dispatch, so
# the installed copy is still found, and the missing branch would go untested.
sub _with_renderer {
	my ($ok, $version, $code) = @_;
	no warnings 'redefine';
	local *Database::BI::Controller::Dashboard::_map_renderer_version =
		sub { $ok, $version };
	return $code->();
}

sub _fake_renderer {
	my ($ok, $version) = @_;
	return _with_renderer($ok, $version, sub {
		$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon'));
	});
}

subtest 'a missing HTML::OSM degrades instead of returning 500' => sub {
	_fake_renderer(0, undef)
		->status_is(200, 'the map page still renders')
		->content_like(qr/HTML::OSM 0\.12 or later/,
			'the warning names the version that is required')
		->content_like(qr/and it is not installed/,
			'the warning says the module is not installed')
		->content_like(qr/data-key="error_map_renderer_missing"/,
			'the warning is the missing-module message')
		->content_unlike(qr/L\.marker\(/, 'no map script is emitted')
		->content_like(qr/Plotting 2 markers/, 'the markers are still counted')
		->content_like(qr/Plotting 2 markers for 3 of 5 rows/,
			'and the rows without a coordinate are still counted');
};

subtest 'an HTML::OSM older than 0.12 degrades instead of returning 500' => sub {
	_fake_renderer(0, '0.11')
		->status_is(200, 'the map page still renders')
		->content_like(qr/HTML::OSM 0\.12 or later/,
			'the warning names the version that is required')
		->content_like(qr/installed HTML::OSM is 0\.11/,
			'the warning names the version that is installed')
		->content_like(qr/data-key="error_map_renderer_old"/,
			'the warning is the older-install message, not the missing-module one')
		->content_unlike(qr/L\.marker\(/, 'no map script is emitted')
		->content_like(qr/Plotting 2 markers/, 'the markers are still counted');
};

subtest 'a canvas map card degrades the same way' => sub {
	# A canvas draws its map cards through the same _map_data, so a card has to
	# carry the warning and the marker count too, and the page has to survive
	# with its other cards - the /map route is not the only entry point.
	$t->post_ok('/api/analyses' => json => {
		name     => 'Map degradation',
		datasets => [ { spec => $places_spec, alias => 'left' } ],
		visuals  => [
			{
				kind   => 'map',
				encode => { lat => 'lat', lon => 'lon' },
				title  => 'Map card',
			},
			# A second card, so a degrading map card is shown not to take the
			# rest of the page with it.
			{ kind => 'table', encode => {}, title => 'Table card' },
		],
	})->status_is(201, 'the canvas was saved');

	my $id = $t->tx->res->json->{id};
	ok $id, 'the canvas has an id' or return;

	# Control: with a usable renderer the same card draws markers, so the
	# assertions below cannot pass on a page that never draws a map.
	$t->get_ok("/a/$id")->status_is(200, 'the canvas renders with a usable renderer')
		->content_like(qr/L\.marker\(/, 'and its map card draws markers')
		->content_like(qr/Table card/, 'and the table card is there as well');

	for my $case (
		[ 'missing', 0, undef,  'error_map_renderer_missing', qr/and it is not installed/ ],
		[ 'too old', 0, '0.11', 'error_map_renderer_old',     qr/installed HTML::OSM is 0\.11/ ],
	) {
		my ($label, $ok, $version, $key, $text) = @$case;

		my $body = _with_renderer($ok, $version, sub {
			$t->get_ok("/a/$id")->status_is(200, "the canvas renders with $label HTML::OSM");
			return $t->tx->res->body // '';
		});

		like $body, qr/data-key="\Q$key\E"/, "$label: the card carries the $key note";
		like $body, $text, "$label: the note says which problem it is";
		unlike $body, qr/L\.marker\(/, "$label: no map is drawn on the card";
		like $body, qr/Plotting 2 markers/, "$label: the card still counts its markers";
		like $body, qr/Table card/,
			"$label: the other card on the canvas is untouched";
		like $body, qr/<td>Ramsgate<\/td>/,
			"$label: and still shows the data rows";
	}
};

done_testing();
