use strict;
use warnings;
use Test::More;
use Test::Exception;

# karr k24: load_age on a connection that names a tenant namespace through
# the connect key `schema`. The driver (_set_connection_schema) sets the
# search_path ahead of on_connect_call; connect_call_load_age (karr k18) must
# put ag_catalog BEHIND the namespace entry of that path, once, and keep the tenant schema first --
# the old `SET search_path = ag_catalog, "$user", public` threw it away, so an
# unqualified object landed in the wrong schema. Offline guard: t/32.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn && $user;

eval { require DBIO::PostgreSQL::Storage; 1 }
  or plan skip_all => 'DBIO::PostgreSQL not installed';

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

# A server that is not there fails the file, with a plan (karr k113).
my $admin = LiveServer->control_dbh;

my ($age_available) = $admin->selectrow_array(
  q{SELECT 1 FROM pg_available_extensions WHERE name = 'age'}
);
plan skip_all => 'Apache AGE extension not available in this PostgreSQL'
  unless $age_available;

my $NS    = 'k24_tenant';
my $GRAPH = 'k24_graph_' . $$;
my $TABLE = 'k24_probe';

$admin->{RaiseError} = 1;
$admin->do('CREATE EXTENSION IF NOT EXISTS age');
$admin->do("DROP SCHEMA IF EXISTS $NS CASCADE");
$admin->do("CREATE SCHEMA $NS");

my @live;
END {
  for my $s (grep { $_ } @live) {
    eval { $s->storage->drop_graph($GRAPH, 1) };
  }
  if ($admin) {
    eval { $admin->do("DROP SCHEMA IF EXISTS $NS CASCADE") };
    $admin->disconnect;
  }
}

{
  package K24::Plain;
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('PostgreSQL::Age');

  package K24::Declared;
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::Age');
  __PACKAGE__->pg_extensions('age');
}

sub path_of {
  my ($schema) = @_;
  my ($p) = $schema->storage->dbh->selectrow_array(
    q{SELECT current_setting('search_path')});
  return [ map { my $e = $_; $e =~ s/^\s+|\s+$//g; $e =~ s/^"(.*)"$/$1/; $e }
           split /,/, $p ];
}

sub connect_ns {
  my ($class) = @_;
  my $schema = $class->connect($dsn, $user, $pass, {
    AutoCommit      => 1,
    RaiseError      => 1,
    PrintError      => 0,
    schema          => $NS,
    on_connect_call => 'load_age',
  });
  $schema->storage->ensure_connected;
  push @live, $schema;
  return $schema;
}

# --- case 1: the schema key alone; the driver puts no ag_catalog on the path
{
  my $schema = connect_ns('K24::Plain');
  my $path = path_of($schema);

  ok((grep { $_ eq 'ag_catalog' } @$path), 'ag_catalog is on the search_path');
  ok((grep { $_ eq $NS } @$path), 'tenant schema stays on the search_path');
  is($path->[0], $NS, 'the tenant namespace leads the search_path');
  is($path->[1], 'ag_catalog', 'ag_catalog follows the namespace entry')
    or diag "search_path: @$path";
  is(scalar(grep { $_ eq 'ag_catalog' } @$path), 1, 'ag_catalog appears exactly once')
    or diag "search_path: @$path";
  is(scalar(grep { $_ eq $NS } @$path), 1, 'tenant schema appears exactly once');

  lives_ok { $schema->storage->create_graph($GRAPH) } 'create_graph lives';
  my $rows;
  lives_ok {
    $rows = $schema->storage->cypher($GRAPH, q{ RETURN 1 }, ['one'], undef,
      { auto_decode => 1 });
  } 'cypher runs on the tenant connection';
  is($rows && $rows->[0]{one}, 1, 'cypher result comes back');

  my $dbh = $schema->storage->dbh;
  $dbh->do("CREATE TABLE $TABLE (id integer)");
  my ($where) = $dbh->selectrow_array(
    q{SELECT schemaname FROM pg_tables WHERE tablename = ?}, undef, $TABLE);
  # ag_catalog sits behind the namespace, so PostgreSQL creates unqualified
  # objects in the first existing schema of the path: the tenant.
  is($where, $NS, 'an unqualified CREATE TABLE lands in the tenant schema, not ag_catalog');
  $dbh->do("DROP TABLE $TABLE");

  $schema->storage->drop_graph($GRAPH, 1);
}

# --- case 2: the schema class declares the extension; the driver already
# puts ag_catalog on the path itself, load_age must not double it
{
  my $schema = connect_ns('K24::Declared');
  my $path = path_of($schema);

  # The driver appends ag_catalog ('<ns>, public, ag_catalog'); load_age
  # leaves a path that already holds it alone.
  is(scalar(grep { $_ eq 'ag_catalog' } @$path), 1,
    'declared age extension: ag_catalog appears exactly once');
  ok((grep { $_ eq $NS } @$path), 'declared age extension: tenant schema stays on the path');
  is($path->[-1], 'ag_catalog', 'declared age extension: the driver\'s order is kept (ag_catalog last)')
    or diag "search_path: @$path";
}

done_testing;
