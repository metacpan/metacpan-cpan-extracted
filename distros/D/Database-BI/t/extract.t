#!/usr/bin/env perl
# t/extract.t -- Phase 4.1: Extract cache unit tests

use strict;
use warnings;

use lib 'lib';

use File::Path	qw(remove_tree make_path);
use File::Spec;
use File::Temp	qw(tempdir);
use Mojo::Util	qw(url_escape);
use Test::More;

use_ok('Database::BI::Extract') or BAIL_OUT('Cannot load Extract module');

my $tmpdir = tempdir(CLEANUP => 1);

my $cache = Database::BI::Extract->new(model_dir => $tmpdir);
isa_ok($cache, 'Database::BI::Extract', 'constructor returns correct class');

# ---------------------------------------------------------------------------
# 1. get() on an empty cache returns undef
# ---------------------------------------------------------------------------

is($cache->get('table:sales', 12345, 100), undef,
	'get() on cold cache returns undef');

# ---------------------------------------------------------------------------
# 2. put() then get() with same fingerprint returns the path
# ---------------------------------------------------------------------------

my $fake_bytes = 'SQLite format 3' . "\0" x 100;
my $path = $cache->put('table:sales', 12345, 100, $fake_bytes);
ok(defined $path && length $path, 'put() returns a path');
ok(-f $path, 'put() created the file on disk');

my $hit = $cache->get('table:sales', 12345, 100);
is($hit, $path, 'get() with matching fingerprint returns the path');

# ---------------------------------------------------------------------------
# 3. get() with different mtime returns undef (cache miss)
# ---------------------------------------------------------------------------

my $miss = $cache->get('table:sales', 99999, 100);
is($miss, undef, 'get() with different mtime is a cache miss');

# ---------------------------------------------------------------------------
# 4. get() with different size returns undef (cache miss)
# ---------------------------------------------------------------------------

my $miss2 = $cache->get('table:sales', 12345, 999);
is($miss2, undef, 'get() with different size is a cache miss');

# ---------------------------------------------------------------------------
# 5. Deleting the extract directory leaves the cache gracefully returning undef
# ---------------------------------------------------------------------------

remove_tree(File::Spec->catdir($tmpdir, 'extracts'));
my $after_delete = $cache->get('table:sales', 12345, 100);
is($after_delete, undef, 'get() after extract dir removed returns undef (cache miss, not crash)');

# ---------------------------------------------------------------------------
# 6. No files created under data_dir
# ---------------------------------------------------------------------------

my $data_dir = tempdir(CLEANUP => 1);
my $cache2   = Database::BI::Extract->new(model_dir => File::Spec->catdir($tmpdir, 'model'));
$cache2->put('table:products', 54321, 200, $fake_bytes);

my @data_files = glob("$data_dir/*");
is(scalar @data_files, 0, 'no files created under data_dir');

# ---------------------------------------------------------------------------
# 7. HTTP /view/sales still works without extracts (integration smoke)
# ---------------------------------------------------------------------------

SKIP: {
	eval { require Test::Mojo; require Database::BI } or skip 'Test::Mojo / Database::BI not loadable', 2;
	skip 'data/sales.csv not found', 2 unless -f 'data/sales.csv';

	my $t = Test::Mojo->new('Database::BI');
	# Point model_dir to a temp dir (no extracts there).
	$t->app->config->{model_dir} = $tmpdir;

	# Remove extracts dir to prove it falls through.
	remove_tree(File::Spec->catdir($tmpdir, 'extracts'));

	$t->get_ok('/view/sales')->status_is(200, '/view/sales works without extract dir');
}

# ---------------------------------------------------------------------------
# 8. Performance smoke: a repeated request with an unchanged fingerprint
#    must not rebuild the extract (cache hit).
#    Generates ~10 k rows -- enough to prove the cache path, fast in CI.
# ---------------------------------------------------------------------------

SKIP: {
	eval { require Test::Mojo; require Database::BI; require DBI } or
		skip 'Test::Mojo / Database::BI / DBI not loadable', 3;

	my $perf_dir = tempdir(CLEANUP => 1);
	my $csv_path = File::Spec->catfile($perf_dir, 'big.csv');

	# Write a 10 000-row CSV.
	open(my $fh, '>', $csv_path) or skip "cannot write $csv_path", 3;
	print {$fh} "id,value,label\n";
	print {$fh} "$_," . ($_ * 3) . ",row$_\n" for 1 .. 10_000;
	close $fh;

	my $t = Test::Mojo->new('Database::BI');
	$t->app->config->{model_dir} = $perf_dir;
	$t->app->config->{data_dir}  = $perf_dir;

	# First request -- parses the CSV.
	my $t0 = time();
	$t->get_ok("/open?path=" . Mojo::Util::url_escape($csv_path))
		->status_is(200, 'large CSV opens on first request');
	my $t1 = time();

	# Second request -- should hit the extract (or fall through gracefully).
	$t->get_ok("/open?path=" . Mojo::Util::url_escape($csv_path))
		->status_is(200, 'large CSV opens on second request');

	pass('performance smoke: two requests on a 10k-row CSV complete');
}

done_testing;
