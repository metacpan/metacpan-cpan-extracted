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

# A place written across two columns: an address, then its country.  The
# second row has no address, so its place is the country alone; the third's
# address has spaces around it.
my $houses_csv = _write_file(File::Spec->catfile($dir, 'houses.csv'),
	"id,person,address,country\n"
	. "1,Valentin,\"Brezje 8, Cerknica\",Slovenia\n"
	. "2,Franc,,Slovenia\n"
	. "3,Marija,\"  Brezje 8, Cerknica \",Slovenia\n"
	. "4,Ana,,\n"
);

my $places_spec = 'path:' . $places_csv;
my $houses_spec = 'path:' . $houses_csv;
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
	'Brezje 8, Cerknica, Slovenia' => Stub::Point->new(latitude => 45.79, longitude => 14.36, database => 'OpenAddresses'),
	'Slovenia'            => Stub::Point->new(latitude => 46.12, longitude => 14.82, database => 'OpenAddresses'),
});

$t->app->config->{geocoder} = $stub;

# HTML::OSM is a recommends dep; skip when absent so CI does not fail just
# because the optional renderer is not installed.
#
# 0.13 is the floor, not just installation: below it the application reports
# the renderer in the page and draws nothing, so every assertion here about
# markers, popups and Leaflet assets would fail for a reason the file cannot
# test.  The degraded page is covered by the in-process stand-in instead.
my $have_map_renderer = eval { require HTML::OSM; HTML::OSM->VERSION(0.14); 1 };
plan skip_all => 'HTML::OSM 0.14 or later is needed to draw a map'
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
	like($body, qr/amount: 3/, 'the popup names the requested column and its value');
	like($body, qr{<th>amount<\\/th><\\/tr><tr><td>10<\\/td><\\/tr><tr><td>5<\\/td>},
		'and lists it for each row of a place where it differs');
	unlike($body, qr{<th>id<}, 'only the requested column');
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
	)->status_is(201)->json_is('/visual' => 2)
	 ->json_like('/html' => qr{<script\b[^>]*>\s*\(function \(\) \{},
		'a map card returned to a page comes back scoped, like every other card');

	$t->get_ok("/a/$cid")->status_is(200);
	my $body = $t->tx->res->body;
	like($body, qr{leaflet(?:\@[\d.]+)?/dist/leaflet\.css}, 'Leaflet CSS is in the canvas head');
	like($body, qr/id="map-0"/, 'the first map has a unique element id');
	like($body, qr/id="map-1"/, 'the second map has a unique element id');
	like($body, qr/id="map-2"/, 'a map added after saving has a unique element id');
	like($body, qr/L\.map\('map-0'\)/, 'the first map initialises its own element');
	like($body, qr/L\.map\('map-1'\)/, 'the second map initialises its own element');
	like($body, qr/L\.map\('map-2'\)/, 'the appended map initialises its own element');

	# A map card's script is scoped like every other card's -- two maps on one
	# page are two scripts declaring the same names -- and it is scoped where
	# every card is, by the renderer, so once rather than once per layer.
	my ($script) = $body =~ m{(<script\b[^>]*>(?:(?!</script>).)*L\.map\('map-0'\).*?</script>)}s;
	ok($script, 'the first map\'s own script is found');
	is(scalar(() = ($script // '') =~ /\(function \(\) \{/g), 1,
		'and it is closed over one function of its own, not two');
	like($script // '', qr{\A<script\b[^>]*>\s*\(function \(\) \{},
		'which is the outermost thing it does');
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
	# _map_data always passes search => 0, so no keystrokes leave the server.

	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon'))->status_is(200);
	my $body = $t->tx->res->body;
	unlike($body, qr/id="search-box"/, 'no search input in the map page');
	unlike($body, qr/id="clear-search-button"/, 'no clear-search button either');
	unlike($body, qr/nominatim\.openstreetmap\.org/, 'no Nominatim fetch in the JS');
	like($body, qr/id="reset-button"/, 'the Reset Map button is still there');
};

subtest 'max_zoom= caps the tile layer zoom' => sub {

	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon', max_zoom => 16))
		->status_is(200);
	like($t->tx->res->body, qr/maxZoom:\s*16/, '?max_zoom=16 sets maxZoom: 16 on the tile layer');

	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon', max_zoom => 0))
		->status_is(200);
	like($t->tx->res->body, qr/maxZoom:\s*0/, '?max_zoom=0 is a legal value (zero is valid)');

	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon'))
		->status_is(200);
	# The tile layer's options: fitBounds has a maxZoom of its own, the zoom it
	# fits to at most
	unlike($t->tx->res->body, qr/attribution: '(?:[^'\\]|\\.)*',\s*maxZoom/, 'absent max_zoom= means no maxZoom option emitted');
};

subtest 'max_zoom= can come from config (map_max_zoom)' => sub {

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
		->content_like(qr/var legendEntries = /, 'a colour key is drawn on the map')
		->content_like(qr/Ramsgate/, 'the key names a category')
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
		->content_like(qr/HTML::OSM 0\.14 or later/,
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

subtest 'an HTML::OSM older than 0.14 degrades instead of returning 500' => sub {
	_fake_renderer(0, '0.11')
		->status_is(200, 'the map page still renders')
		->content_like(qr/HTML::OSM 0\.14 or later/,
			'the warning names the version that is required')
		->content_like(qr/installed HTML::OSM is 0\.11/,
			'the warning names the version that is installed')
		->content_like(qr/data-key="error_map_renderer_old"/,
			'the warning is the older-install message, not the missing-module one')
		->content_unlike(qr/L\.marker\(/, 'no map script is emitted')
		->content_like(qr/Plotting 2 markers/, 'the markers are still counted');
};

# The key HTML::OSM draws on the map: its entries, groups and points, as the
# script declares them
sub _map_key_of {
	my ($body) = @_;
	my ($entries) = $body =~ /var legendEntries = (.*?);\n/;
	my ($groups)  = $body =~ /var legendGroups = (.*?);\n/;
	my ($points)  = $body =~ /var legendPoints = (.*?);\n/;
	my ($title)   = $body =~ /var legendTitle = '((?:[^'\\]|\\.)*)';/;
	return {
		entries => defined($entries) ? decode_json($entries) : undef,
		groups  => defined($groups)  ? decode_json($groups)  : undef,
		points  => $points,
		title   => $title,
	};
}

subtest 'the map has a scale bar and a key that follows the view' => sub {
	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon'))->status_is(200);
	like($t->tx->res->body, qr/L\.control\.scale\(\)\.addTo\(map\)/, 'every map has a scale bar');
	unlike($t->tx->res->body, qr/legendEntries/, 'and a map with nothing to explain has no key');
	like($t->tx->res->body, qr/map\.fitBounds\(\[\[51\.33, 0\.75\], \[51\.92, 1\.42\]\]/,
		'with no zoom= it opens on every marker');
	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon', zoom => 9))->status_is(200);
	unlike($t->tx->res->body, qr/fitBounds/, 'a zoom= is where it opens instead');

	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon', series => 'place', scheme => 'set2'))->status_is(200);
	my $body = $t->tx->res->body;
	my $key  = _map_key_of($body);
	is($key->{title}, 'place', 'a series key is titled with its column');
	is_deeply([ map { [ @{$_}{qw(label colour group)} ] } @{ $key->{entries} } ],
		[ [ 'Ramsgate', '#66c2a5', 'rule0' ], [ 'Earls Colne', '#fc8d62', 'rule1' ],
		  [ '(blank)', '#8da0cb', 'rule2' ], [ '12345', '#e78ac3', 'rule3' ] ],
		'each value, its colour, and the group its markers are given');
	is_deeply($key->{groups}, [ 'rule0', 'rule1' ],
		'the values of rows with no position have no marker, so they are never in view and never listed');
	is($key->{points}, '[[51.33,1.42,0],[51.92,0.75,1]]', 'and the key knows where each one is, to list only those in view');
	like($body, qr/var legendEmpty = 'Nothing in this view';/, 'what it says when nothing is in view');

	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon',
		color => 'amount', color_rule => 'gt:6:#ff0000', color_default => 'green'))->status_is(200);
	$key = _map_key_of($t->tx->res->body);
	is_deeply([ map { [ @{$_}{qw(label colour group)} ] } @{ $key->{entries} } ],
		[ [ 'amount > 6', '#ff0000', 'rule0' ], [ 'Other', '#008000', 'other' ] ],
		'colour rules are listed as rules, with Other; a named colour is passed as hex')
		or diag(explain($key->{entries}));
	is($key->{points}, '[[51.33,1.42,0],[51.92,0.75,1]]', 'a marker that matches no rule belongs to Other');

	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon', size => 'amount'))->status_is(200);
	$key = _map_key_of($t->tx->res->body);
	is($key->{title}, 'amount', 'a bubble key is titled with the size column');
	is_deeply([ map { [ $_->{label}, $_->{radius} ] } @{ $key->{entries} } ],
		[ [ '3', 6 ], [ '6.5', 18 ], [ '10', 30 ] ],
		'the smallest, middle and largest sizes, drawn the size their bubbles are');
	ok(!(grep { exists $_->{group} } @{ $key->{entries} }), 'sizes say what a size means anywhere, so they are always listed');

	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon', series => 'place', size => 'amount'))->status_is(200);
	$key = _map_key_of($t->tx->res->body);
	is_deeply([ map { $_->{label} } @{ $key->{entries} } ],
		[ 'Ramsgate', 'Earls Colne', '(blank)', '12345', 'amount 3', 'amount 6.5', 'amount 10' ],
		'with both, the sizes are labelled with their column');
	like($t->tx->res->body, qr/L\.circleMarker\([^)]*\]?, \{[^}]*\}\)/, 'and the bubbles are drawn');
};

subtest 'a canvas map card is coloured and sized as the map it was saved from' => sub {
	# A card stores its colour and size columns in encode, as the map page
	# saves them.  They used to be read only from the page's options, so a
	# card drew plain pins.
	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Keyed maps',
			datasets => [ { spec => $places_spec, alias => 'left' } ],
			visuals  => [
				{ kind => 'map', encode => { lat => 'lat', lon => 'lon', color => 'amount' },
				  options => { color_rules => [ { op => 'gt', val => 6, color => '#ff0000' } ], color_default => '#00ff00' },
				  title => 'Coloured' },
				{ kind => 'map', encode => { lat => 'lat', lon => 'lon', size => 'amount' }, title => 'Sized' },
				{ kind => 'map', encode => { lat => 'lat', lon => 'lon', color => 'nope', size => 'nope' }, title => 'Stale' },
			],
		})
	)->status_is(201)->tx->res->json->{id};

	$t->get_ok("/a/$cid")->status_is(200);
	my $body = $t->tx->res->body;
	my @scripts = $body =~ m{(<script\b[^>]*>(?:(?!</script>).)*?L\.map\('map-\d'\).*?</script>)}sg;
	is(scalar @scripts, 3, 'three map cards');
	like($scripts[0], qr/%23ff0000/, 'the coloured card colours a marker by its rule');
	like($scripts[0], qr/%2300ff00/, 'and the rest by its default');
	like($scripts[1], qr/L\.circleMarker\(/, 'the sized card draws bubbles');
	unlike($scripts[2], qr/L\.circleMarker\(|%23/, 'a card naming columns that are gone draws plain pins');

	is_deeply([ map { $_->{label} } @{ _map_key_of($scripts[0])->{entries} } ], [ 'amount > 6', 'Other' ],
		'the coloured card has its key');
	is(_map_key_of($scripts[1])->{title}, 'amount', 'and the sized card has one for its sizes');
	like($scripts[2], qr/L\.control\.scale/, 'every card has a scale bar');
};

subtest 'loc= repeated geocodes the columns joined with ", "' => sub {
	my $url = '/map?l=' . url_escape($houses_spec) . '&loc=address&loc=country';
	my $before = scalar @{ $stub->{calls} };

	$t->get_ok($url)->status_is(200);
	my $body = $t->tx->res->body;

	my @asked = map { @{ $_->{values} } } @{ $stub->{calls} }[ $before .. $#{ $stub->{calls} } ];
	is_deeply([ sort @asked ], [ 'Brezje 8, Cerknica, Slovenia', 'Slovenia' ],
		'the geocoder is asked for each row\'s cells joined, trimmed, without the empty ones');

	like($body, qr/<title>Map of address, country/, 'the page is titled after both columns');
	like($body, qr/from columns address, country/, 'the summary names both columns');
	like($body, qr/Plotting 2 markers for 3 of 4 rows/, 'a row with neither cell is not plotted');
	like($body, qr/L\.marker\(\[45\.79, 14\.36\]/, 'the address is plotted');
	like($body, qr/L\.marker\(\[46\.12, 14\.82\]/, 'and the row with only a country, at the country');
	like($body, qr/<strong>Brezje 8, Cerknica, Slovenia/, 'the popup names the joined place');
	unlike($body, qr/<b>address:<\/b>|<b>country:<\/b>/, 'and leaves the two columns out of its list');
	like(html_unescape($body), qr/Map: address, country/, 'the breadcrumb names both columns');

	my ($chart) = $body =~ /data-chart="([^"]*)"/;
	my $spec = decode_json(html_unescape($chart // 'null'));
	is_deeply($spec->{encode}{loc}, [qw(address country)], 'Add to canvas keeps both columns, in order');

	$t->get_ok('/map?l=' . url_escape($houses_spec) . '&loc=address&loc=nope')
		->status_is(400, 'a second column that is not there is refused')
		->content_like(qr/Column "nope" is not in this view/);

	$t->get_ok('/map?l=' . url_escape($houses_spec) . '&loc=country&loc=')
		->status_is(200, 'an empty loc= is ignored')
		->content_like(qr/<title>Map of country &#x2014;/, 'leaving the one column');

	# A canvas card stores the columns as a list, and draws the same map.
	$t->post_ok('/api/analyses' => json => {
		name     => 'Houses',
		datasets => [ { spec => $houses_spec, alias => 'left' } ],
		visuals  => [ { kind => 'map', encode => { loc => [qw(address country)] }, title => 'Houses' } ],
	})->status_is(201);
	my $id = $t->tx->res->json->{id};
	$t->get_ok("/a/$id")->status_is(200)
		->content_like(qr/L\.marker\(\[45\.79, 14\.36\]/, 'a card with two place columns plots the joined place')
		->content_like(qr/Plotting 2 markers for 3 of 4 rows/, 'and counts the same rows');

	# The map panel offers the second column, and remembers it.
	$t->get_ok('/open?path=' . url_escape($houses_csv))->status_is(200)
		->element_exists('select#map-loc2-sel[name="loc"]', 'the map panel has a "Followed by" column');
	$t->post_ok('/geo/save' => form => {
		l => $houses_spec, replace => 1, col => [qw(address country)], kind => [qw(location location_suffix)],
	})->status_is(200)->json_is('/ok' => 1);
	$t->get_ok('/geo/list?l=' . url_escape($houses_spec))
		->json_is('/columns/country/kind' => 'location_suffix', 'the second column is remembered as such')
		->json_is('/columns/address/kind' => 'location');
	$t->post_ok('/geo/save' => form => { l => $houses_spec, col => 'country', kind => 'suffix' })
		->status_is(400, 'an unknown kind is still refused');

	# Remember columns keeps the text added to each place too.
	$t->get_ok('/open?path=' . url_escape($houses_csv))
		->element_exists('input#map-loc-text-inp[name="loc_text"]', 'the panel has Add to each place');
	$t->post_ok('/geo/save' => form => {
		l => $houses_spec, replace => 1, col => 'address', kind => 'location', loc_text => '  Slovenia ',
	})->status_is(200);
	$t->get_ok('/geo/list?l=' . url_escape($houses_spec))
		->json_is('/loc_text' => 'Slovenia', 'remembered, tidied')
		->json_is('/columns/address/kind' => 'location')
		->json_hasnt('/columns/country', 'replace=1 forgot the old columns');
	$t->post_ok('/geo/save' => form => { l => $houses_spec, replace => 1, col => 'address', kind => 'location' })
		->status_is(200);
	$t->get_ok('/geo/list?l=' . url_escape($houses_spec))
		->json_hasnt('/loc_text', 'saved again without it, it is forgotten');
	$t->post_ok('/geo/save' => form => { l => $houses_spec, col => 'address', kind => 'location', loc_text => 'Slovenia' });
	$t->post_ok('/geo/delete' => form => { l => $houses_spec })->status_is(200);
	$t->get_ok('/geo/list?l=' . url_escape($houses_spec))
		->json_hasnt('/loc_text', 'Forget remembered columns forgets it too');
	$t->post_ok('/geo/save' => form => { l => $houses_spec, col => 'address', kind => 'location', loc_text => 'x' x 201 })
		->status_is(400, 'text the map would refuse is refused');
};

subtest 'the places that were not plotted can be listed, and their rows opened' => sub {
	# Ramsgate is known; Atlantis is not, and is named twice; Lyonesse is past
	# the cap of one new lookup; one row is empty and one a bare number.
	my $csv = _write_file(File::Spec->catfile($dir, 'unplotted.csv'),
		"id,place\n1,Ramsgate\n2,Atlantis\n3,Atlantis\n4,\n5,12345\n6,Lyonesse\n");
	my $spec  = "path:$csv";
	my $table = '/open?path=' . url_escape($csv);
	my $map   = '/map?l=' . url_escape($spec) . '&loc=place';

	local $t->app->config->{map_geocode_max} = 1;
	$t->get_ok($map . '&back=' . url_escape($table))->status_is(200);
	my $body = $t->tx->res->body;

	like($body, qr/data-key="warn_map_rows_skipped"/, 'the rows are said to be unplotted');
	like(html_unescape($body), qr/Plotted 1 of 6 rows; 5 could not be plotted: 1 with no place in the row, 1 whose place is a bare number, not a place name, 2 whose place was not found, 1 whose place has not been looked up yet</,
		'the note names each reason that applies, counted in rows');
	like($body, qr/<summary>List the 4 places that were not plotted<\/summary>/,
		'and the note opens onto the places, one each however many rows name it');

	my @entries = $body =~ /<tr data-reason="([^"]+)">\s*<td>(.*?)<\/td>\s*<td class="num">(.*?)<\/td>/sg;
	my @got;
	while (my ($reason, $place, $rows) = splice @entries, 0, 3) {
		my ($href) = $rows =~ /href="([^"]+)"/;
		(my $count = $rows) =~ s/<[^>]+>//g;
		push @got, [ $reason, $place, $count, html_unescape($href // '') ];
	}
	is_deeply([ map { [ @{$_}[0 .. 2] ] } @got ], [
		[ 'not_found', 'Atlantis',          '2 rows' ],
		[ 'empty',     '<em>(empty)</em>',  '1 row'  ],
		[ 'refused',   '12345',             '1 row'  ],
		[ 'later',     'Lyonesse',          '1 row'  ],
	], 'in row order, each with its reason and how many rows it stands for');
	like($body, qr/Not looked up yet; it will be tried next time/, 'the reasons are said in words');

	my ($atlantis, $empty) = map { $_->[3] } @got[0, 1];
	like($atlantis, qr/\A\Q$table\E&f=place%3Aeq%3AAtlantis&back2=/, 'a place links to the table it came from, filtered to it');
	like($empty, qr/&f=place%3Aempty&/, 'an empty cell to its empty rows');

	# One link opens every unplotted row at once, whatever the reason.
	my ($all) = $body =~ /<a class="map-unplotted-all" href="([^"]+)">([^<]+)</;
	like($body, qr/>Show the 5 rows that were not plotted in the table</, 'one link offers every unplotted row');
	$all = html_unescape($all // '');
	like($all, qr/\A\Q$table\E&f=place%3Ain%3A&back2=|\A\Q$table\E&f=place%3Ain%3A/, 'as an in filter on the table it came from');
	$t->get_ok($all)->status_is(200);
	my $all_page = $t->tx->res->body;
	my @ids = $all_page =~ /<td[^>]*>([1-6])<\/td>\s*<td[^>]*>(?:Atlantis|Lyonesse|12345|)<\/td>/g;
	is_deeply([ sort @ids ], [ 2 .. 6 ], 'which shows those rows and not the plotted one')
		or diag($all);
	unlike($all_page, qr/<td[^>]*>Ramsgate<\/td>/, 'Ramsgate, which was plotted, is not among them');

	$t->get_ok($atlantis)->status_is(200);
	my $rows_page = $t->tx->res->body;
	is(scalar(() = $rows_page =~ /<td[^>]*>Atlantis<\/td>/g), 2, 'the link shows the rows that name the place');
	like(html_unescape($rows_page), qr/Map: place/, 'with the map in its breadcrumb, to go back to');

	$t->get_ok($map)->status_is(200);
	like(html_unescape($t->tx->res->body), qr{href="/open\?path=[^"]*&f=place%3Aeq%3AAtlantis}, 'with no back=, the link is to the file\'s own table');

	$t->get_ok('/map?l=' . url_escape("path:$shared_a_csv") . '&loc=place&back=' . url_escape($table))->status_is(200);
	unlike($t->tx->res->body, qr/class="map-unplotted"/, 'a map that plots every row lists nothing');
};

subtest 'the link to every unplotted row is offered only when it is exact' => sub {
	# A place across two columns is filtered column by column, so the cells of
	# two unplotted rows can pair up into a row that was plotted.  Then the one
	# link would show too much, and only the per-place links are offered.
	my $mixed = _write_file(File::Spec->catfile($dir, 'unplotted-mixed.csv'),
		"id,address,country\n"
		. "1,\"Brezje 8, Cerknica\",Slovenia\n"
		. "2,Atlantis,Slovenia\n"
		. "3,\"Brezje 8, Cerknica\",Sea\n");
	$t->get_ok('/map?l=' . url_escape("path:$mixed") . '&loc=address&loc=country')->status_is(200);
	my $body = $t->tx->res->body;
	like($body, qr/<summary>List the 2 places that were not plotted<\/summary>/, 'two places were not plotted');
	unlike($body, qr/class="map-unplotted-all"/, 'and the one link, which would also select row 1, is not offered');
	is(scalar(() = $body =~ /title="Show these rows in the table"/g), 2, 'but each place still links to its rows');

	my $apart = _write_file(File::Spec->catfile($dir, 'unplotted-apart.csv'),
		"id,address,country\n"
		. "1,\"Brezje 8, Cerknica\",Slovenia\n"
		. "2,Atlantis,Sea\n"
		. "3,Lyonesse,Sea\n");
	$t->get_ok('/map?l=' . url_escape("path:$apart") . '&loc=address&loc=country')->status_is(200);
	my ($all) = $t->tx->res->body =~ /<a class="map-unplotted-all" href="([^"]+)"/;
	ok(defined $all, 'when the columns select exactly the unplotted rows, the link is offered');
	$all = html_unescape($all // '');
	like($all, qr/f=address%3Ain%3A.*&f=country%3Ain%3A/, 'with an in filter on each place column');
	$t->get_ok($all)->status_is(200);
	my $rows = $t->tx->res->body;
	ok(scalar($rows =~ /<td[^>]*>Atlantis<\/td>/) && scalar($rows =~ /<td[^>]*>Lyonesse<\/td>/), 'it shows both unplotted rows');
	unlike($rows, qr/<td[^>]*>Brezje 8, Cerknica<\/td>/, 'and not the plotted one');
};

subtest 'a place outside ASCII links to its rows' => sub {
	# The links carry the cell in the URL.  Escaped as characters rather than
	# UTF-8, the letters came back as something else and no row matched.
	my $town = "\x{10C}u\x{10D}ki";
	my $csv  = _write_file(File::Spec->catfile($dir, 'unplotted-utf8.csv'),
		Mojo::Util::encode('UTF-8', "id,place\n1,Ramsgate\n2,$town\n3,$town\n"));
	$t->get_ok('/map?l=' . url_escape("path:$csv") . '&loc=place')->status_is(200);
	my $body = $t->tx->res->body;

	my ($one) = $body =~ /<a href="([^"]+)" title="Show these rows in the table">/;
	my ($all) = $body =~ /<a class="map-unplotted-all" href="([^"]+)"/;
	ok(defined($one) && defined($all), 'the place and all the unplotted rows are linked');

	for my $link ([ 'the place', $one ], [ 'every unplotted row', $all ]) {
		$t->get_ok(html_unescape($link->[1] // ''))->status_is(200);
		my $page = Mojo::Util::decode('UTF-8', $t->tx->res->body);
		is(scalar(() = $page =~ /<td[^>]*>\Q$town\E<\/td>/g), 2, "the link to $link->[0] shows its two rows");
	}
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

# ===========================================================================
# The progress bar: a browser's map page asks nothing, lists the places, and
# /geo/lookup answers them one at a time, saving each answer as it comes.
# ===========================================================================

subtest 'A browser is shown the map at once, with the places to look up listed' => sub {
	my $progress_csv = _write_file(File::Spec->catfile(tempdir(CLEANUP => 1), 'progress.csv'),
		"id,town\n1,Ramsgate\n2,Walmer\n3,Sandwich\n4,Walmer\n5,42\n");
	my $spec  = 'path:' . $progress_csv;
	my $html  = { Accept => 'text/html,application/xhtml+xml' };
	my $calls = scalar @{ $stub->{'calls'} };

	$t->get_ok(_url(l => $spec, loc => 'town'), $html)->status_is(200);
	my $body = $t->tx->res->body;

	is(scalar @{ $stub->{'calls'} }, $calls, 'the page asked the geocoder nothing');
	like($body, qr/id="map-progress"/, 'it has the progress bar');
	like($body, qr/id="map-progress-cancel"/, 'and a Cancel button');
	like($body, qr/Looking up 2 places that are not in the cache yet/,
		'it counts the places that are not cached, once each, without the bare number');
	like($body, qr/L\.marker\(\[51\.33, 1\.42\]/, 'a cached place is on the map already');
	unlike($body, qr/class="map-notes"/, 'the notes wait until the places are looked up');
	like($body, qr{fetch\(outline \? '/geo/boundary' : '/geo/lookup'}, 'the page posts to /geo/lookup (and an outline to /geo/boundary)');

	my ($json) = $body =~ m{<script\b[^>]*\stype="application/json" id="map-pending">(.*?)</script>}s;
	ok(defined($json), 'the places are listed for the script');
	my $pending = decode_json($json // '[]');
	is_deeply([ map { $_->{place} } @{$pending} ], [qw(Walmer Sandwich)], 'in the order of their rows');
	ok(!(grep { !length($_->{sig} // '') } @{$pending}), 'each one signed');

	my ($done)   = $body =~ /data-done-url="([^"]*)"/;
	my ($cached) = $body =~ /data-cached-url="([^"]*)"/;
	$done   = html_unescape($done // '');
	$cached = html_unescape($cached // '');
	unlike($done, qr/geocode=/, 'when it is done the page is drawn again as it was asked for');
	like($cached, qr/geocode=cached/, 'and Cancel draws it from the cache');
	like($body, qr/<noscript>.*geocode=wait/s, 'without a script, a link waits for the lookups');

	# Walmer is found, and saved at once.
	$stub->{'results'}{'Walmer'} = Stub::Point->new(latitude => 51.20, longitude => 1.40, database => 'OpenAddresses');
	$t->post_ok('/geo/lookup' => form => $pending->[0])->status_is(200)
		->json_is('/status', 'found')->json_is('/stored', 1)->json_is('/place', 'Walmer');
	is(scalar @{ $stub->{'calls'} }, $calls + 1, 'one place, one lookup');
	my $models = decode_json(do { open(my $fh, '<', $model_store) or die $!; local $/; <$fh> });
	is_deeply($models->{geo}{shared}{places}{Walmer}, [51.20, 1.40], 'Walmer is in the shared cache already');

	# Asking again (another tab) is answered from the cache.
	$t->post_ok('/geo/lookup' => form => $pending->[0])->status_is(200)
		->json_is('/status', 'found')->json_is('/stored', 1);
	is(scalar @{ $stub->{'calls'} }, $calls + 1, 'a place in the cache is not looked up again');

	# A place's signature does not fit another place.
	$t->post_ok('/geo/lookup' => form => { place => 'Sandwich', sig => $pending->[0]{sig} })->status_is(403);

	# Cancel: the map is drawn from the cache, Sandwich is left for later, and
	# a link offers to look it up.
	$t->get_ok($cached, $html)->status_is(200);
	$body = $t->tx->res->body;
	is(scalar @{ $stub->{'calls'} }, $calls + 1, 'geocode=cached asks nothing');
	unlike($body, qr/id="map-progress"/, 'and shows no progress bar');
	like($body, qr/L\.marker\(\[51\.2, 1\.4\]/, 'the place found before Cancel is on the map');
	like($body, qr/<tr data-reason="later">\s*<td>Sandwich</, 'the place not looked up is listed as later');
	my ($retry) = $body =~ /id="map-retry" href="([^"]*)"/;
	ok(defined($retry), 'with a link to look it up');
	unlike(html_unescape($retry // ''), qr/geocode=/, 'which is the map without geocode=');

	# Trying again looks up only what is left: Walmer, found before Cancel,
	# comes from the cache.
	$t->get_ok(html_unescape($retry // ''), $html)->status_is(200);
	$body = $t->tx->res->body;
	is(scalar @{ $stub->{'calls'} }, $calls + 1, 'trying again asks nothing before the bar starts');
	my ($again) = $body =~ m{<script\b[^>]*\stype="application/json" id="map-pending">(.*?)</script>}s;
	is_deeply([ map { $_->{place} } @{ decode_json($again // '[]') } ], [ 'Sandwich' ],
		'only the place not looked up is listed again');
	like($body, qr/L\.marker\(\[51\.2, 1\.4\]/, 'and Walmer is on the map already');

	# Sandwich is not found: remembered as such, so the next page is complete.
	$t->post_ok('/geo/lookup' => form => $pending->[1])->status_is(200)
		->json_is('/status', 'not_found')->json_is('/stored', 1);
	$t->get_ok($done, $html)->status_is(200);
	$body = $t->tx->res->body;
	unlike($body, qr/id="map-progress"/, 'once every place has an answer, there is no progress bar');
	like($body, qr/<tr data-reason="not_found">\s*<td>Sandwich</, 'and Sandwich is not found');
	like($body, qr/Plotting 2 markers for 3 of 5 rows/, 'the rest are plotted');
};

subtest 'geocode=wait, and a client that is not a browser, look places up first' => sub {
	my $wait_csv = _write_file(File::Spec->catfile(tempdir(CLEANUP => 1), 'wait.csv'),
		"id,town\n1,Margate\n2,Broadstairs\n");
	$stub->{'results'}{'Margate'}     = Stub::Point->new(latitude => 51.38, longitude => 1.38, database => 'OpenAddresses');
	$stub->{'results'}{'Broadstairs'} = Stub::Point->new(latitude => 51.36, longitude => 1.43, database => 'OpenAddresses');
	my $calls = scalar @{ $stub->{'calls'} };

	$t->get_ok(_url(l => "path:$wait_csv", loc => 'town', geocode => 'wait'),
		{ Accept => 'text/html' })->status_is(200);
	is(scalar @{ $stub->{'calls'} }, $calls + 1, 'geocode=wait looks them up in the request');
	unlike($t->tx->res->body, qr/id="map-progress"/, 'with no progress bar');
	like($t->tx->res->body, qr/Plotting 2 markers for 2 of 2 rows/, 'and plots them');

	$t->get_ok(_url(l => "path:$wait_csv", loc => 'town', geocode => 'nope'))->status_is(400)
		->content_like(qr/geocode= must be "wait"/);
};

subtest '/geo/lookup: a place that cannot be looked up now is held, not remembered' => sub {
	my $held_csv = _write_file(File::Spec->catfile(tempdir(CLEANUP => 1), 'held.csv'),
		"id,town\n1,Nowhere Yet\n");
	my $url  = _url(l => "path:$held_csv", loc => 'town');
	my $html = { Accept => 'text/html' };

	# Listed by the page while there is a geocoder to ask...
	$t->get_ok($url, $html)->status_is(200);
	my ($json) = $t->tx->res->body =~ m{<script\b[^>]*\stype="application/json" id="map-pending">(.*?)</script>}s;
	my ($item) = @{ decode_json($json // '[]') };
	is($item->{place}, 'Nowhere Yet', 'the page lists the place');

	# ...and looked up after it has gone.
	my $geocoder = delete $t->app->config->{geocoder};
	no warnings qw(redefine once);
	local *Database::BI::Model::Geocode::_load_geocoder = sub { $_[0]{_unavailable} = 'it is not installed'; return };

	$t->post_ok('/geo/lookup' => form => $item)->status_is(200)
		->json_is('/status', 'held')->json_is('/stored', 0);
	my $models = decode_json(do { open(my $fh, '<', $model_store) or die $!; local $/; <$fh> });
	ok(!exists $models->{geo}{shared}{places}{'Nowhere Yet'}, 'it is not remembered');

	$t->get_ok($url, $html)->status_is(200);
	unlike($t->tx->res->body, qr/id="map-progress"/,
		'without a geocoder nothing can be asked, so there is no progress bar');

	$t->app->config->{geocoder} = $geocoder;
};

# ---------------------------------------------------------------------------
# A marker stands for every row at its place, and its popup lists them: the
# values the rows share once, the ones that differ as a table.  Past
# map_popup_rows the rest are counted, with a link to them in the table this
# map came from.  (Reported on a family-history file: a house where three
# events happened showed "3 rows" and only the first event.)
# ---------------------------------------------------------------------------
subtest 'a popup lists every row at a place, capped, with a link to the rest' => sub {
	$t->get_ok(_url(l => $places_spec, loc => 'place'))->status_is(200);
	my $body = $t->tx->res->body;
	my ($popup) = $body =~ m{bindPopup\('(<strong>Ramsgate.*?)'\)}s;
	ok defined($popup), 'the Ramsgate marker has a popup' or return;
	like $popup, qr/2 rows<br>lat: 51\.33<br>lon: 1\.42/, 'what both rows share is said once';
	like $popup, qr{<tr><th>id<\\/th><th>amount<\\/th><\\/tr><tr><td>1<\\/td><td>10<\\/td><\\/tr><tr><td>2<\\/td><td>5<\\/td><\\/tr>},
		'and both rows are listed, not only the first';
	unlike $popup, qr/more/, 'two rows are under the default cap';

	local $t->app->config->{map_popup_rows} = 1;
	my $back = '/open?path=' . url_escape($places_csv);
	$t->get_ok(_url(l => $places_spec, loc => 'place', back => $back))->status_is(200);
	($popup) = $t->tx->res->body =~ m{bindPopup\('(<strong>Ramsgate.*?)'\)}s;
	is scalar(() = $popup =~ /<td>/g), 2, 'one row of two cells under a cap of one';
	my ($link) = $popup =~ m{and 1 more: <a href="([^"]+)">show all 2 in the table<\\/a>};
	ok defined($link), 'the rest are counted and linked' or return;
	$link =~ s/&amp;/&/g;
	like $link, qr{\A/open\?path=[^&]+&f=place%3Aeq%3ARamsgate&back2=}, 'to the table, filtered to the place';
	$t->get_ok($link)->status_is(200);
	is scalar(() = $t->tx->res->body =~ m{<td[^>]*>Ramsgate</td>}g), 2, 'which shows exactly its rows';

	# By coordinates, rows at one point are one marker in the same way.
	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon', back => $back))->status_is(200);
	($popup) = $t->tx->res->body =~ m{bindPopup\('(<strong>51\.330000, 1\.420000.*?)'\)}s;
	like $popup, qr/place: Ramsgate/, 'a point lists its shared values';
	like $popup, qr{and 1 more: <a href="[^"]*f=lat%3Aeq%3A51\.33&amp;f=lon%3Aeq%3A1\.42}, 'and links to its rows by coordinate';

	# A cap that is not a number is the default.
	local $t->app->config->{map_popup_rows} = 'lots';
	$t->get_ok(_url(l => $places_spec, loc => 'place'))->status_is(200);
	unlike $t->tx->res->body, qr/and \d+ more/, 'a bad map_popup_rows is ignored';
};

# ===========================================================================
# loc_text= -- text added to the end of each place before it is looked up
# ===========================================================================

subtest 'GET /map?loc_text= adds text to each place' => sub {
	$stub->{'results'}{'Deal, Kent, England'} =
		Stub::Point->new(latitude => 51.22, longitude => 1.40, database => 'OpenAddresses');
	my $before = scalar @{ $stub->{'calls'} };

	$t->get_ok(_url(l => $towns_spec, loc => 'town', loc_text => '  Kent,   England '))
		->status_is(200)
		->content_like(qr/from column town with &ldquo;Kent, England&rdquo; added/, 'the summary says so');

	my @asked = map { @{ $_->{'values'} } } @{ $stub->{'calls'} }[ $before .. $#{ $stub->{'calls'} } ];
	is_deeply([ sort @asked ], [ 'Deal, Kent, England', 'Faversham, Kent, England' ],
		'each place is looked up with the text, its spaces tidied');
	like($t->tx->res->body, qr/L\.marker\(\[51\.22, 1\.4\]/, 'and plotted');

	my $chart = decode_json($t->tx->res->dom->at('#new-canvas-panel')->attr('data-chart'));
	is($chart->{encode}{loc_text}, 'Kent, England', 'a canvas card made from the map keeps it');

	# A leading comma is dropped, as the place and the text are joined with one.
	$before = scalar @{ $stub->{'calls'} };
	$t->get_ok(_url(l => $towns_spec, loc => 'town', loc_text => ', Kent, England'))->status_is(200);
	is(scalar @{ $stub->{'calls'} }, $before, 'the same places, answered from the cache');

	# Cancelled part way, with the text: what was found is kept under the
	# place with its text, and trying again lists only the rest.
	my $html = { Accept => 'text/html' };
	my $kent = _write_file(File::Spec->catfile(tempdir(CLEANUP => 1), 'kent.csv'),
		"id,town\n1,Whitstable\n2,Herne Bay\n");
	my $kent_url = _url(l => "path:$kent", loc => 'town', loc_text => 'Kent');
	$t->get_ok($kent_url, $html)->status_is(200);
	my ($json) = $t->tx->res->body =~ m{<script\b[^>]*\stype="application/json" id="map-pending">(.*?)</script>}s;
	my $pending = decode_json($json // '[]');
	is_deeply([ map { $_->{place} } @{$pending} ], [ 'Whitstable, Kent', 'Herne Bay, Kent' ],
		'the progress bar looks up each place with the text');
	$stub->{'results'}{'Whitstable, Kent'} =
		Stub::Point->new(latitude => 51.36, longitude => 1.03, database => 'OpenAddresses');
	$t->post_ok('/geo/lookup' => form => $pending->[0])->status_is(200)->json_is('/stored', 1);
	$before = scalar @{ $stub->{'calls'} };
	$t->get_ok($kent_url, $html)->status_is(200);	# after Cancel, opened again
	($json) = $t->tx->res->body =~ m{<script\b[^>]*\stype="application/json" id="map-pending">(.*?)</script>}s;
	is_deeply([ map { $_->{place} } @{ decode_json($json // '[]') } ], [ 'Herne Bay, Kent' ],
		'opened again, only the place not looked up is listed');
	like($t->tx->res->body, qr/L\.marker\(\[51\.36, 1\.03\]/, 'the one found is drawn from the cache');
	is(scalar @{ $stub->{'calls'} }, $before, 'without asking the geocoder');

	# A row with no place is not looked up at the text alone.
	$t->get_ok(_url(l => $places_spec, loc => 'place', loc_text => 'Kent'))->status_is(200);
	ok(!(grep { $_ eq 'Kent' } map { @{ $_->{'values'} } } @{ $stub->{'calls'} }), 'no lookup of "Kent" alone');

	$t->get_ok(_url(l => $towns_spec, loc => 'town', loc_text => 'x' x 201))->status_is(400)
		->content_like(qr/loc_text= is the text added to the end of each place, at most 200 characters/);
	$t->get_ok(_url(l => $towns_spec, loc => 'town', loc_text => "Kent\nEngland"))->status_is(400);

	# Coordinates need no help.
	$t->get_ok(_url(l => $places_spec, lat => 'lat', lon => 'lon', loc_text => 'Kent'))->status_is(200)
		->content_unlike(qr/added\./, 'ignored with lat= and lon=');
};

done_testing();
