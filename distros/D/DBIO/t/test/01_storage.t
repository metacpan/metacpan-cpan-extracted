use strict;
use warnings;

use Test::More;
use DBIO::Test;

my $schema = DBIO::Test->init_schema;

isa_ok $schema, 'DBIO::Test::Schema', 'init_schema returns correct class';
isa_ok $schema->storage, 'DBIO::Test::Storage', 'storage is fake';
ok $schema->storage->connected, 'fake storage reports connected';

# sql_maker works
my $sm = $schema->storage->sql_maker;
ok $sm, 'sql_maker is available';
isa_ok $sm, 'DBIO::SQLMaker', 'sql_maker is correct class';

# disconnect/reconnect
$schema->storage->disconnect;
ok !$schema->storage->connected, 'disconnected';

done_testing;
