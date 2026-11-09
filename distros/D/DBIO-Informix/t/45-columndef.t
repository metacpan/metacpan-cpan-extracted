use strict;
use warnings;
use Test::More;

# Unit test for the shared Informix column-definition renderer. This is the
# single grammar that DDL, Diff::Table and Diff::Column all delegate to.

use_ok 'DBIO::Informix::ColumnDef';
DBIO::Informix::ColumnDef->import('column_def_sql');

is(column_def_sql(name => 'id', type => 'integer'),
  'id integer', 'plain column');

is(column_def_sql(name => 'name', type => 'varchar(255)', not_null => 1),
  'name varchar(255) NOT NULL', 'not null');

# Default quoting is type-aware.
is(column_def_sql(name => 'flag', type => 'integer', default_value => '0'),
  'flag integer DEFAULT 0', 'numeric default unquoted');

is(column_def_sql(name => 'label', type => 'varchar(64)', default_value => 'hi'),
  q{label varchar(64) DEFAULT 'hi'}, 'character default quoted');

is(column_def_sql(name => 'q', type => 'integer', not_null => 1, default_value => '0'),
  'q integer DEFAULT 0 NOT NULL', 'DEFAULT precedes NOT NULL (HCL ALTER TABLE MODIFY example: DEFAULT 1 NOT NULL; live unmeasured, karr k14)');

is(column_def_sql(name => 'ts', type => 'datetime year to second', default_value => \'today'),
  'ts datetime year to second DEFAULT today', 'SCALAR ref => literal SQL, unquoted');

# SERIAL is a type, not a modifier: never doubled, never combined with a base
# type, and carries no DEFAULT.
is(column_def_sql(name => 'id', type => 'integer', is_auto_increment => 1),
  'id SERIAL', 'auto_increment collapses to SERIAL, base type dropped');

is(column_def_sql(name => 'id', type => 'serial', is_auto_increment => 1, not_null => 1),
  'id SERIAL NOT NULL', 'no double SERIAL');

is(column_def_sql(name => 'id', type => 'integer', is_auto_increment => 1, default_value => '5'),
  'id SERIAL', 'serial drops default');

# Identifiers are quoted.
like(column_def_sql(name => 'order', type => 'integer'),
  qr/^"?order"?\sinteger$/, 'name passed through identifier quoting');

# karr k22 -- SERIAL8 and BIGSERIAL are types of their own; auto-increment
# must not turn them into a 4-byte SERIAL
is(column_def_sql(name => 'id', type => 'serial8', is_auto_increment => 1, not_null => 1),
  'id SERIAL8 NOT NULL', 'serial8 stays serial8');
is(column_def_sql(name => 'id', type => 'bigserial', is_auto_increment => 1),
  'id BIGSERIAL', 'bigserial stays bigserial');
is(column_def_sql(name => 'id', type => 'bigint', is_auto_increment => 1),
  'id SERIAL', 'any other auto-increment type is SERIAL');

done_testing;
