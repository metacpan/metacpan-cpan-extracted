use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::DB2::DDL;
use DBIO::DB2::Type qw(_db2_column_type);

# OFFLINE (karr k40). A column's size is a scalar or an array reference. The
# array reference is the core form for a type with more than one parameter:
# DBIO::Cake's numeric(10,2) declares size => [10, 2]. _db2_column_type
# interpolated whatever it was given, so that column deployed as
#
#   "price" DECIMAL(ARRAY(0x55d0c8a3f1b8))
#
# and the install died on the server (SQL0103N, an invalid numeric literal).
# The parts are joined with a comma instead, which is also the one string
# DBIO::DB2::Introspect::Columns gives back for such a column ("10,2") -- so
# both sides of a diff render the same type.

my @SIZE = (
  # data_type, size, rendered
  [ 'decimal', [ 10, 2 ], 'DECIMAL(10,2)', 'precision and scale as an array reference' ],
  [ 'numeric', [ 10, 2 ], 'DECIMAL(10,2)', '... for numeric, mapped to DECIMAL, too' ],
  [ 'decimal', [ 10 ],    'DECIMAL(10)',   'an array reference of one part' ],
  [ 'decimal', [],        'DECIMAL',       'an empty array reference is no size at all' ],
  [ 'decimal', '10,2',    'DECIMAL(10,2)', 'the same size as a string stays what it was' ],
  [ 'varchar', 64,        'VARCHAR(64)',   'a plain number stays what it was' ],
  [ 'integer', undef,     'INTEGER',       'no size stays no size' ],
);

for my $case (@SIZE) {
  my ($data_type, $size, $rendered, $name) = @$case;

  # Both calling forms: the column_info hash DBIO::DB2::DDL passes, and the
  # (type, size) pair of the diff op classes.
  is _db2_column_type({ data_type => $data_type, size => $size }), $rendered,
    "$name: $rendered (column_info form)";

  is _db2_column_type($data_type, $size), $rendered,
    "$name: $rendered (type, size form)";
}

# OFFLINE (karr k41). A size is not always a length the type takes. The diff
# op classes get their columns from DBIO::DB2::Introspect::Columns, where
# data_type is SYSCAT.COLUMNS.TYPENAME and size is LENGTH -- for a type
# declared without one, its storage length. Written back as given, that was
#
#   "id" INTEGER(4)
#
# and no table with an integer column could be created by an upgrade
# (SQL0104N). Every (data_type, size) pair below is what Db2 12.1.5 gave back
# for a column install_ddl can declare, and every rendering was accepted by
# that server and gave the same catalog type again.

my @CATALOG = (
  # data_type, size, rendered
  [ 'SMALLINT',     2, 'SMALLINT',         'a type without a length gets none' ],
  [ 'INTEGER',      4, 'INTEGER',          '...' ],
  [ 'BIGINT',       8, 'BIGINT',           '...' ],
  [ 'REAL',         4, 'REAL',             '...' ],
  [ 'DOUBLE',       8, 'DOUBLE PRECISION', '... nor does the catalog name of FLOAT and DOUBLE PRECISION' ],
  [ 'DATE',         4, 'DATE',             '...' ],
  [ 'TIME',         3, 'TIME',             '...' ],
  [ 'XML',          0, 'XML',              '... a length of 0 included' ],
  [ 'DECIMAL', '10,2', 'DECIMAL(10,2)',    'precision and scale stay' ],
  [ 'DECIMAL',      5, 'DECIMAL(5)',       '... as does a precision alone' ],
  [ 'VARCHAR',    100, 'VARCHAR(100)',     'a length the type takes stays' ],
  [ 'CHARACTER',    3, 'CHARACTER(3)',     '... under the catalog name of CHAR, too' ],
  [ 'VARBINARY',   16, 'VARBINARY(16)',    '...' ],
  [ 'CLOB',  1048576, 'CLOB(1048576)',     '... and the length of a CLOB declared without one' ],
  [ 'BLOB',  1048576, 'BLOB(1048576)',     '...' ],
  # DBIO::DB2::Introspect::Columns gives a TIMESTAMP its precision as size
  # (SCALE), not LENGTH: t/45-introspect-columns.t.
  [ 'TIMESTAMP',    6, 'TIMESTAMP(6)',     'the precision of a TIMESTAMP stays' ],
  [ 'TIMESTAMP',    0, 'TIMESTAMP(0)',     '... a precision of 0 included' ],
);

for my $case (@CATALOG) {
  my ($data_type, $size, $rendered, $name) = @$case;

  is _db2_column_type($data_type, $size), $rendered,
    "catalog $data_type with size $size: $rendered ($name)";
}

# The same on the install side, where the size comes from a result class
# written with another engine in mind.

is _db2_column_type({ data_type => 'integer', size => 11 }), 'INTEGER',
  'a result class integer with a display width deploys as INTEGER';

# karr k54 (ADR 0004 addendum). Db2 11.1 and later have BOOLEAN, BINARY(n) and
# VARBINARY(n) natively; boolean used to be written as SMALLINT and binary as BLOB,
# and a BOOLEAN or BINARY column came back from the catalog as another type than
# the class declared. Measured on 12.1.5: BOOLEAN takes no length (BOOLEAN(1) is
# SQL0104N; the catalog's LENGTH 1 is left out), BINARY is valid bare (= BINARY(1))
# and with a length, VARBINARY needs one (SQL0604N).
is _db2_column_type({ data_type => 'boolean', size => 1 }), 'BOOLEAN',
  '... and a boolean with a size as the BOOLEAN it maps to (no length)';
is _db2_column_type('boolean'), 'BOOLEAN', 'boolean: BOOLEAN, not SMALLINT';
is _db2_column_type('bool'),    'BOOLEAN', 'bool: BOOLEAN';
is _db2_column_type('BOOLEAN', 1), 'BOOLEAN', 'catalog BOOLEAN with its LENGTH 1: no length';
is _db2_column_type('binary', 8),  'BINARY(8)', 'binary with a size: BINARY(8), not BLOB';
is _db2_column_type('binary'),     'BINARY',    'binary without a size: valid bare, valid bare, as CHAR is';
is _db2_column_type('BINARY', 8),  'BINARY(8)', 'catalog BINARY keeps its length';
is _db2_column_type('varbinary', 16), 'VARBINARY(16)', 'varbinary stays VARBINARY';
throws_ok { _db2_column_type('varbinary') } qr/varbinary.*needs a size/i, '... and still needs a size';

# karr k55. The limits, measured on Db2 12.1.5: BINARY(n) takes n <= 255, VARBINARY(n)
# n <= 32672; above, SQL0604N. A binary of more than 255 bytes is what VARBINARY is
# for, so it is written as one (the catalog then reads VARBINARY, which is what
# DBIO::Generate writes back: a stable round trip, t/80); beyond the VARBINARY limit
# there is no type to map to and the column is refused, naming type, column, size and
# the limit, rather than left to the server.
is _db2_column_type('binary', 255),   'BINARY(255)',     'binary at the BINARY limit stays BINARY(255)';
is _db2_column_type('binary', 256),   'VARBINARY(256)',  'binary above it is VARBINARY(n)';
is _db2_column_type('binary', 300),   'VARBINARY(300)',  '... 300';
is _db2_column_type({ data_type => 'binary', size => 32672 }), 'VARBINARY(32672)',
  '... up to the VARBINARY limit, in the column_info form as well';
is _db2_column_type('varbinary', 32672), 'VARBINARY(32672)', 'varbinary at its limit stays';
is _db2_column_type('varbinary', 300),   'VARBINARY(300)',   'varbinary of 300 stays (it was never BINARY)';
is _db2_column_type('BINARY', 8),        'BINARY(8)',        'the catalog BINARY(8) is not touched';
is _db2_column_type('VARBINARY', 32672), 'VARBINARY(32672)', 'the catalog VARBINARY at the limit is not touched';
is _db2_column_type('blob', 1048576),    'BLOB(1048576)',    'blob has no such limit here';
for my $t (qw(binary varbinary)) {
  throws_ok { _db2_column_type($t, 32673, 'T.c') } qr/\Q$t\E.*column T\.c.*32673.*32672/s,
    "$t of 32673 is refused, naming type, column, size and the limit";
  throws_ok { _db2_column_type({ data_type => $t, size => 100000 }) } qr/100000.*32672/s,
    "... in the column_info form, too";
}
throws_ok { _db2_column_type('binary', 40000, 'T.c') } qr/blob/i, '... and points to blob';

# ... and where the array reference bit: the DDL of a schema that declares the column this way.

{
  package T::K40::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('k40_item');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    price => { data_type => 'numeric', size => [ 10, 2 ], is_nullable => 1 },
    label => { data_type => 'varchar', size => 64, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K40::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Item => 'T::K40::Result::Item');
}

my $ddl = DBIO::DB2::DDL->install_ddl('T::K40::Schema');

like $ddl, qr/^\s*"price" DECIMAL\(10,2\),$/m,
  'install_ddl renders size => [10, 2] as DECIMAL(10,2)';

unlike $ddl, qr/ARRAY\(0x/,
  '... and no array reference is left in the DDL as the address it has';

like $ddl, qr/^\s*"label" VARCHAR\(64\),$/m,
  '... beside a column with a scalar size, rendered as before';

# karr k45. text, varchar, json and varbinary without a size, and interval, are
# refused where the type is rendered -- Db2 answers SQL0604N / SQL0204N, and a
# guessed length would be a decision about the data. With a size nothing changes.

for my $t (qw(varchar json varbinary)) {
  throws_ok { _db2_column_type($t, undef, 'T.c') } qr/\Q$t\E.*column T\.c.*needs a size.*SQL0604N/s,
    "$t without a size is refused, naming type and column";
  throws_ok { _db2_column_type({ data_type => $t }) } qr/needs a size/,
    "... in the column_info form, too";
  throws_ok { _db2_column_type($t, '') } qr/needs a size/, "... and with an empty size";
}
throws_ok { _db2_column_type('interval', undef, 'T.c') } qr/no interval type.*column T\.c/,
  'interval is refused';
throws_ok { _db2_column_type('interval', 6) } qr/no interval type/,
  '... with a size as well';

# karr k57 (conformance, core ADR 0060). Db2 has no ENUM and no BIT type
# (SQL0204N / SQL0104N): the type is refused where it is rendered, as a
# DBIO::Exception whose text says "refus" and names type and column -- the
# refusal convention of DBIO::Test::Conformance -- and not left to the server.
for my $t (qw(enum bit)) {
  throws_ok { _db2_column_type($t, undef, 'T.c') } qr/no \Q$t\E type.*column T\.c.*refus/s,
    "$t is refused, naming type and column";
  my $err = $@;
  isa_ok $err, 'DBIO::Exception', "... the refusal of $t";
  throws_ok { _db2_column_type($t, 8) } qr/no \Q$t\E type/, "... with a size as well";
}
for my $t (qw(varchar json)) {
  eval { _db2_column_type($t, undef, 'T.c') };
  isa_ok $@, 'DBIO::Exception', "the refusal of $t without a size";
}

# karr k57 (maintainer decision): text without a size is a CLOB -- the type
# that holds a string of any length -- not a refusal. Nothing is guessed: the
# CLOB is what the declaration says (text, no bound), and VARCHAR(n) stays for
# a text with a size. varchar and json without a size are still refused.
is _db2_column_type('text'),                  'CLOB',         'text without a size is a CLOB';
is _db2_column_type({ data_type => 'text' }), 'CLOB',         '... in the column_info form, too';
is _db2_column_type('text', ''),              'CLOB',         '... and with an empty size';
is _db2_column_type('text', 100),             'VARCHAR(100)', 'text with a size is VARCHAR(n)';

is _db2_column_type('text', 100),      'VARCHAR(100)',   'text with a size stays VARCHAR(n)';
is _db2_column_type('json', 4000),     'VARCHAR(4000)',  'json with a size stays VARCHAR(n)';
is _db2_column_type('varbinary', 16),  'VARBINARY(16)',  'varbinary with a size stays';
is _db2_column_type('char'),           'CHAR',           'char without a size is CHAR(1): valid, unchanged';
is _db2_column_type('blob'),           'BLOB',           'blob without a size: valid, unchanged';
is _db2_column_type('clob'),           'CLOB',           'clob without a size: valid, unchanged';

# DECFLOAT (karr k45). The size is 16 or 34 (the digits); the catalog's LENGTH
# 8 / 16 is converted in DBIO::DB2::Introspect::Columns (t/45).
is _db2_column_type('decfloat', 16), 'DECFLOAT(16)', 'decfloat with size 16';
is _db2_column_type('decfloat', 34), 'DECFLOAT(34)', 'decfloat with size 34';
is _db2_column_type('decfloat'),     'DECFLOAT',     'decfloat without a size is DECFLOAT (Db2 default 34)';
is _db2_column_type('DECFLOAT', 34), 'DECFLOAT(34)', 'the catalog name, too';

# The character-type test of the default logic classifies without rendering,
# so it must not trip over the refusal.
for my $t (qw(text varchar json)) {
  lives_and { is DBIO::DB2::DDL::_db2_is_character_type($t), 1 }
    "_db2_is_character_type($t) answers without a size";
}
lives_and { is DBIO::DB2::DDL::_db2_default_literal('00000', 'varchar'), "'00000'" }
  'a default on a size-less varchar is still quoted (k46)';

# install_ddl: the refusal names table and column.
{
  package T::K45::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('k45_item');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    note => { data_type => 'varchar', is_nullable => 1 },
    body => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package T::K45::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Item => 'T::K45::Result::Item');
}
throws_ok { DBIO::DB2::DDL->install_ddl('T::K45::Schema') }
  qr/k45_item\.note.*needs a size/s, 'install_ddl refuses a varchar column without a size, naming table.column';
T::K45::Result::Item->add_columns(note => { data_type => 'varchar', size => 40, is_nullable => 1 });
T::K45::Schema->register_class(Item => 'T::K45::Result::Item');
like(DBIO::DB2::DDL->install_ddl('T::K45::Schema'), qr/^\s*"body" CLOB,$/m,
  'install_ddl writes a text column without a size as CLOB (karr k57)');

done_testing;
