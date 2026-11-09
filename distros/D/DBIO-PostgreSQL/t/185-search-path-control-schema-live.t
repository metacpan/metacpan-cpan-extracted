use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    1;
  } or plan skip_all =>
    'Future::IO::Impl::IOAsync + IO::Async required for the live future_io transport';
}

eval { require DBIO::PostgreSQL::Storage::Async; 1 }
  or plan skip_all => 'DBIO::Async not installed -- future_io transport unavailable';

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# karr k142 (b) -- the search_path of a connection with the connect key
# `schema` holds, for a declared extension that names no schema, the schema
# its control file fixes (postgis_topology: topology, age: ag_catalog), as the
# CREATE EXTENSION of the install does. Before, it held public, so the objects
# of the extension were not found unqualified on the connection.
#
# WHY postgis_topology first: age's own activation puts ag_catalog on the path
# anyway, so it cannot tell the control-file rule from the activation.
# postgis_topology has no activation; its schema is on the path only if the
# storage asked the server. Sync and each future_io pool connection must
# agree, because both replay the same seam on different transports.
#
# Needs the extensions on the server (not installed: the control file is read
# from pg_available_extension_versions); skipped, with the reason, otherwise.

{
  my $h = LiveServer->control_dbh;
  my %avail = map { $_ => 1 } @{ $h->selectcol_arrayref(
    q{SELECT name FROM pg_catalog.pg_available_extensions
       WHERE name IN ('age', 'postgis', 'postgis_topology')}) };
  $h->disconnect;
  for my $need (qw(age postgis postgis_topology)) {
    plan skip_all => "extension $need not available on the server" unless $avail{$need};
  }
}

for my $module (qw(DBIO::PostgreSQL::Age DBIO::PostgreSQL::PostGIS)) {
  eval "require $module; 1" or plan skip_all => "$module not installed";
}

($dsn, $user, $pass) = PrivatePgDatabase->create('pg_k142');

my $n = 0;
sub schema_class {
  my (@ext) = @_;
  my $pkg = 'K142Live::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('PostgreSQL');
  $pkg->pg_extensions(@ext);
  return $pkg;
}
sub connect_to {
  my ($class, %attrs) = @_;
  return $class->connect($dsn, $user, $pass,
    { PrintError => 0, PrintWarn => 0, schema => 'k142_tenant', %attrs });
}
sub sync_path { scalar $_[0]->storage->dbh->selectrow_array('SHOW search_path') }
sub pool_paths {
  my ($schema) = @_;
  my $async = $schema->storage->async;
  my @rows = map { $_->get } map {
    $async->select_async('pg_namespace',
      [ \q{current_setting('search_path')}, \'pg_backend_pid()' ], { nspname => 'pg_catalog' })
  } 1, 2;
  return ([ map { $_->[0] } @rows ], $rows[0][1] != $rows[1][1]);
}

# 1. no activation: only the control file can put topology on the path
{
  my $class = schema_class('postgis', 'postgis_topology');
  my $want  = 'k142_tenant, public, topology';
  is sync_path(connect_to($class)), $want,
    'sync: postgis_topology without a declared schema -> topology from its control file';
  my $schema = connect_to($class, async => 'future_io', pool_size => 2);
  my ($paths, $two) = pool_paths($schema);
  is_deeply $paths, [ ($want) x 2 ], 'future_io: each pool connection has the same path';
  ok $two, '... and they are two connections';
  $schema->storage->disconnect;
}

# 2. a declared schema wins over the control file, with no query needed
{
  my $class = schema_class('postgis', postgis_topology => { schema => 'topology' });
  my $schema = connect_to($class);
  is sync_path($schema), 'k142_tenant, public, topology',
    'sync: a declared schema is the one on the path';
  $schema->storage->disconnect;
}

# 3. age, as in the task: ag_catalog on the path, sync and pool alike
{
  my $class = schema_class('age');
  my $sync = sync_path(connect_to($class));
  like $sync, qr/\bag_catalog\b/, 'sync: age -> ag_catalog is on the path';
  unlike $sync, qr/\bpublic\b/,
    '... in the place of public, which the install does not use for age';
  my $schema = connect_to($class, async => 'future_io', pool_size => 2);
  my ($paths) = pool_paths($schema);
  is_deeply $paths, [ ($sync) x 2 ], 'future_io: the pool connections have the sync path';
  $schema->storage->disconnect;
}

done_testing;
