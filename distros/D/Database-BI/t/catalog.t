#!/usr/bin/env perl
# t/catalog.t -- Phase 4.7: Catalog/lineage view tests

use strict;
use warnings;

use Test::More;
use Test::Mojo;

eval { require Database::BI } or plan skip_all => 'Database::BI not loadable';
plan skip_all => 'data/sales.csv not found' unless -f 'data/sales.csv';

my $t = Test::Mojo->new('Database::BI');

# ---------------------------------------------------------------------------
# 1. GET /catalog returns 200
# ---------------------------------------------------------------------------

$t->get_ok('/catalog')->status_is(200, 'GET /catalog returns 200');

# ---------------------------------------------------------------------------
# 2. Catalog page contains "sales" (the data/sales.csv file)
# ---------------------------------------------------------------------------

$t->content_like(qr/sales/, 'catalog page mentions sales dataset');

# ---------------------------------------------------------------------------
# 3. Catalog page contains expected column headers
# ---------------------------------------------------------------------------

$t->content_like(qr/File/,          'catalog has File column header');
$t->content_like(qr/Last modified/, 'catalog has Last modified column header');
$t->content_like(qr/Used by/,       'catalog has Used by column header');

# ---------------------------------------------------------------------------
# 4. Catalog shows analysis name when an analysis references the dataset
# ---------------------------------------------------------------------------

use File::Temp qw(tempdir);
use Mojo::JSON qw(encode_json);
use Mojo::File;

my $model_dir = tempdir(CLEANUP => 1);
$t->app->config->{model_dir} = $model_dir;

# Create a fake analyses.json referencing sales.csv.
my $analyses_path = Mojo::File->new($model_dir)->child('analyses.json')->to_string;
my $abs_sales = Mojo::File->new('data/sales.csv')->realpath->to_string;
my $analyses = {
	'testABC123' => {
		id       => 'testABC123',
		name     => 'My Sales Analysis',
		version  => 1,
		created  => '2026-10-01T00:00:00Z',
		updated  => '2026-10-01T00:00:00Z',
		datasets => [ { spec => "path:$abs_sales" } ],
	},
};
Mojo::File->new($analyses_path)->spurt(encode_json($analyses));

$t->get_ok('/catalog')->status_is(200, 'GET /catalog with analysis returns 200');
$t->content_like(qr/My Sales Analysis/, 'catalog lists the analysis name');
$t->content_like(qr/testABC123/,        'catalog links to the analysis id');

# ---------------------------------------------------------------------------
# 5. Catalog returns 200 even when data dir is empty / no supported files
# ---------------------------------------------------------------------------

my $empty_data = tempdir(CLEANUP => 1);
$t->app->config->{data_dir} = $empty_data;
$t->get_ok('/catalog')->status_is(200, 'GET /catalog with empty data dir returns 200');
$t->content_like(qr/No data files found/, 'catalog says no data files when dir is empty');

done_testing;
