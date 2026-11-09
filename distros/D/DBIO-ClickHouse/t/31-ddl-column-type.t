use strict;
use warnings;
use Test::More;

# t/31-ddl-column-type.t — DBIO::ClickHouse::DDL's _clickhouse_column_type, the
# sole column-type renderer behind install_ddl's CREATE TABLE generator. Pure
# function, no database, no server.
#
# The intent this locks down: a ClickHouse column type is a *composed* string,
# not a lookup. Nullability lives inside the type (columns are NOT NULL by
# default), LowCardinality nests outside it, and the composite types refuse
# both. Getting the nesting or the width wrong produces DDL the server rejects
# or — worse — silently accepts with the wrong range.

use DBIO::ClickHouse::DDL;

sub ch_type { DBIO::ClickHouse::DDL::_clickhouse_column_type($_[0]) }

# --- integers: width follows the source dialect, unsigned via extra ---------
my %int_map = (
  tinyint   => 'Int8',
  smallint  => 'Int16',
  mediumint => 'Int32',
  int       => 'Int32',
  integer   => 'Int32',
  bigint    => 'Int64',
  serial    => 'Int32',
  bigserial => 'Int64'
);
is ch_type({ data_type => $_ }), $int_map{$_}, "int: $_ -> $int_map{$_}"
  for sort keys %int_map;

is ch_type({ data_type => 'integer', extra => { unsigned => 1 } }), 'UInt32',
  'unsigned integer -> UInt32';
is ch_type({ data_type => 'bigint', extra => { unsigned => 1 } }), 'UInt64',
  'unsigned bigint -> UInt64';
is ch_type({ data_type => 'tinyint', extra => { unsigned => 1 } }), 'UInt8',
  'unsigned tinyint -> UInt8';
# unsigned only applies to the integer family; it must not corrupt other types
is ch_type({ data_type => 'varchar', extra => { unsigned => 1 } }), 'String',
  'unsigned is ignored for non-integer types';

# --- strings: the whole family collapses onto String, size dropped ----------
is ch_type({ data_type => $_, size => 255 }), 'String', "string: $_ -> String"
  for qw(varchar char character text clob tinytext mediumtext longtext ntext);
is ch_type({ data_type => $_ }), 'String', "binary: $_ -> String"
  for qw(blob bytea binary varbinary longblob);
is ch_type({ data_type => 'json' }), 'String',
  'json -> String (the native JSON type is not a portable target)';

# FixedString is opt-in and needs a size; never inferred from char(N).
is ch_type({ data_type => 'char', size => 2, extra => { fixed_string => 1 } }),
  'FixedString(2)', 'char + fixed_string extra -> FixedString(2)';
is ch_type({ data_type => 'char', size => 2 }), 'String',
  'char(2) alone stays String — FixedString is zero-byte padded, opt-in only';
is ch_type({ data_type => 'char', extra => { fixed_string => 1 } }), 'String',
  'fixed_string without a size cannot be rendered, falls back to String';

# --- decimals: precision/scale from size, never a bare Decimal -------------
is ch_type({ data_type => 'decimal', size => [10, 2] }), 'Decimal(10, 2)',
  'decimal + [p,s] -> Decimal(10, 2)';
is ch_type({ data_type => 'numeric', size => [5, 0] }), 'Decimal(5, 0)',
  'numeric + [p,s] -> Decimal(5, 0)';
is ch_type({ data_type => 'numeric', size => 8 }), 'Decimal(8, 0)',
  'bare precision -> scale 0';
is ch_type({ data_type => 'decimal' }), 'Decimal(38, 9)',
  'sizeless decimal falls back — ClickHouse has no bare Decimal';
is ch_type({ data_type => 'money' }), 'Decimal(19, 4)',
  'money keeps its fixed precision';

# --- floats ---------------------------------------------------------------
is ch_type({ data_type => 'real' }),             'Float32', 'real -> Float32';
is ch_type({ data_type => 'float' }),            'Float32', 'float -> Float32';
is ch_type({ data_type => 'double' }),           'Float64', 'double -> Float64';
is ch_type({ data_type => 'double precision' }), 'Float64', 'double precision -> Float64';

# --- temporal: range correctness over byte width --------------------------
is ch_type({ data_type => 'date' }), 'Date32',
  'date -> Date32 (Date starts at 1970 and cannot hold a birth date)';
is ch_type({ data_type => 'datetime' }), 'DateTime64(3)',
  'datetime -> DateTime64(3), millisecond precision';
is ch_type({ data_type => 'timestamp' }), 'DateTime64(3)',
  'timestamp -> DateTime64(3)';
is ch_type({ data_type => 'timestamptz' }), "DateTime64(3, 'UTC')",
  'timestamptz carries the zone inside the type';
is ch_type({ data_type => 'time' }), 'String',
  'time -> String (no non-experimental native Time type)';

# The narrow native types are reachable by spelling them the way ClickHouse
# spells them. Case is the whole signal: 'date' is the portable spelling and
# widens for range correctness, 'Date' is the native type name and is passed
# through as-is — otherwise a Date column could not be asked for at all and a
# live one would widen on every redeploy (karr k11).
is ch_type({ data_type => 'Date' }), 'Date',
  'native Date is passed through, not widened to Date32';
is ch_type({ data_type => 'DateTime' }), 'DateTime',
  'native DateTime is passed through, not widened to DateTime64(3)';
is ch_type({ data_type => 'Date', is_nullable => 1 }), 'Nullable(Date)',
  'a native name still composes with nullability';
is ch_type({ data_type => 'Date[]' }), 'Array(Date)',
  'and inside an array';

# --- misc -----------------------------------------------------------------
is ch_type({ data_type => 'boolean' }), 'Bool', 'boolean -> Bool';
is ch_type({ data_type => 'bool' }),    'Bool', 'bool -> Bool';
is ch_type({ data_type => $_ }), 'UUID', "uuid family: $_ -> UUID"
  for qw(uuid guid uniqueidentifier);

# --- enums: Enum8 up to 127 members, 1-based declaration order -------------
is ch_type({ data_type => 'enum', extra => { list => [qw(draft live)] } }),
  q{Enum8('draft' = 1, 'live' = 2)}, 'enum -> Enum8, numbered from 1';
is ch_type({ data_type => 'enum', extra => { list => ["it's"] } }),
  q{Enum8('it\\'s' = 1)}, 'enum member quote is escaped';
# 127 members still fit Int8's 1..127 numbering; 128 do not and widen to Enum16.
like ch_type({ data_type => 'enum', extra => { list => [map { "v$_" } 1 .. 127] } }),
  qr/\AEnum8\('v1' = 1, .*'v127' = 127\)\z/, '127 members still fit Enum8';
like ch_type({ data_type => 'enum', extra => { list => [map { "v$_" } 1 .. 128] } }),
  qr/\AEnum16\('v1' = 1, .*'v128' = 128\)\z/, '128 members widen to Enum16';
is ch_type({ data_type => 'enum' }), 'String',
  'enum without a member list degrades to String, not an unrenderable "enum"';

# --- arrays ---------------------------------------------------------------
is ch_type({ data_type => 'text[]' }),    'Array(String)', 'text[] -> Array(String)';
is ch_type({ data_type => 'integer[]' }), 'Array(Int32)',  'integer[] -> Array(Int32)';

# --- Nullable(T): from is_nullable, part of the type ----------------------
is ch_type({ data_type => 'varchar', is_nullable => 1 }), 'Nullable(String)',
  'is_nullable wraps in Nullable';
is ch_type({ data_type => 'varchar', is_nullable => 0 }), 'String',
  'not nullable stays bare — ClickHouse columns are NOT NULL by default';
is ch_type({ data_type => 'varchar' }), 'String',
  'absent is_nullable is not nullable';
is ch_type({ data_type => 'integer', is_nullable => 1 }), 'Nullable(Int32)',
  'Nullable wraps the mapped type, not the source type';
is ch_type({ data_type => 'text[]', is_nullable => 1 }), 'Array(String)',
  'composite types are never wrapped — Nullable(Array(T)) is rejected by the server';

# --- LowCardinality(T): opt-in, nests outside Nullable --------------------
is ch_type({ data_type => 'varchar', extra => { low_cardinality => 1 } }),
  'LowCardinality(String)', 'low_cardinality extra wraps the type';
is ch_type({ data_type => 'varchar', is_nullable => 1, extra => { low_cardinality => 1 } }),
  'LowCardinality(Nullable(String))', 'LowCardinality nests outside Nullable';
is ch_type({ data_type => 'varchar' }), 'String',
  'low_cardinality is never inferred';

# --- escape hatches -------------------------------------------------------
is ch_type({ data_type => 'DateTime64(6)', size => 999 }), 'DateTime64(6)',
  'pre-parameterized data_type passes through, size ignored';
is ch_type({ data_type => 'DateTime64(6)', is_nullable => 1 }), 'Nullable(DateTime64(6))',
  'a hand-written native type still composes with nullability';
is ch_type({ data_type => 'Nullable(String)', is_nullable => 1 }), 'Nullable(String)',
  'an already-Nullable type is not double-wrapped';
is ch_type({ data_type => 'IPv6' }), 'IPv6',
  'unknown type passes through verbatim (native ClickHouse type names)';
is ch_type({}), 'String', 'missing data_type defaults to String';

# --- native spelling wins over the portable map ---------------------------
# A data_type spelled exactly as ClickHouse spells the type counts as native
# and is never translated. Most native names need no help — they are absent
# from the portable map and pass through like IPv6 above. These seven collide
# with a portable key, so they are the whole surface of the rule and are
# checked, not assumed. Both halves of each collision are asserted together:
# the native spelling must survive AND the portable one must keep mapping.
for my $case (
  # native      renders to      portable    renders to
  [ 'String',   'String',       'string',   'String'        ],
  [ 'Bool',     'Bool',         'bool',     'Bool'          ],
  [ 'UUID',     'UUID',         'uuid',     'UUID'          ],
  [ 'Date',     'Date',         'date',     'Date32'        ],
  [ 'DateTime', 'DateTime',     'datetime', 'DateTime64(3)' ],
  [ 'Time',     'Time',         'time',     'String'        ],
  [ 'JSON',     'JSON',         'json',     'String'        ]
) {
  my ($native, $native_out, $portable, $portable_out) = @$case;
  is ch_type({ data_type => $native }), $native_out,
    "native spelling $native -> $native_out";
  is ch_type({ data_type => $portable }), $portable_out,
    "portable spelling $portable -> $portable_out";
}

# Case is the entire signal, so an all-caps SQL-style spelling is NOT the
# native ClickHouse one and still goes through the portable map. Anything else
# would make a schema written in SQL caps pick up native types by accident.
is ch_type({ data_type => 'DATE' }), 'Date32',
  'SQL-caps DATE is not the native spelling and still widens';
is ch_type({ data_type => 'DATETIME' }), 'DateTime64(3)', 'nor is DATETIME';
is ch_type({ data_type => 'VARCHAR' }), 'String', 'nor is VARCHAR';

# Bare Decimal and bare Enum are deliberately NOT native names: ClickHouse
# rejects both without parameters, so passing them through would emit DDL the
# server cannot parse.
is ch_type({ data_type => 'Decimal', size => [10, 2] }), 'Decimal(10, 2)',
  'Decimal is not treated as native — ClickHouse has no parameterless Decimal';
is ch_type({ data_type => 'Enum', extra => { list => [qw(draft live)] } }),
  q{Enum8('draft' = 1, 'live' = 2)},
  'Enum is not treated as native either — it needs its members';

# The native name is resolved before the extra flags that select a type, so a
# contradictory String + fixed_string is String. FixedString(N) is asked for
# through the portable char spelling, or written out in full.
is ch_type({ data_type => 'String', size => 3, extra => { fixed_string => 1 } }),
  'String', 'the native name wins over the fixed_string extra';

done_testing;
