use strict;
use warnings;

use Test::More;

use DBIO::SQLite::Test;

# karr k84, core ADR 0067: a schema always has a driver, and DBIO::Test::Schema
# keeps none in its class. DBIO::SQLite::Test declares SQLite by default -- on
# the plain path and as the driver of every backend on the replicated path --
# and a storage_type the caller names wins.

local $ENV{DBIO_TEST_DSN};

{
  package DBIO::SQLite::Test::K84Storage;
  use base 'DBIO::SQLite::Storage';
}

{
  my $schema = DBIO::SQLite::Test->init_schema(no_deploy => 1);
  is ref $schema->storage, 'DBIO::SQLite::Storage',
    'init_schema declares DBIO::SQLite::Storage when the caller names no storage_type';
  ok !$schema->storage->connected,
    '... as a declaration, before any connection decides anything';
}

{
  my $schema = DBIO::SQLite::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::SQLite::Test::K84Storage',
  );
  is ref $schema->storage, 'DBIO::SQLite::Test::K84Storage',
    'a storage_type the caller names wins over the default';
}

{
  my $schema = DBIO::SQLite::Test->init_schema(
    no_deploy              => 1,
    replicated             => 1,
    replicant_connect_info => [
      ['dbi:SQLite:dbname=:memory:', '', '', { AutoCommit => 1 }],
    ],
  );
  my $storage = $schema->storage;
  isa_ok $storage, 'DBIO::Replicated::Storage';
  is $storage->backend_storage_class, 'DBIO::SQLite::Storage',
    'replicated => 1 builds its backends from the declared SQLite driver';
  my @replicants = $storage->pool->all_replicants;
  is scalar @replicants, 1, 'one replicant';
  isa_ok $_->storage, 'DBIO::SQLite::Storage', 'the replicant storage' for @replicants;
}

{
  my $schema = DBIO::SQLite::Test->init_schema(
    no_deploy    => 1,
    replicated   => 1,
    storage_type => 'DBIO::SQLite::Test::K84Storage',
  );
  is $schema->storage->backend_storage_class, 'DBIO::SQLite::Test::K84Storage',
    'replicated => 1 runs its backends on the storage_type the caller names';
}

{
  my $schema = DBIO::SQLite::Test->init_schema(
    no_deploy    => 1,
    storage_type => {
      'DBIO::Replicated::Storage' => {
        backend_storage_class => 'DBIO::SQLite::Test::K84Storage',
      },
    },
  );
  is $schema->storage->backend_storage_class, 'DBIO::SQLite::Test::K84Storage',
    'a full replicated storage_type keeps the backend_storage_class it gives';
}

done_testing;
