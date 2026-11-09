use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

# Live: postgis_topology and its runtime schemas (karr k31, ADR 0066 Decisions 7).
#
# The class exists because a topology is a SCHEMA the database gets at
# runtime: topology.CreateTopology('name', srid) adds a row to
# topology.topology and creates the schema 'name' with the tables edge_data,
# face, node and relation, none of them a pg_depend member of the extension. So
# the driver's base filter does not keep them out of the model -- this file
# samples exactly that against a real server (the maintainer asked for the
# measurement, not the assumption) -- and the extension's claims have to.
#
# Everything happens in one transaction that is rolled back: the extension and
# the topology exist for the duration of the test only. Gated on
# DBIO_TEST_PG_DSN; skips without a PostGIS-capable database that offers
# postgis_topology.

my ($dsn, $user, $pass) =
  @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};
$dsn  //= $ENV{DBIO_TEST_PG_EXT_DSN};
$user //= $ENV{DBIO_TEST_PG_EXT_USER};
$pass //= $ENV{DBIO_TEST_PG_EXT_PASS};

plan skip_all => 'DBIO_TEST_PG_DSN not set' unless $dsn;

eval { require DBI; require DBD::Pg; 1 }
  or plan skip_all => 'DBI / DBD::Pg not available';

use DBIO::Extension::Protocol;
use DBIO::PostgreSQL::Introspect;
use DBIO::PostgreSQL::PostGIS::Extension;
use DBIO::PostgreSQL::PostGIS::Topology::Extension;
use MockPgDeploy;

my $TOPO = 'DBIO::PostgreSQL::PostGIS::Topology::Extension';
my $GIS  = 'DBIO::PostgreSQL::PostGIS::Extension';
my $NAME = 'dbio_postgis_topo_probe';

my $dbh = eval {
  DBI->connect($dsn, $user, $pass,
    { RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 0 });
};
plan skip_all => "Cannot connect: $@" unless $dbh;

END { $dbh->rollback if $dbh && $dbh->{Active} }

eval {
  $dbh->do('CREATE EXTENSION IF NOT EXISTS postgis');
  $dbh->do('CREATE EXTENSION IF NOT EXISTS postgis_topology');
  1;
} or do {
  $dbh->rollback;
  plan skip_all => "postgis_topology not available: $@";
};

# before any topology: the extension is there, its state is empty
is_deeply $TOPO->inspect({ dbh => $dbh, self => {} }), { topologies => [] },
  'inspect: installed, no topology yet';

$dbh->selectrow_array('SELECT topology.CreateTopology(?, 4326)', undef, $NAME);

my $state = $TOPO->inspect({ dbh => $dbh, self => {} });
is_deeply [ grep { $_->{name} eq $NAME } @{ $state->{topologies} } ],
  [ { name => $NAME, srid => 4326 } ],
  'inspect: the topology is read from topology.topology';

# The measurement: the base model holds the schema of the topology, as the
# application's, because no pg_depend member filter catches it ...
my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
ok exists $model->{schemas}{$NAME}, 'the base model has the schema of the topology ...'
  or diag join ', ', sort keys %{ $model->{schemas} };
ok exists $model->{tables}{"$NAME.node"} && exists $model->{tables}{"$NAME.face"},
  '... and its tables (node, face): nothing filtered them';

# ... and the claims take them out, the table of the extension itself is
# already out (a member of the extension)
ok !exists $model->{tables}{'topology.topology'} && !exists $model->{tables}{'public.spatial_ref_sys'},
  'topology.topology and spatial_ref_sys are not in the base model: members of their extensions';

my $entries = [
  { name => 'postgis',          class => $GIS,  options => {}, installed => 1, schema => 'public' },
  { name => 'postgis_topology', class => $TOPO, options => {}, installed => 1, schema => 'topology' },
];
my $protocol = DBIO::Extension::Protocol->new(entries => $entries, driver => {});
$protocol->inspect($dbh);
my ($extended) = $protocol->extend_models(MockPgDeploy->new, $model, $model);

ok !exists $extended->{schemas}{$NAME}, 'with the extension in the list, the schema of the topology is gone';
is_deeply [ grep { /\A\Q$NAME\E\./ } keys %{ $extended->{tables} } ], [],
  '... with all its tables';
is_deeply [ grep { /\A\Q$NAME\E\./ } keys %{ $extended->{columns} } ], [],
  '... and their columns';
ok exists $extended->{schemas}{public}, 'the application\'s schemas stay';

$dbh->rollback;
is_deeply [ $dbh->selectrow_array(q{SELECT count(*) FROM pg_namespace WHERE nspname = ?}, undef, $NAME) ], [0],
  'nothing of the probe is left in the database';

done_testing;
