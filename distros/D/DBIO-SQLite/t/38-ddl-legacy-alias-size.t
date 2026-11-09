use strict;
use warnings;
use Test::More;

use DBIO::SQLite::DDL;

# Regression for karr k15.
#
# _sqlite_column_type() has two paths: portable base types (delegate to the
# adapter, which correctly renders size) and legacy %type_map aliases (which
# only appended size for the exact native names VARCHAR/CHAR). 'decimal' and
# 'character' are legacy aliases -- not DBIO::Schema::Type base types -- so
# they fell into the legacy path and lost their size:
#
#   data_type => 'decimal',   size => [10,2]  ->  bare NUMERIC   (wrong)
#   data_type => 'character', size => 24      ->  bare CHARACTER (wrong)
#
# This test locks in the fix: legacy-mapped NUMERIC/DECIMAL honor an [p,s]
# arrayref size, and legacy-mapped CHARACTER honors a scalar length, the same
# way VARCHAR/CHAR already did.

{
  package DDLSizeTest::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package DDLSizeTest::Schema::Result::Item;
  use base 'DBIO::Core';

  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id     => { data_type => 'integer', is_auto_increment => 1 },
    price  => { data_type => 'decimal',   size => [10, 2] },
    code   => { data_type => 'character', size => 24 },
  );
  __PACKAGE__->set_primary_key('id');
}
DDLSizeTest::Schema->register_class(Item => 'DDLSizeTest::Schema::Result::Item');

my $ddl = DBIO::SQLite::DDL->install_ddl('DDLSizeTest::Schema');

like($ddl, qr/"price" NUMERIC\(10,2\)/, 'legacy decimal alias keeps precision/scale');
like($ddl, qr/"code" CHARACTER\(24\)/,  'legacy character alias keeps length');

# Sizeless legacy aliases still render bare (no regression on the common case).
is(DBIO::SQLite::DDL::_sqlite_column_type({ data_type => 'decimal' }),
  'NUMERIC', 'sizeless decimal renders bare NUMERIC');
is(DBIO::SQLite::DDL::_sqlite_column_type({ data_type => 'character' }),
  'CHARACTER', 'sizeless character renders bare CHARACTER');

done_testing;
