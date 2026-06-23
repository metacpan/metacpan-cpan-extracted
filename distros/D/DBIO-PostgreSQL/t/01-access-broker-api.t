use strict;
use warnings;

use Test::More;

use DBIO::AccessBroker::Credentials;

{
  package TestSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

my $broker = DBIO::AccessBroker::Credentials->new(
  dsn      => 'dbi:Pg:dbname=dbio_test;host=localhost',
  username => 'dbio',
  password => 'secret',
);

my $schema = TestSchema->connect($broker);

isa_ok $schema->storage, 'DBIO::PostgreSQL::Storage';
is $schema->storage->access_broker, $broker, 'postgresql storage keeps broker';
is $schema->storage->access_broker_mode, 'write', 'postgresql storage defaults broker mode to write';

done_testing;
