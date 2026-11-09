use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# MEASUREMENT (ADR 0066, decision 7, karr k136): what postgis_topology makes.
# The statements are in the POD of DBIO::PostgreSQL::Extension; this file keeps
# them true.
#
# What this file claims, in a database of its own:
#   1. the schema "topology" and its tables are the extension's: tables and
#      sequence are members (pg_depend deptype 'e'); the schema is not a member;
#   2. topology.CreateTopology('t1') makes a schema t1 with tables, a view and
#      sequences, and none of them is a member of the extension -- they are
#      ordinary objects of the database, which a deploy would see as the model's;
#   3. DROP EXTENSION postgis_topology is refused while t1 exists (a trigger of
#      t1.relation depends on a function of the extension); without t1 it
#      drops, and the schema "topology" stays behind.

{
  my $h = LiveServer->control_dbh;
  my %avail = map { $_ => 1 } @{ $h->selectcol_arrayref(
    q{SELECT name FROM pg_catalog.pg_available_extensions WHERE name IN ('postgis', 'postgis_topology')}
  ) };
  $h->disconnect;
  plan skip_all => "extension $_ not available on the server"
    for grep { !$avail{$_} } qw(postgis postgis_topology);
}

my @db = PrivatePgDatabase->create('t149');
my $h  = LiveServer->control_dbh(login => \@db, attrs => { PrintWarn => 0 });

$h->do('CREATE EXTENSION postgis');
$h->do('CREATE EXTENSION postgis_topology');

sub members_in {
  my ($schema) = @_;
  return $h->selectall_arrayref(q{
    SELECT c.relname FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = ? AND c.relkind IN ('r', 'S', 'v', 'm')
      AND EXISTS (SELECT 1 FROM pg_catalog.pg_depend d
                   WHERE d.classid = 'pg_catalog.pg_class'::regclass AND d.objid = c.oid
                     AND d.refclassid = 'pg_catalog.pg_extension'::regclass AND d.deptype = 'e')
    ORDER BY 1}, undef, $schema);
}
sub relations_in {
  my ($schema) = @_;
  return $h->selectcol_arrayref(q{
    SELECT c.relname FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = ? AND c.relkind IN ('r', 'S', 'v', 'm') ORDER BY 1}, undef, $schema);
}
sub schema_is_member {
  my ($schema) = @_;
  return scalar $h->selectrow_array(q{
    SELECT count(*) FROM pg_catalog.pg_depend d
    JOIN pg_catalog.pg_namespace n ON n.oid = d.objid
    WHERE d.classid = 'pg_catalog.pg_namespace'::regclass AND n.nspname = ?
      AND d.refclassid = 'pg_catalog.pg_extension'::regclass AND d.deptype = 'e'}, undef, $schema);
}
sub schema_exists {
  return scalar $h->selectrow_array(q{SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = ?}, undef, $_[0]);
}

is_deeply [ map { $_->[0] } @{ members_in('topology') } ], [qw( layer topology topology_id_seq )],
  'topology: its tables and its sequence are members of the extension';
ok !schema_is_member('topology'), '... the schema itself is not (the extension depends on it)';

$h->do(q{SELECT topology.CreateTopology('t1')});
ok schema_exists('t1'), 'CreateTopology makes the schema t1';
ok scalar @{ relations_in('t1') }, '... with relations';
is_deeply members_in('t1'), [], '... none of which is a member of the extension';
ok !schema_is_member('t1'), '... nor is the schema';

ok !eval { local $h->{PrintError} = 0; local $h->{RaiseError} = 1; $h->do('DROP EXTENSION postgis_topology'); 1 },
  'DROP EXTENSION postgis_topology is refused while a topology exists ...';
like $@, qr/other objects depend on it.*trigger relation_integrity_checks on table t1\.relation/s,
  '... because a trigger of t1.relation depends on a function of the extension';
ok schema_exists('t1'), '... and t1 is still there: a topology is not taken along';

$h->do('DROP SCHEMA t1 CASCADE');
ok eval { $h->do('DROP EXTENSION postgis_topology'); 1 }, 'without the topology the extension drops';
ok schema_exists('topology'), '... and the schema "topology" stays behind (not a member)';

$h->disconnect;
done_testing;
