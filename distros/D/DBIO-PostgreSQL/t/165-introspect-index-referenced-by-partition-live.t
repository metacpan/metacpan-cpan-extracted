use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

LiveServer->require_server;

# LIVE test for the second review of karr k140: the keys that stand on an index.
#
# WHAT IT ASSERTS: referenced_by of the index of a constraint names the foreign
# keys that were declared, and not the copies the server makes of a key of a
# partitioned table for each of its partitions (pg_constraint.conparentid set).
#
# WHY: the copies point at the same index. Listed, they made a refusal name
# a constraint of a partition (link_p1_ref_code_fkey) that no statement can
# drop -- the server refuses "cannot drop inherited constraint" -- and the way
# out the message gave could not be run. The foreign key section of the model
# leaves the copies out (Introspect::ForeignKeys); this one has to say the same.

my $dbh = LiveServer->control_dbh(
  login => [ PrivatePgDatabase->create('t165') ], attrs => { PrintWarn => 0 });
$dbh->do('SET client_min_messages = warning');
$dbh->do($_) for
  'CREATE TABLE ref (id bigint NOT NULL PRIMARY KEY, code bigint NOT NULL, CONSTRAINT ref_code_key UNIQUE (code))',
  'CREATE TABLE link (id bigint NOT NULL, ref_code bigint NOT NULL, PRIMARY KEY (id)) PARTITION BY RANGE (id)',
  'CREATE TABLE link_p1 PARTITION OF link FOR VALUES FROM (0) TO (100)',
  'CREATE TABLE link_p2 PARTITION OF link FOR VALUES FROM (100) TO (200)',
  'ALTER TABLE link ADD CONSTRAINT link_ref_fkey FOREIGN KEY (ref_code) REFERENCES ref (code)',
  'CREATE TABLE plain (id bigint NOT NULL PRIMARY KEY, ref_code bigint NOT NULL REFERENCES ref (code))';

my ($copies) = $dbh->selectrow_array(q{SELECT count(*) FROM pg_catalog.pg_constraint
  WHERE contype = 'f' AND conindid = 'ref_code_key'::regclass AND conparentid <> 0});
cmp_ok($copies, '>=', 2, 'the server made a copy of the key for each partition');

my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
my $by = $model->{indexes}{'public.ref'}{ref_code_key}{referenced_by};
is_deeply(
  [ map { join '.', @{$_}{qw( table_name constraint_name )} } @{ $by // [] } ],
  [ 'link.link_ref_fkey', 'plain.plain_ref_code_fkey' ],
  'referenced_by names the declared keys, not the copies at the partitions',
);

$dbh->disconnect;
done_testing;
