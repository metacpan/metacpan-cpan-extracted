use strict;
use warnings;

use Test::More;

use DBIO::Deploy::Base;

# Deploy asks the driver's own hooks (_ddl_quote_ident, _ddl_sql_dialect, ...)
# of the storage that is the driver's. Over a replicated storage that is the
# master's storage: the replicated storage forwards a named list of methods and
# nothing else, so such a hook is not reached through it.
{
  package DBIO::Test::DeployHookStorage;
  use base 'DBIO::Test::Storage';

  sub _ddl_quote_ident { '<' . $_[1] . '>' }
  sub _ddl_sql_dialect { 'hookdialect' }
}

{
  package DBIO::Test::DeployHookDriver;
  use base 'DBIO::Base';

  sub connection {
    my $self = shift;
    $self->storage_type('+DBIO::Test::Storage');
    return $self->next::method(@_);
  }
}

{
  package DBIO::Test::DeployHookReplicated;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components(qw(+DBIO::Test::DeployHookDriver Replicated));
}

my $schema = DBIO::Test::DeployHookReplicated->connect(
  'dbi:Test:deploy', '', '',
  { backend_storage_class => 'DBIO::Test::DeployHookStorage' },
);
isa_ok $schema->storage, 'DBIO::Replicated::Storage';
ok !$schema->storage->can('_ddl_quote_ident'),
  'the replicated storage itself does not know the driver hook';

my $deploy = DBIO::Deploy::Base->new(schema => $schema);

isa_ok $deploy->_driver_storage, 'DBIO::Test::DeployHookStorage',
  'the driver storage of a replicated schema is the master\'s';
is $deploy->_driver_storage, $schema->storage->master->storage,
  'and it is the very storage of the master';
is $deploy->_ddl_quote_ident('t'), '<t>',
  'the driver\'s quoting hook is reached through a replicated storage';

# a plain storage is its own driver storage
my $plain = $schema->storage->master->storage;
is DBIO::Deploy::Base::driver_storage($plain), $plain,
  'a storage that is not replicated is returned as it is';

done_testing;
