use strict;
use warnings;

use Test::More;

# The connection's namespace (connect key `schema`) is held by the backends the
# replicated storage drives. Asked on the replicated storage, it answers with
# the master's, the same way every capability does.
{
  package DBIO::Test::SchemaOrderDriver;
  use base 'DBIO::Base';

  sub connection {
    my $self = shift;
    $self->storage_type('+DBIO::Test::Storage');
    return $self->next::method(@_);
  }
}

{
  package DBIO::Test::SchemaReplicated;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components(qw(+DBIO::Test::SchemaOrderDriver Replicated));
}

my $dsn = 'dbi:Test:schema';

my $with = DBIO::Test::SchemaReplicated->connect(
  $dsn, '', '', { backend_storage_class => 'DBIO::Test::Storage', schema => 'x' },
);
isa_ok $with->storage, 'DBIO::Replicated::Storage';
is $with->storage->master->storage->connection_schema, 'x',
  'the master backend carries the schema';
is $with->storage->connection_schema, 'x',
  'connection_schema on the replicated storage is the master\'s';

my $without = DBIO::Test::SchemaReplicated->connect(
  $dsn, '', '', { backend_storage_class => 'DBIO::Test::Storage' },
);
is $without->storage->connection_schema, undef,
  'without a schema connection_schema is undef';

done_testing;
