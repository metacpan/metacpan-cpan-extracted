use strict;
use warnings;
use Test::More;

# Pure-offline test: exercise the `use DBIO -sqlite` shortcut without ever
# touching a real database. No connect(), no deploy() -- we only assert the
# static class-data side effects of DBIO::Shortcut::sqlite->apply($caller).

# Schema class: the shortcut must pin +DBIO::SQLite::Storage as storage_type.
{
  package My::Shortcut::Schema;
  use DBIO 'Schema', -sqlite;
}

is(
  My::Shortcut::Schema->storage_type,
  '+DBIO::SQLite::Storage',
  'use DBIO -sqlite on a Schema sets storage_type to +DBIO::SQLite::Storage',
);

# Result class: the shortcut must load the DBIO::SQLite::Result component,
# making the class isa DBIO::SQLite::Result and giving it the component's
# methods (sqlite_index / sqlite_indexes).
{
  package My::Shortcut::Schema::Result::Artist;
  use DBIO 'Core', -sqlite;
}

isa_ok(
  'My::Shortcut::Schema::Result::Artist',
  'DBIO::SQLite::Result',
  'use DBIO -sqlite on a Result class composes DBIO::SQLite::Result',
);

can_ok('My::Shortcut::Schema::Result::Artist', 'sqlite_index');
can_ok('My::Shortcut::Schema::Result::Artist', 'sqlite_indexes');

done_testing;
