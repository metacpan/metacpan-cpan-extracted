use strict;
use warnings;

use Test::More;

# Offline only: this test never touches a real database. It asserts that the
# `use DBIO 'Schema', -db2;` shortcut pins the DB2 storage driver onto the
# schema class via DBIO::Shortcut::db2 -> DBIO->apply_driver.

{
  package My::DB2::Schema;
  use DBIO 'Schema', -db2;
}

ok(
  My::DB2::Schema->isa('DBIO::Schema'),
  'schema using -db2 isa DBIO::Schema'
);

is(
  My::DB2::Schema->storage_type,
  '+DBIO::DB2::Storage',
  '-db2 shortcut pins storage_type to +DBIO::DB2::Storage'
);

done_testing;
