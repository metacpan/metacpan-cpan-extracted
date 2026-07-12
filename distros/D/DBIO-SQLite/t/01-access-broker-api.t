use strict;
use warnings;

use Test::More;

use DBIO::AccessBroker::Static;

{
  package TestSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}

my $broker = DBIO::AccessBroker::Static->new(
  dbname   => ':memory:',
  username => '',
  password => '',
);

my $schema = TestSchema->connect($broker);

isa_ok $schema->storage, 'DBIO::SQLite::Storage';
is $schema->storage->access_broker, $broker, 'sqlite storage keeps broker';
is $schema->storage->access_broker_mode, 'write', 'sqlite storage defaults broker mode to write';

done_testing;
