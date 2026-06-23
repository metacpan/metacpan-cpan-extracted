use strict;
use warnings;

use Test::More;

use DBIO::SQLite::Test;

my $schema = DBIO::SQLite::Test->init_schema(
  no_deploy             => 1,
  replicated            => 1,
  replicant_connect_info => [
    ['dbi:SQLite:dbname=:memory:', '', '', { AutoCommit => 1 }],
  ],
);

isa_ok $schema->storage, 'DBIO::Replicated::Storage', 'SQLite test helper supports replicated mode';
isa_ok $schema->storage->master->storage, 'DBIO::SQLite::Storage', 'master uses SQLite storage';
is scalar($schema->storage->pool->all_replicants), 1, 'replicant connect_info applied through SQLite test helper';

done_testing;
