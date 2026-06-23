use strict;
use warnings;
use Test::More;

# OFFLINE: pure shortcut-wiring test. No DB, no connect, no DBIO::Test::Storage
# mock needed -- the shortcut sets storage_type at `use` time on the package.

{
  package My::Ora::Schema;
  use DBIO 'Schema', -ora;
}

ok( My::Ora::Schema->isa('DBIO::Schema'),
  'schema class is a DBIO::Schema via -ora shortcut' );

is( My::Ora::Schema->storage_type, '+DBIO::Oracle::Storage',
  '-ora shortcut pins storage_type to +DBIO::Oracle::Storage' );

# DBIO::Oracle has no Result component, so the Result path is a no-op by
# convention -- nothing to assert there for this driver.
ok( !-e 'lib/DBIO/Oracle/Result.pm',
  'DBIO::Oracle ships no Result component (Schema path only)' );

done_testing;
