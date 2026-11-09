use strict;
use warnings;

use Test::More;

use DBIO::DB2::Introspect::Columns;
use DBIO::DB2::Type qw(_db2_column_type);

# OFFLINE (karr k41). What DBIO::DB2::Introspect::Columns makes of a
# SYSCAT.COLUMNS row -- the shape both sides of every real diff have, and the
# one the diff op classes render DDL from.
#
# The rows are replayed from a handle that never connects, but they are not
# invented: TYPENAME, LENGTH, SCALE, DEFAULT and IDENTITY are what Db2 12.1.5
# held for the declaration named beside each row.
#
# The point of the file is `size`. For every type but one it is LENGTH (with
# SCALE after a comma when above zero), which is the storage length for a type
# declared without one. TIMESTAMP is the one: LENGTH is 7 to 13 and says
# nothing a declaration takes, SCALE is the fractional-seconds precision that
# TIMESTAMP(p) does take. Carried as "10,6", it made the diff write
# TIMESTAMP(10,6), which the server refuses (SQL0104N); the bare 7 of a
# TIMESTAMP(0) was accepted and silently created a TIMESTAMP(7).

{
  package Mock::DB2;
  sub new { bless { columns => $_[1], pk => $_[2] }, $_[0] }
  sub prepare {
    my ($self, $sql) = @_;
    my $rows = $sql =~ /FROM syscat\.columns/ ? $self->{columns} : $self->{pk};
    return bless { rows => $rows }, 'Mock::DB2::STH';
  }

  package Mock::DB2::STH;
  sub execute { my $self = shift; $self->{i} = 0; return 1 }
  sub fetchrow_hashref { my $self = shift; return $self->{rows}[ $self->{i}++ ] }
}

my @ROWS = (
  # colname,  typename,   length, scale, default,           identity, nulls   declared as
  [ 'id',      'INTEGER',        4,  0, undef,               'Y', 'N' ],  # INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY
  [ 'name',    'VARCHAR',      100,  0, undef,               'N', 'N' ],  # VARCHAR(100) NOT NULL
  [ 'status',  'VARCHAR',       20,  0, q{'new'},            'N', 'N' ],  # VARCHAR(20) NOT NULL DEFAULT 'new'
  [ 'nick',    'VARCHAR',       40,  0, q{'it''s'},          'N', 'Y' ],  # VARCHAR(40) DEFAULT 'it''s'
  [ 'rating',  'INTEGER',        4,  0, q{0},                'N', 'Y' ],  # INTEGER DEFAULT 0
  [ 'score',   'DECIMAL',       10,  2, undef,               'N', 'Y' ],  # DECIMAL(10,2)
  [ 'code',    'CHARACTER',      3,  0, undef,               'N', 'Y' ],  # CHAR(3)
  [ 'bio',     'CLOB',     1048576,  0, undef,               'N', 'Y' ],  # CLOB
  [ 'born',    'DATE',           4,  0, undef,               'N', 'Y' ],  # DATE
  [ 'created', 'TIMESTAMP',     10,  6, q{CURRENT TIMESTAMP}, 'N', 'Y' ], # TIMESTAMP DEFAULT CURRENT TIMESTAMP
  [ 'ts0',     'TIMESTAMP',      7,  0, undef,               'N', 'Y' ],  # TIMESTAMP(0)
  [ 'ts3',     'TIMESTAMP',      9,  3, undef,               'N', 'Y' ],  # TIMESTAMP(3)
  [ 'ts12',    'TIMESTAMP',     13, 12, undef,               'N', 'Y' ],  # TIMESTAMP(12)
  [ 'df16',    'DECFLOAT',       8,  0, undef,               'N', 'Y' ],  # DECFLOAT(16)
  [ 'df34',    'DECFLOAT',      16,  0, undef,               'N', 'Y' ],  # DECFLOAT(34), also a bare DECFLOAT
  [ 'small',   'SMALLINT',       2,  0, undef,               'N', 'Y' ],  # SMALLINT
  [ 'big',     'BIGINT',         8,  0, undef,               'N', 'Y' ],  # BIGINT
  [ 'dbl',     'DOUBLE',         8,  0, undef,               'N', 'Y' ],  # DOUBLE, FLOAT, DOUBLE PRECISION
  [ 'rl',      'REAL',           4,  0, undef,               'N', 'Y' ],  # REAL
  [ 'tm',      'TIME',           3,  0, undef,               'N', 'Y' ],  # TIME
  [ 'vb',      'VARBINARY',     16,  0, undef,               'N', 'Y' ],  # VARBINARY(16)
  [ 'bl',      'BLOB',     1048576,  0, undef,               'N', 'Y' ],  # BLOB
  [ 'flag',    'BOOLEAN',        1,  0, undef,               'N', 'Y' ],  # BOOLEAN (karr k54)
  [ 'flag_d',  'BOOLEAN',        1,  0, q{TRUE},             'N', 'Y' ],  # BOOLEAN DEFAULT TRUE
  [ 'bn',      'BINARY',         8,  0, undef,               'N', 'Y' ],  # BINARY(8)
  [ 'who',     'VARCHAR',       30,  0, q{USER},             'N', 'Y' ],  # VARCHAR(30) DEFAULT USER
  [ 'zip',     'CHARACTER',      5,  0, q{'00000'},          'N', 'Y' ],  # CHAR(5) DEFAULT '00000'
  [ 'nul',     'INTEGER',        4,  0, q{NULL},             'N', 'Y' ],  # INTEGER DEFAULT NULL
  [ 'money',   'DECIMAL',       12,  2, q{0.00},             'N', 'Y' ],  # DECIMAL(12,2) DEFAULT 0.00
);

my $colno = 0;
my $dbh = Mock::DB2->new(
  [ map { {
      tabname => 'author', colname => $_->[0], colno => $colno++,
      typename => $_->[1], length => $_->[2], scale => $_->[3],
      default => $_->[4], identity => $_->[5], nulls => $_->[6],
  } } @ROWS ],
  [ { tabname => 'author', colname => 'id', colseq => 1 } ],
);

my $columns = DBIO::DB2::Introspect::Columns->fetch(
  $dbh, 'DB2INST1', { author => { table_name => 'author', kind => 'table' } },
);
my %col = map { $_->{column_name} => $_ } @{ $columns->{author} };

is_deeply [ map { $_->{column_name} } @{ $columns->{author} } ], [ map { $_->[0] } @ROWS ],
  'the columns of the table, in COLNO order';

# --- size ---------------------------------------------------------------------

is $col{created}{catalog_size}, 6,  'TIMESTAMP: size is the precision (SCALE 6), not LENGTH and SCALE';
is $col{ts0}{catalog_size},     0,  'TIMESTAMP(0): size is 0, not the LENGTH 7';
is $col{ts3}{catalog_size},     3,  'TIMESTAMP(3): size is 3';
is $col{ts12}{catalog_size},    12, 'TIMESTAMP(12): size is 12';

is $col{score}{catalog_size}, '10,2', 'DECIMAL(10,2): size is LENGTH and SCALE';
is $col{name}{catalog_size},  100,    'VARCHAR(100): size is LENGTH';
is $col{code}{catalog_size},  3,      'CHAR(3): size is LENGTH';
is $col{id}{catalog_size},    4,      'INTEGER: size is the storage length the catalog holds';
is $col{born}{catalog_size},  4,      'DATE: likewise';
is $col{bio}{catalog_size},   1048576, 'CLOB: the length it got without one being declared';

# DECFLOAT (karr k45): LENGTH is the storage length, 8 or 16 bytes; the
# declaration takes the digits. Rendered from LENGTH, the diff wrote
# DECFLOAT(16) for a DECFLOAT(34) and DECFLOAT(8) for a DECFLOAT(16).
is $col{df16}{catalog_size}, 16, 'DECFLOAT(16): LENGTH 8 is carried as size 16';
is $col{df34}{catalog_size}, 34, 'DECFLOAT(34): LENGTH 16 is carried as size 34';

# --- the rest of the shape the diff reads --------------------------------------

is $col{code}{catalog_type}, 'CHARACTER', 'data_type is TYPENAME: CHARACTER for a CHAR column';

is $col{status}{catalog_default}, q{'new'},
  'default_value is DEFAULT, the SQL text: a string literal keeps its quotes';
is $col{nick}{catalog_default}, q{'it''s'},
  '... and its doubled apostrophe';
is $col{rating}{catalog_default}, '0', '... a number is bare';
is $col{created}{catalog_default}, 'CURRENT TIMESTAMP', '... and so is a special register';
is $col{name}{catalog_default}, undef, 'no default is undef';

is $col{id}{is_auto_increment}, 1, 'an identity column carries is_auto_increment';
ok !exists $col{name}{is_auto_increment}, '... and no other column has the key';

is_deeply [ @{ $col{id} }{qw(is_pk pk_position not_null)} ], [ 1, 1, 1 ],
  'the primary key column is marked, and NULLS N is not_null';
is_deeply [ @{ $col{nick} }{qw(is_pk pk_position not_null)} ], [ 0, 0, 0 ],
  '... a nullable column outside the key is not';

# --- the normalized model (karr k44, ADR 0013) -------------------------------
# data_type, size and default_value are what DBIO::Introspect::Base hands
# DBIO::Generate through table_columns_info: the values a result class
# declares. The catalog fields above are the diff's, and stay what they were.

is_deeply { map { $_ => $col{$_}{data_type} } keys %col }, {
  id => 'integer', name => 'varchar', status => 'varchar', nick => 'varchar',
  rating => 'integer', score => 'decimal', code => 'char', bio => 'clob',
  born => 'date', created => 'timestamp', ts0 => 'timestamp', ts3 => 'timestamp',
  ts12 => 'timestamp', df16 => 'decfloat', df34 => 'decfloat',
  small => 'smallint', big => 'bigint', dbl => 'double precision', rl => 'real',
  tm => 'time', vb => 'varbinary', bl => 'blob', flag => 'boolean', flag_d => 'boolean', bn => 'binary', who => 'varchar', zip => 'char',
  nul => 'integer', money => 'decimal',
}, 'data_type: TYPENAME lower-cased; CHARACTER is char, DOUBLE is double precision';

is $col{name}{size},  100, 'VARCHAR(100): size 100';
is $col{code}{size},  3,   'CHAR(3): size 3 (the data_type is char, not CHARACTER)';
is $col{vb}{size},    16,  'VARBINARY(16): size 16';
is $col{bn}{size},    8,   'BINARY(8): size 8';
is_deeply [ $col{flag}{catalog_type}, $col{flag}{catalog_size} ], [ 'BOOLEAN', 1 ], 'BOOLEAN: catalog_type BOOLEAN, catalog_size 1';
is_deeply $col{flag_d}{default_value}, \'TRUE', 'BOOLEAN DEFAULT TRUE: the default is an expression, a SCALAR reference';
is _db2_column_type($col{flag}{data_type}, $col{flag}{size}), 'BOOLEAN', 'boolean renders BOOLEAN';
is _db2_column_type($col{bn}{data_type}, $col{bn}{size}), 'BINARY(8)', 'binary 8 renders BINARY(8)';
is $col{bio}{size},   1048576, 'CLOB: the declared (default) length';
is_deeply $col{score}{size}, [ 10, 2 ], 'DECIMAL(10,2): size is [10, 2]';
is_deeply $col{money}{size}, [ 12, 2 ], 'DECIMAL(12,2): size is [12, 2]';
is $col{created}{size}, 6,  'TIMESTAMP: size is the precision';
is $col{ts0}{size},     0,  'TIMESTAMP(0): size 0';
is $col{ts12}{size},    12, 'TIMESTAMP(12): size 12';
is $col{df16}{size},    16, 'DECFLOAT(16): size 16';
is $col{df34}{size},    34, 'DECFLOAT(34): size 34';

for my $name (qw(id small big dbl rl born tm flag flag_d)) {
  ok !exists $col{$name}{size},
    "$name: Db2 declares $col{$name}{catalog_type} without a length, so there is no size";
}

# What the generated result class declares installs as what it was: the
# normalized type and size render to the catalog's own declaration.
is _db2_column_type($col{name}{data_type},  $col{name}{size}),  'VARCHAR(100)',   'varchar 100 renders VARCHAR(100)';
is _db2_column_type($col{code}{data_type},  $col{code}{size}),  'CHAR(3)',        'char 3 renders CHAR(3)';
is _db2_column_type($col{score}{data_type}, $col{score}{size}), 'DECIMAL(10,2)',  'decimal [10,2] renders DECIMAL(10,2)';
is _db2_column_type($col{dbl}{data_type},   $col{dbl}{size}),   'DOUBLE PRECISION', 'double precision renders itself';
is _db2_column_type($col{df34}{data_type},  $col{df34}{size}),  'DECFLOAT(34)',   'decfloat 34 renders DECFLOAT(34)';
is _db2_column_type($col{ts3}{data_type},   $col{ts3}{size}),   'TIMESTAMP(3)',   'timestamp 3 renders TIMESTAMP(3)';

is $col{status}{default_value}, 'new',  "default_value: a string literal is the string, 'new' is new";
is $col{nick}{default_value},   q{it's}, q{... and 'it''s' is it's};
is $col{zip}{default_value},    '00000', q{... a character default keeps its zeros: '00000'};
is $col{rating}{default_value}, '0',    '... a number is its text';
is $col{money}{default_value},  '0.00', '... a decimal too';
is_deeply $col{created}{default_value}, \'CURRENT TIMESTAMP',
  '... a special register is a SCALAR reference';
is_deeply $col{who}{default_value}, \'USER', '... USER too (not the string USER)';
is $col{nul}{default_value}, undef, 'DEFAULT NULL is undef';
is $col{name}{default_value}, undef, 'no default is undef';

# --- BOOLEAN defaults (karr k55) ---------------------------------------------------
# Measured on Db2 12.1.5: SYSCAT.COLUMNS.DEFAULT of a BOOLEAN holds the text as it
# was written -- DEFAULT '1' reads '1' (quotes kept), 1 reads 1, TRUE reads TRUE,
# 'true' reads 'true'. install_ddl writes a class value '1' bare (DEFAULT 1, the
# digit rule of _db2_default_literal), so a column made by hand with DEFAULT '1'
# and the same column made from the class (the compare schema of every diff, and
# what DBIO::Generate writes from the live model) differed in catalog_default
# ('1' against 1) and the diff set a default that was the default already. For a
# BOOLEAN the catalog text of a quoted number is read as the number, the form
# install_ddl writes; the other texts stay (they are written back as they are).
{
  my @B = (
    # colname, default,   declared as
    [ 'q1',  q{'1'},     ],    # BOOLEAN DEFAULT '1'
    [ 'q0',  q{'0'},     ],    # BOOLEAN DEFAULT '0'
    [ 'n1',  q{1},       ],    # BOOLEAN DEFAULT 1
    [ 'tt',  q{TRUE},    ],    # BOOLEAN DEFAULT TRUE
    [ 'ff',  q{FALSE},   ],    # BOOLEAN DEFAULT FALSE
    [ 'st',  q{'true'},  ],    # BOOLEAN DEFAULT 'true'
    [ 'sh',  q{'t'},     ],    # BOOLEAN DEFAULT 't'
  );
  my $no = 0;
  my $bdbh = Mock::DB2->new(
    [ (map { {
        tabname => 'flags', colname => $_->[0], colno => $no++, typename => 'BOOLEAN',
        length => 1, scale => 0, default => $_->[1], identity => 'N', nulls => 'N',
    } } @B),
      { tabname => 'flags', colname => 'vc', colno => $no++, typename => 'VARCHAR',
        length => 5, scale => 0, default => q{'1'}, identity => 'N', nulls => 'N' },
    ],
    [],
  );
  my $bc = DBIO::DB2::Introspect::Columns->fetch(
    $bdbh, 'DB2INST1', { flags => { table_name => 'flags', kind => 'table' } });
  my %b = map { $_->{column_name} => $_ } @{ $bc->{flags} };

  is $b{q1}{catalog_default}, '1', q{BOOLEAN DEFAULT '1': catalog_default is 1, the form install_ddl writes};
  is $b{q0}{catalog_default}, '0', q{... '0' is 0};
  is $b{q1}{default_value},   '1', '... and default_value is 1 (unchanged)';
  is $b{n1}{catalog_default}, '1', '... DEFAULT 1 is 1';
  is $b{q1}{catalog_default}, $b{n1}{catalog_default}, q{... so '1' and 1 compare equal in the diff};
  is $b{tt}{catalog_default}, 'TRUE',    '... TRUE stays TRUE';
  is $b{ff}{catalog_default}, 'FALSE',   '... FALSE stays FALSE';
  is $b{st}{catalog_default}, q{'true'}, q{... 'true' stays 'true' (install_ddl writes a class value true quoted)};
  is $b{sh}{catalog_default}, q{'t'},    q{... 't' stays 't'};
  is $b{vc}{catalog_default}, q{'1'},    q{a VARCHAR DEFAULT '1' keeps its quotes: only BOOLEAN is read this way};
}

done_testing;
