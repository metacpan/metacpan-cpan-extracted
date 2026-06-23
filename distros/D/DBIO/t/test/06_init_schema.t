use strict;
use warnings;

use Test::More;
use DBIO::Test;

# Default: fake storage, no deploy, no populate
{
  my $schema = DBIO::Test->init_schema;
  isa_ok $schema, 'DBIO::Test::Schema';
  isa_ok $schema->storage, 'DBIO::Test::Storage';
  ok $schema->storage->connected, 'default is connected';
}

# no_deploy skips deploy/populate
{
  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  isa_ok $schema, 'DBIO::Test::Schema';
  # should work fine — deploy is a no-op for fake storage anyway
}

# no_connect returns unconnected schema
{
  my $schema = DBIO::Test->init_schema(no_connect => 1);
  ok $schema, 'no_connect returns a schema';
  # it's a composed namespace, not connected
}

# replicated shortcut wraps fake storage by default
{
  my $schema = DBIO::Test->init_schema(
    no_deploy  => 1,
    replicated => 1,
  );

  isa_ok $schema->storage, 'DBIO::Replicated::Storage';
  isa_ok $schema->storage->master->storage, 'DBIO::Test::Storage';
}

# replicated shortcut can wrap a requested backend storage type
{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    replicated   => 1,
    storage_type => 'DBIO::Storage::DBI::NoBindVars',
  );

  isa_ok $schema->storage, 'DBIO::Replicated::Storage';
  ok $schema->storage->master->storage->isa('DBIO::Test::Storage'),
    'replicated backend keeps fake test storage execution';
  ok $schema->storage->master->storage->isa('DBIO::Storage::DBI::NoBindVars'),
    'replicated backend also inherits requested storage type';
}

# replicated shortcut can auto-connect replicants
{
  my $schema = DBIO::Test->init_schema(
    no_deploy             => 1,
    replicated            => 1,
    replicant_connect_info => [
      ['dbi:Test:replicant_one', '', '', { AutoCommit => 1 }],
      ['dbi:Test:replicant_two', '', '', { AutoCommit => 1 }],
    ],
  );

  is scalar($schema->storage->pool->all_replicants), 2,
    'replicated shortcut auto-connects replicants';
}

# Multiple independent schemas
{
  my $s1 = DBIO::Test->init_schema;
  my $s2 = DBIO::Test->init_schema;

  $s1->storage->reset_captured;
  $s2->storage->reset_captured;

  $s1->resultset('Artist')->search({ name => 'a' })->all;
  $s2->resultset('CD')->search({ title => 'b' })->all;

  is scalar($s1->storage->captured_queries), 1, 'schema 1 has 1 query';
  is scalar($s2->storage->captured_queries), 1, 'schema 2 has 1 query';

  like( ($s1->storage->captured_queries)[0]->{sql}, qr/artist/i, 'schema 1 query is on artist' );
  like( ($s2->storage->captured_queries)[0]->{sql}, qr/cd/i, 'schema 2 query is on cd' );
}

done_testing;
