use strict;
use warnings;
use Test::More;

# Pure-offline test for the `use DBIO -ix` shortcut. No real DB, no connect:
# the shortcut pins storage_type (class data) at compile time, which we read
# back directly off the schema class.

{
  package My::IX::Schema;
  use DBIO 'Schema', -ix;
}

is(
  My::IX::Schema->storage_type,
  '+DBIO::Informix::Storage',
  'use DBIO -ix sets storage_type on the Schema class',
);

ok(
  My::IX::Schema->isa('DBIO::Schema'),
  'the shortcut leaves the class a DBIO::Schema',
);

# Informix ships no DBIO::Informix::Result component, so there is no Result
# path to assert here.
ok(
  !-e 'lib/DBIO/Informix/Result.pm',
  'no DBIO::Informix::Result component (Schema path only)',
);

done_testing;
