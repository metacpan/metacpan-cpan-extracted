use strict;
use warnings;
use Test::More;

# Offline coverage for the shared DDL emit helpers. These two functions are
# the single source of truth for Sybase type rendering and DEFAULT clauses --
# DBIO::Sybase::DDL (install_ddl) and DBIO::Sybase::Diff::{Table,Column} all
# route through them, so locking their behaviour here guards against the
# duplication regressing back into per-emitter copies.

use_ok 'DBIO::Sybase::DDL';

use DBIO::Sybase::DDL qw( sybase_column_type sybase_default_clause );

# --- sybase_column_type -------------------------------------------------
my %type_map = (
  integer          => 'INT',
  bigint           => 'INT',
  smallint         => 'SMALLINT',
  tinyint          => 'SMALLINT',
  serial           => 'BIGINT',
  bigserial        => 'BIGINT',
  varchar          => 'VARCHAR(255)',
  nvarchar         => 'VARCHAR(255)',
  char             => 'CHAR(1)',
  text             => 'TEXT',
  clob             => 'TEXT',
  date             => 'DATETIME',
  timestamp        => 'DATETIME',
  smalldatetime    => 'SMALLDATETIME',
  blob             => 'IMAGE',
  bytea            => 'IMAGE',
  numeric          => 'NUMERIC(18,6)',
  decimal          => 'NUMERIC(18,6)',
  float            => 'FLOAT',
  real             => 'FLOAT',
  'double precision' => 'DOUBLE PRECISION',
  boolean          => 'BIT',
);
is sybase_column_type($_), $type_map{$_}, "type: $_ -> $type_map{$_}"
  for sort keys %type_map;

is sybase_column_type('UNKNOWNTYPE'), 'UNKNOWNTYPE', 'unknown type passes through uppercased';
is sybase_column_type('weirdo'),      'WEIRDO',      'unknown lc type uppercased';
is sybase_column_type(undef),         'VARCHAR(255)', 'undef defaults to varchar';

# --- sybase_default_clause ----------------------------------------------
is sybase_default_clause(undef),        '',                  'no default -> empty clause';
is sybase_default_clause('null'),       '',                  "literal 'null' -> empty clause";
is sybase_default_clause('hello'),      " DEFAULT 'hello'",  'string default quoted';
is sybase_default_clause(0),            " DEFAULT '0'",      'zero default quoted (defined)';
is sybase_default_clause(\'getdate()'), ' DEFAULT getdate()', 'scalar ref emitted verbatim';

done_testing;
