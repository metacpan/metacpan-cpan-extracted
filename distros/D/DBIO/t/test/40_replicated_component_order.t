use strict;
use warnings;

use Test::More;

# A driver component pins storage_type in connection() and then calls
# next::method. When it runs after DBIO::Replicated it overrides the
# replicated storage; that order is refused loudly instead of yielding a
# schema without replication.
{
  package DBIO::Test::OrderDriver;
  use base 'DBIO::Base';

  sub connection {
    my $self = shift;
    $self->storage_type('+DBIO::Test::Storage');
    return $self->next::method(@_);
  }
}

{
  package DBIO::Test::OrderSchemaWrong;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components(qw(Replicated +DBIO::Test::OrderDriver));
}

{
  package DBIO::Test::OrderSchemaRight;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components(qw(+DBIO::Test::OrderDriver Replicated));
}

my $dsn = 'dbi:Test:order';

my $err;
eval { DBIO::Test::OrderSchemaWrong->connect($dsn, '', '', {}); 1 }
  or $err = "$@";

ok defined $err, 'Replicated before the driver component refuses to connect';
like $err, qr/Replicated/, 'the message names Replicated';
like $err, qr/PostgreSQL Replicated/,
  'the message names the order: driver component first, Replicated last';
like $err, qr/DBIO::Test::Storage/, 'the message names the storage class that was set';

my $schema = DBIO::Test::OrderSchemaRight->connect(
  $dsn, '', '', { backend_storage_class => 'DBIO::Test::Storage' },
);
isa_ok $schema->storage, 'DBIO::Replicated::Storage',
  'driver component first, Replicated last gives replicated storage';

done_testing;
