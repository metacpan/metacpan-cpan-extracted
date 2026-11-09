#!/usr/bin/env perl
# t/31-ddl-column-type.t — DBIO::DuckDB::DDL's _duckdb_column_type, the sole
# column-type renderer behind install_ddl's CREATE TABLE generator. Pure
# function, no database. Regression test for karr #9: declared
# $info->{size} was silently dropped for every size-parameterizable mapped
# type (varchar/char/text family, numeric/decimal).

use strict;
use warnings;
use Test::More;
use DBIO::DuckDB::DDL;

# Sized types: size must be re-attached after the %type_map lookup.
is DBIO::DuckDB::DDL::_duckdb_column_type({ data_type => 'varchar', size => 100 }),
  'VARCHAR(100)', 'varchar + size -> VARCHAR(100)';
is DBIO::DuckDB::DDL::_duckdb_column_type({ data_type => 'char', size => 10 }),
  'VARCHAR(10)', 'char + size -> VARCHAR(10)';
is DBIO::DuckDB::DDL::_duckdb_column_type({ data_type => 'character', size => 5 }),
  'VARCHAR(5)', 'character + size -> VARCHAR(5)';
is DBIO::DuckDB::DDL::_duckdb_column_type({ data_type => 'text', size => 255 }),
  'VARCHAR(255)', 'text + size -> VARCHAR(255)';
is DBIO::DuckDB::DDL::_duckdb_column_type({ data_type => 'decimal', size => [10, 2] }),
  'DECIMAL(10,2)', 'decimal + size -> DECIMAL(10,2)';
is DBIO::DuckDB::DDL::_duckdb_column_type({ data_type => 'numeric', size => [5, 0] }),
  'DECIMAL(5,0)', 'numeric + size -> DECIMAL(5,0)';

# Unsized use of the same types: no trailing parens.
is DBIO::DuckDB::DDL::_duckdb_column_type({ data_type => 'varchar' }),
  'VARCHAR', 'unsized varchar unaffected';
is DBIO::DuckDB::DDL::_duckdb_column_type({ data_type => 'decimal' }),
  'DECIMAL', 'unsized decimal unaffected';

# Unrelated types are unaffected even if size happens to be set (shouldn't
# happen in practice, but the mapping must not misfire on other types).
is DBIO::DuckDB::DDL::_duckdb_column_type({ data_type => 'integer', size => 100 }),
  'INTEGER', 'sized integer unaffected';
is DBIO::DuckDB::DDL::_duckdb_column_type({ data_type => 'boolean' }),
  'BOOLEAN', 'boolean unaffected';

# money already carries its own parenthesized DuckDB type; must not be
# double-appended even though it maps through the same DECIMAL family.
is DBIO::DuckDB::DDL::_duckdb_column_type({ data_type => 'money' }),
  'DECIMAL(19,4)', 'money keeps its fixed precision, no double append';

# A data_type that already bakes size into the string (the pre-existing
# escape hatch) is returned verbatim, size key ignored.
is DBIO::DuckDB::DDL::_duckdb_column_type({ data_type => 'varchar(20)', size => 999 }),
  'varchar(20)', 'pre-parenthesized data_type short-circuits, size ignored';

done_testing;
