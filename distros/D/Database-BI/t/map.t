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
use Mojo::Util  qw(url_escape);

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

my $places_spec = 'path:' . $places_csv;
my $markup_spec = 'path:' . $markup_csv;
my $range_spec  = 'path:' . $range_csv;

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
});

$t->app->config->{geocoder} = $stub;

# HTML::OSM is a recommends dep; skip when absent so CI does not fail just
# because the optional renderer is not installed.
plan skip_all => 'HTML::OSM not installed; map rendering tests need it'
	unless eval { require HTML::OSM; 1 };

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
	like($body, qr{<head>.*leaflet\@1\.9\.4/dist/leaflet\.css.*</head>}s,
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

subtest 'An unopenable source is a 404' => sub {
	$t->get_ok(_url(l => 'path:/nonexistent/nothing.csv', loc => 'place'))
		->status_is(404);
};

done_testing();
