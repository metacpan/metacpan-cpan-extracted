use strict;
use warnings;
use Test::More;

# Offline test for the DBIO::Shortcut::fb stub (`use DBIO -fb`).
# No DBI, no DSN, no real database — pure class-setup assertions.

# The stub must work cold: loading it on its own should be enough for the
# two-tier resolver in core to delegate to DBIO->apply_driver(..., 'Firebird').
require_ok 'DBIO::Shortcut::fb';
can_ok 'DBIO::Shortcut::fb', 'apply';

# Schema class using the shortcut alongside the base role.
{
  package MyTest::Shortcut::Schema;
  use DBIO 'Schema', -fb;
}

ok 'MyTest::Shortcut::Schema'->isa('DBIO::Schema'),
  q{use DBIO 'Schema', -fb sets up DBIO::Schema inheritance};

is 'MyTest::Shortcut::Schema'->storage_type, '+DBIO::Firebird::Storage',
  q{-fb pins storage_type to +DBIO::Firebird::Storage on a Schema class};

# Firebird ships no DBIO::Firebird::Result component, so apply_driver is a
# no-op on a Result class — it must NOT die and must NOT pull in a component.
{
  package MyTest::Shortcut::Result::Thing;
  use DBIO 'Core', -fb;
}

ok 'MyTest::Shortcut::Result::Thing'->isa('DBIO::Core'),
  q{use DBIO 'Core', -fb sets up DBIO::Core inheritance};

ok !'MyTest::Shortcut::Result::Thing'->isa('DBIO::Firebird::Result'),
  q{-fb does not load a Result component (Firebird has none)};

done_testing;
