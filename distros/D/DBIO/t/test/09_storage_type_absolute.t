use strict;
use warnings;

use Test::More;

use DBIO::Test::Schema;

{
  package TestSchema;
  use base 'DBIO::Test::Schema';
  __PACKAGE__->storage_type('+DBIO::Test::Storage');
}

my $schema = TestSchema->connect;

isa_ok $schema->storage, 'DBIO::Test::Storage', 'absolute +storage_type resolves correctly';
ok $schema->storage->connected, 'absolute +storage_type schema is connected';

done_testing;
