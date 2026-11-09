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

# ADR 0066 in the driver (karr k136): the activation of the declared
# extensions reaches every new connection -- the sync one and each connection
# of a future_io pool. The extension here is a fake one that asks for a
# library the server has everywhere (plpgsql) and a schema for the path, so
# the test needs neither AGE nor its distribution.
#
# What this file claims:
#   1. a sync connection without the connect key has the entries of the
#      activation appended to the search_path it had;
#   2. with the key: the namespace first, then the declaration's schemas, then
#      the entries;
#   3. the same on every connection of a future_io pool;
#   4. LOAD of the library runs on the connection (it does not fail);
#   5. a future_io schema that goes out of scope closes its pool connections
#      with it: no connection of this test is left on its database (core k406).

($dsn, $user, $pass) = PrivatePgDatabase->create('t147');

{
  package K136L::Probe;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'k136probe' }
  sub driver { 'DBIO::PostgreSQL' }
  sub activation { { load => 'plpgsql', search_path => ['k136_act'] } }
}
$INC{'K136L/Probe.pm'} = __FILE__;

{
  package K136L::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_extensions(k136probe => { class => 'K136L::Probe' });
}

my @db = ($dsn, $user, $pass);
my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });

sub path_of {
  my ($schema) = @_;
  return scalar $schema->storage->dbh->selectrow_array('SHOW search_path');
}

my $default = do {
  my $h = LiveServer->control_dbh(login => \@db);
  my ($p) = $h->selectrow_array('SHOW search_path');
  $h->disconnect;
  $p;
};

{
  my $schema = K136L::Schema->connect(@db, @CONNECT);
  is path_of($schema), "$default, k136_act",
    'no key: the connection has its default search_path, the entries of the activation behind it';
  ok eval { $schema->storage->dbh->do(q{LOAD 'plpgsql'}); 1 }, 'the library the extension asks for can be loaded here';
  $schema->storage->disconnect;
}
{
  my $schema = K136L::Schema->connect(@db, { schema => 'tenant_a', %{ $CONNECT[0] } });
  is path_of($schema), 'tenant_a, public, k136_act',
    'with the key: the namespace, public (no schema declared), the entries';
  $schema->storage->disconnect;
}
{
  package K136L::Schema2;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_extensions(k136probe => { class => 'K136L::Probe', schema => 'k136_ext' });
}
{
  my $schema = K136L::Schema2->connect(@db, { schema => 'tenant_b', %{ $CONNECT[0] } });
  is path_of($schema), 'tenant_b, k136_ext, k136_act',
    'the schema of the declaration comes before the entries';
  $schema->storage->disconnect;
}

SKIP: {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    require DBIO::PostgreSQL::Storage::Async;
    1;
  } or skip 'Future::IO::Impl::IOAsync, IO::Async and DBIO::Async are needed for future_io', 5;

  my @path = ('pg_namespace', [ \q{current_setting('search_path')}, \'pg_backend_pid()' ],
    { nspname => 'pg_catalog' });

  for my $case ([ 'tenant_c', 'tenant_c, public, k136_act' ], [ undef, "$default, k136_act" ]) {
    my ($namespace, $want) = @$case;
    my $schema = K136L::Schema->connect(@db,
      { (defined $namespace ? (schema => $namespace) : ()), async => 'future_io', pool_size => 2, PrintError => 0 });
    my $async = $schema->storage->async;
    my @rows = map { $_->get } map { $async->select_async(@path) } 1, 2;
    is_deeply [ map { $_->[0] } @rows ], [ ($want) x 2 ],
      'pool connections ' . (defined $namespace ? "with the key" : 'without it') . ' have the path of the activation';
    isnt $rows[0][1], $rows[1][1], '... and they are two connections';
  }

  # The schemas of the loop are gone. Nothing waits and no loop runs here:
  # freeing the schema is what closes its connections.
  my $control = LiveServer->control_dbh(login => \@db);
  my ($open) = $control->selectrow_array(
    'SELECT count(*) FROM pg_stat_activity WHERE datname = current_database() AND pid <> pg_backend_pid()');
  $control->disconnect;
  is $open, 0, 'the future_io schemas are freed: none of their connections is open any more';
}

done_testing;
