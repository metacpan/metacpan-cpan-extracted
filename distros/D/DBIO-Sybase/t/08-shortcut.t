use strict;
use warnings;
use Test::More;

# Pure-offline test: exercise the `use DBIO -syb` shortcut without ever
# touching a real database. No connect(), no deploy() -- we only assert the
# static class-data side effect of DBIO::Shortcut::syb->apply($caller).
#
# The Sybase driver has no DBIO::Sybase::Result component, so only the Schema
# path applies: apply_driver pins +DBIO::Sybase::Storage as storage_type.
{
  package My::Shortcut::Schema;
  use DBIO 'Schema', -syb;
}

is(
  My::Shortcut::Schema->storage_type,
  '+DBIO::Sybase::Storage',
  'use DBIO -syb on a Schema sets storage_type to +DBIO::Sybase::Storage',
);

done_testing;
