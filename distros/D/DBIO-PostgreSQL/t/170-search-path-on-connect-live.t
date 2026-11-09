use strict;
use warnings;
use Test::More;

# LIVE: the declared pg_search_path is the search_path of every connection of
# the schema, sync and every future_io pool connection (karr k121, point 4;
# maintainer's decision 2026-10-22).
#
# WHY: the install script no longer ends with SET search_path (t/168), so the
# declaration had no effect at all. SHOW search_path on a live connection is
# the only measure that says whether it has one now.
#
# The claims: declared (a b) -> 'a, b' on the dbh and on each of two pool
# connections; nothing declared -> what a plain connection has; the connect
# key -> the namespace path, the declaration unread; on_connect_do of the
# application runs behind it and wins.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_PG_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

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
LiveServer->require_server;

BEGIN {
  package K121P4L::Result::Thing;
  $INC{'K121P4L/Result/Thing.pm'} = 1;
  use base 'DBIO::Core';
  __PACKAGE__->table('k121_p4_things');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}

my $n = 0;
sub schema_class {
  my (%o) = @_;
  my $pkg = 'K121P4L::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('PostgreSQL');
  $pkg->pg_search_path(@{ $o{search_path} }) if $o{search_path};
  $pkg->register_class(Thing => 'K121P4L::Result::Thing');
  return $pkg;
}
sub connect_to {
  my ($class, %attrs) = @_;
  return $class->connect($dsn, $user, $pass, { PrintError => 0, PrintWarn => 0, %attrs });
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

my $plain = LiveServer->control_dbh->selectrow_array('SHOW search_path');

# 1. declared
{
  my $class = schema_class(search_path => [qw( k121_a k121_b )]);
  is sync_path(connect_to($class)), 'k121_a, k121_b', 'sync: SHOW search_path is the declared path';

  my $schema = connect_to($class, async => 'future_io', pool_size => 2);
  my ($paths, $two) = pool_paths($schema);
  is_deeply $paths, [ ('k121_a, k121_b') x 2 ], 'future_io: each pool connection has the declared path';
  ok $two, '... and they are two connections';
  $schema->storage->disconnect;
}

# 2. not declared
{
  my $class = schema_class();
  is sync_path(connect_to($class)), $plain, 'sync: nothing declared, the path a plain connection has';
  my $schema = connect_to($class, async => 'future_io', pool_size => 2);
  my ($paths) = pool_paths($schema);
  is_deeply $paths, [ ($plain) x 2 ], 'future_io: nothing declared, the same';
  $schema->storage->disconnect;
}

# 3. the connect key
{
  my $class = schema_class(search_path => [qw( k121_a k121_b )]);
  is sync_path(connect_to($class, schema => 'k121_ns')), 'k121_ns, public',
    'sync: the connect key gives the namespace path, the declaration is not read';
  my $schema = connect_to($class, schema => 'k121_ns', async => 'future_io', pool_size => 2);
  my ($paths) = pool_paths($schema);
  is_deeply $paths, [ ('k121_ns, public') x 2 ], 'future_io: the same on each pool connection';
  $schema->storage->disconnect;
}

# 4. on_connect_do of the application wins
{
  my $class = schema_class(search_path => [qw( k121_a k121_b )]);
  my @do = (on_connect_do => [ 'SET search_path TO k121_mine' ]);
  is sync_path(connect_to($class, @do)), 'k121_mine', 'sync: the application\'s own path is the last word';
  my $schema = connect_to($class, @do, async => 'future_io', pool_size => 2);
  my ($paths) = pool_paths($schema);
  is_deeply $paths, [ ('k121_mine') x 2 ], 'future_io: the same on each pool connection';
  $schema->storage->disconnect;
}

done_testing;
