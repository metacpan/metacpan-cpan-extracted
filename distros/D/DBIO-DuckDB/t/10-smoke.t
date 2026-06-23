#!/usr/bin/env perl
# t/10-smoke.t — end-to-end smoke test for DBIO::DuckDB using the
# standard DBIO::Test::Schema via DBIO::DuckDB::Test->init_schema.

use strict;
use warnings;
use Test::More;
use DBIO::DuckDB::Test;

my $schema = DBIO::DuckDB::Test->init_schema;
isa_ok $schema->storage, 'DBIO::DuckDB::Storage', 'duckdb storage';
ok $schema->storage->duckdb_version, 'duckdb_version returned';

# populate_schema already inserted the standard Artist/CD fixture.
my $artist_rs = $schema->resultset('Artist');
ok $artist_rs->count, 'artists populated';

my $cd_rs = $schema->resultset('CD');
ok $cd_rs->count, 'cds populated';

# Round-trip a new Artist + CD.
my $new = $schema->resultset('Artist')->create({ name => 'Autechre' });
ok $new->artistid, 'auto-increment artistid assigned';

$schema->resultset('CD')->create({
  artist => $new->artistid, title => 'Tri Repetae', year => 1995,
});

my $joined = $schema->resultset('CD')->search(
  { 'me.title' => 'Tri Repetae' },
  { join => 'artist', prefetch => 'artist' },
)->single;
ok $joined, 'found new CD';
is $joined->artist->name, 'Autechre', 'prefetched artist name';

my ($n) = $schema->storage->dbh->selectrow_array('SELECT COUNT(*) FROM cd');
ok $n, "raw SQL count = $n";

done_testing;
