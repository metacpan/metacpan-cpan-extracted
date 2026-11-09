use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;

# Regression for karr #24.
#
# _mysql_column_type() has two paths: portable base types (delegate to the
# adapter, which correctly renders size) and legacy %type_map aliases (which
# only appended size for varchar/varbinary/binary, DDL.pm:190). 'decimal' and
# 'character' are legacy aliases -- not DBIO::Schema::Type base types (see
# DBIO::Schema::Type's %ALIAS vs @BASE_TYPES) -- so they fell into the legacy
# path and lost their size:
#
#   data_type => 'decimal',   size => [10,2]  ->  bare decimal(10,2) (hardcoded, size ignored)
#   data_type => 'character', size => 24      ->  bare character     (size dropped entirely)
#
# This locks in the fix: legacy-mapped decimal honors a [precision,scale]
# arrayref size, and legacy-mapped character honors a scalar length, the same
# way varchar/varbinary/binary already did -- falling back to the historical
# defaults only when size is genuinely absent.

is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'decimal', size => [10, 2] }),
  'decimal(10,2)', 'decimal honors [precision,scale] size');

is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'decimal', size => [12, 4] }),
  'decimal(12,4)', 'different precision/scale honored, not hardcoded 10,2');

is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'decimal' }),
  'decimal(10,2)', 'sizeless decimal falls back to the legacy default');

# karr #26: the #24 fix required an ARRAY ref with BOTH members defined, so the
# two remaining size shapes still reached the hardcoded decimal(10,2) -- and
# that is the wrong-size variant of the bug, not the missing-size one: a column
# asking for 20 digits silently got 10, so values are rounded or rejected at
# insert time. Precision-only renders decimal($p) (MySQL's DECIMAL(M) is
# DECIMAL(M,0)), which is the spelling DBIO::MSSQL::DDL::_mssql_column_type
# already uses -- deliberately not a third convention.

is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'decimal', size => 8 }),
  'decimal(8)', 'decimal honors a bare scalar size as the precision');

is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'decimal', size => [20] }),
  'decimal(20)', 'decimal honors a precision-only [p] size');

is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'decimal', size => 20 }),
  'decimal(20)', 'the requested precision survives -- not silently narrowed to 10');

is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'decimal', size => [] }),
  'decimal(10,2)', 'an empty size arrayref is no size at all -> legacy default');

is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'character', size => 24 }),
  'character(24)', 'character honors scalar size');

# Mirror image of the decimal gap: character takes a scalar, so an arrayref
# size used to stringify the reference into the type -- character(ARRAY(0x...)),
# which no server accepts.
is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'character', size => [24] }),
  'character(24)', 'character reads the length out of a [length] arrayref');

is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'character' }),
  'character', 'sizeless character still renders bare (no regression)');

# karr #37: the varchar/varbinary/binary branch a dozen lines above these two
# aliases (DDL.pm:190) read size the way `character` did before #26 -- it
# interpolated whatever was there, so an arrayref stringified into the type as
# varchar(ARRAY(0x...)), a statement no server accepts. All three take exactly
# ONE scalar length (MySQL 8.0 Reference Manual 13.3.2 and 13.3.3: VARCHAR(M),
# BINARY[(M)], VARBINARY(M)), so all three get the same "first member is the
# width" reading `character` got, and a size that names no width falls back to
# the legacy default just as it does for decimal.

is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'varchar', size => 64 }),
  'varchar(64)', 'varchar honors a bare scalar length (no regression)');

is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'varchar', size => [64] }),
  'varchar(64)', 'varchar reads the length out of a [length] arrayref');

is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'varbinary', size => [16] }),
  'varbinary(16)', 'varbinary takes one scalar length too -- same reading');

is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'binary', size => [16] }),
  'binary(16)', 'binary takes one scalar length too -- same reading');

# A second member names nothing on a single-width type, so it is dropped rather
# than stringified -- which is what `character` has done since #26. Both are
# pinned here so the two readings cannot drift apart.
is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'varchar', size => [10, 2] }),
  'varchar(10)', 'a surplus size member is dropped, not stringified');

is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'character', size => [24, 4] }),
  'character(24)', 'character drops a surplus size member the same way');

is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'varchar', size => [] }),
  'varchar(255)', 'an empty size arrayref is no length at all -> legacy default');

is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'varchar' }),
  'varchar(255)', 'sizeless varchar still falls back to the legacy default');

# End-to-end: prove the fix is wired through install_ddl on a real schema.
{
  package DDLSizeTest::MySQL::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package DDLSizeTest::MySQL::Schema::Result::Item;
  use DBIO;

  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    price   => { data_type => 'decimal',   size => [10, 2] },
    code    => { data_type => 'character', size => 24 },
    balance => { data_type => 'decimal',   size => [20] },
    counter => { data_type => 'decimal',   size => 8 },
    label   => { data_type => 'varchar',   size => [64] },
    token   => { data_type => 'varbinary', size => [16] },
    note    => { data_type => 'varchar',   size => 64, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
DDLSizeTest::MySQL::Schema->register_class(Item => 'DDLSizeTest::MySQL::Schema::Result::Item');

my $ddl = DBIO::MySQL::DDL->install_ddl('DDLSizeTest::MySQL::Schema');
like($ddl, qr/`price` decimal\(10,2\)/, 'install_ddl: legacy decimal alias keeps precision/scale');
like($ddl, qr/`code` character\(24\)/,  'install_ddl: legacy character alias keeps length');
like($ddl, qr/`balance` decimal\(20\)/, 'install_ddl: precision-only decimal keeps its 20 digits');
like($ddl, qr/`counter` decimal\(8\)/,  'install_ddl: scalar-size decimal keeps its 8 digits');
like($ddl, qr/`label` varchar\(64\)/,   'install_ddl: varchar reads an arrayref length instead of stringifying it');
like($ddl, qr/`token` varbinary\(16\)/, 'install_ddl: varbinary does too -- the whole branch, not just varchar');

# karr #147 / ADR 0043: canonical_column turns a MISSING is_nullable into
# not_null=1, so the driver DDL must emit NOT NULL for it too -- not only for an
# explicit is_nullable => 0. The columns above carry no is_nullable key at all;
# `note` is the explicit-nullable counterexample.
like($ddl, qr/`price` decimal\(10,2\) NOT NULL/, 'install_ddl: missing is_nullable deploys as NOT NULL (karr #147, ADR 0043)');
# The whole line of the column, and nothing after its type: a pattern that
# only must not match would go on passing if the line were written another way.
like($ddl, qr/^  `note` varchar\(64\),$/m,       'install_ddl: explicit is_nullable => 1 stays nullable');

done_testing;
