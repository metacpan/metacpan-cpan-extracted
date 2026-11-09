#!/usr/bin/env perl
# t/50-arrow.t — DBIO::DuckDB::Storage escape hatches: duckdb_appender,
# duckdb_arrow_fetch (the shape; the types are t/68), duckdb_read_csv, duckdb_version.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use DBIO::DuckDB::Test;

my $schema  = DBIO::DuckDB::Test->init_schema(no_populate => 1);
my $storage = $schema->storage;

ok $storage->duckdb_version, 'duckdb_version';

# --- Appender path: bulk-load 1000 CDs --------------------------------

my $artist = $schema->resultset('Artist')->create({ name => 'Bulk Loader' });

my $app = $storage->duckdb_appender('cd');
isa_ok $app, 'DBD::DuckDB::Appender', 'appender object';

for my $i (1 .. 1000) {
  $app->append_row(
    cdid   => $i + 100,
    artist => $artist->artistid,
    title  => "cd_title_$i",
    year   => 1970 + ($i % 50),
  );
}
$app->flush;

my ($n) = $storage->dbh->selectrow_array('SELECT COUNT(*) FROM cd');
is $n, 1000, 'appender loaded 1000 rows';

# --- Arrow fetch: columnar, names / formats / columns / rows -----------
# (every type: t/68-arrow-fetch.t)

my $t = $storage->duckdb_arrow_fetch(
  q{SELECT (CAST(year AS INTEGER) // 10) * 10 AS decade, COUNT(*) AS n
    FROM cd GROUP BY decade ORDER BY decade},
  [],
);
is ref $t, 'HASH', 'arrow_fetch returns a hash reference';
is_deeply $t->{names}, [qw(decade n)], 'column names, in result order';
is_deeply $t->{formats}, [qw(i l)], 'Arrow formats: INTEGER and BIGINT';
is $t->{rows}, 5, 'five decades';
is_deeply $t->{columns}, [
  [ 1970, 1980, 1990, 2000, 2010 ],
  [ 200, 200, 200, 200, 200 ],
], 'one array of values per column';

# --- read_csv helper --------------------------------------------------

my ($fh, $csv) = tempfile(SUFFIX => '.csv', UNLINK => 1);
print {$fh} "id,name\n1,alpha\n2,beta\n3,gamma\n";
close $fh;

my $read = $storage->duckdb_read_csv($csv);
is ref $read, 'ARRAY', 'read_csv returns arrayref';
is scalar @$read, 3, 'read_csv got 3 rows';

done_testing;
