use strict;
use warnings;
use Test::More;

# Pins the Informix type vocabulary: the coltype-number -> logical mapping
# (introspection side) and the logical -> Informix SQL type mapping (DDL
# side). These two ends must agree on logical type spelling. Centralized in
# DBIO::Informix::Types; the test guards behaviour through the original call
# sites so the refactor stays behaviour-preserving.

use DBIO::Informix::Introspect::Columns;
use DBIO::Informix::DDL;

# --- coltype number -> logical type (Introspect side) ---
# The numbers are the ones a real Informix 15.0.1 server reports in
# syscolumns.coltype (karr k20: INTEGER is 2, SMALLINT 1, DECIMAL 5, ...).
my %coltype = (
  0  => 'char',
  1  => 'smallint',
  2  => 'integer',
  3  => 'float',
  4  => 'smallfloat',
  5  => 'decimal',
  6  => 'serial',
  7  => 'date',
  8  => 'money',
  11 => 'bytea',
  12 => 'text',
  13 => 'varchar',
  14 => 'interval',
  15 => 'nchar',
  16 => 'nvarchar',
  17 => 'int8',
  18 => 'serial8',
  19 => 'set',
  20 => 'multiset',
  21 => 'list',
  40 => 'lvarchar',
  52 => 'bigint',
  53 => 'bigserial',
);

for my $num (sort { $a <=> $b } keys %coltype) {
  is(DBIO::Informix::Introspect::Columns::_map_type($num, undef), $coltype{$num},
    "coltype $num -> $coltype{$num}");
}
is(DBIO::Informix::Introspect::Columns::_map_type(99, undef), 'unknown',
  'unmapped coltype -> unknown');

# DATETIME carries its qualifiers in collength (len*256 + first*16 + last)
is(DBIO::Informix::Introspect::Columns::_map_type(10, 3594), 'datetime year to second', 'datetime year to second');
is(DBIO::Informix::Introspect::Columns::_map_type(10, 4365), 'datetime year to fraction(3)', 'datetime year to fraction(3)');
is(DBIO::Informix::Introspect::Columns::_map_type(10, 2052), 'datetime year to day', 'datetime year to day');
is(DBIO::Informix::Introspect::Columns::_map_type(10, 1128), 'datetime hour to minute', 'datetime hour to minute');

# fixed-length opaque types are told apart by syscolumns.extended_id
is(DBIO::Informix::Introspect::Columns::_map_type(41, 1, 5),  'boolean', 'opaque 5 -> boolean');
is(DBIO::Informix::Introspect::Columns::_map_type(41, 72, 10), 'blob',    'opaque 10 -> blob');
is(DBIO::Informix::Introspect::Columns::_map_type(41, 72, 11), 'clob',    'opaque 11 -> clob');
is(DBIO::Informix::Introspect::Columns::_map_type(41, 72, 99), 'unknown', 'unknown opaque');

# collength -> size (values measured on Informix 15.0.1)
use DBIO::Informix::Types ();
my @size = (
  [ 13, 1300, 20,        'varchar(20,5): the maximum of min*256+max' ],
  [ 13, 30,   30,        'varchar(30)' ],
  [ 16, 7,    7,         'nvarchar(7)' ],
  [ 0,  10,   10,        'char(10)' ],
  [ 15, 5,    5,         'nchar(5)' ],
  [ 40, 500,  500,       'lvarchar(500)' ],
  [ 5,  2562, [10, 2],   'decimal(10,2)' ],
  [ 5,  4351, [16],      'decimal(16): floating, scale 255' ],
  [ 8,  2050, [8, 2],    'money(8,2)' ],
  [ 2,  4,    undef,     'integer has no size' ],
);
for my $c (@size) {
  my ($type, $len, $want, $name) = @$c;
  is_deeply(DBIO::Informix::Types::size_for_coltype($type, $len), $want, "size: $name");
}

# --- logical type -> Informix SQL type (DDL side) ---
my @ddl = (
  [ { data_type => 'integer' },          'INTEGER' ],
  [ { data_type => 'bigint' },           'BIGINT' ],
  [ { data_type => 'smallint' },         'SMALLINT' ],
  [ { data_type => 'double precision' }, 'DOUBLE PRECISION' ],
  [ { data_type => 'real' },             'REAL' ],
  [ { data_type => 'date' },             'DATE' ],
  [ { data_type => 'text' },             'TEXT' ],
  [ { data_type => 'bytea' },            'BYTE' ],
  [ { data_type => 'varchar', size => 64 }, 'VARCHAR(64)' ],
  [ { data_type => 'varchar' },          'VARCHAR(255)' ],
  [ { data_type => 'nvarchar', size => 10 }, 'VARCHAR(10)' ],
  [ { data_type => 'char', size => 8 },  'CHAR(8)' ],
  [ { data_type => 'char' },             'CHAR(255)' ],
  [ { data_type => 'nchar', size => 4 }, 'CHAR(4)' ],
  [ { data_type => 'decimal', size => [10, 2] }, 'DECIMAL(10,2)' ],
  [ { data_type => 'numeric', size => [8, 4] },  'NUMERIC(8,4)' ],
  [ { data_type => 'decimal', size => [16] },    'DECIMAL(16)' ],
  [ { data_type => 'money', size => [8, 2] },    'MONEY(8,2)' ],
  [ { data_type => 'lvarchar', size => 100 },    'LVARCHAR(100)' ],
  [ {},                                  'VARCHAR(255)' ],   # undef data_type
  [ { data_type => 'serial' },           'serial' ],         # passthrough
  [ { data_type => 'mytype' },           'mytype' ],         # passthrough
);

for my $case (@ddl) {
  my ($info, $want) = @$case;
  is(DBIO::Informix::DDL::_informix_column_type($info), $want,
    "ddl type: " . ($info->{data_type} // '(undef)') .
    (defined $info->{size} ? "($info->{size})" : '') . " -> $want");
}

done_testing;
