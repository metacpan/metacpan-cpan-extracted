use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;
use DBIO::SQL::Util ();
use DBIO::Oracle::DDL;
use DBIO::Oracle::Type;
use DBIO::Oracle::Diff::Column;
use DBIO::Oracle::Diff::Table;
use DBIO::Oracle::Introspect::Columns;

# LIVE (karr k38). What the type mapping makes of DATE, BINARY_FLOAT,
# BINARY_DOUBLE, FLOAT, VARCHAR2, NVARCHAR2, NCHAR, TIMESTAMP(n) and NUMBER
# as a real Oracle data dictionary reports them, and what comes back when a
# type goes the whole way round: Result class -> DDL -> server ->
# ALL_TAB_COLUMNS -> DBIO::Oracle::Introspect::Columns -> DBIO type.
#
# The card asked whether DBIO::Oracle::Type::map_dbd_type_to_dbio, which
# catches date|binary_float|binary_double early (it only drops the size),
# should keep the later branches for them. The maintainer decided (2026-10-18):
# the early catch stays -- an Oracle DATE is date, BINARY_FLOAT and
# BINARY_DOUBLE are binary_float and binary_double, because taking the later
# branches would turn a DATE into datetime, written as TIMESTAMP, and a
# MODIFY on every run. The unreachable branches were removed. FLOAT is
# float with its data_precision as the size (not data_length, which is 22 for
# every FLOAT; not real or double precision, which are BINARY_FLOAT and
# BINARY_DOUBLE when written); FLOAT(126) and FLOAT without a precision, the
# same to the dictionary, are float without a size. The sizes of
# VARCHAR2, NVARCHAR2, NCHAR and TIMESTAMP(n) survive the way round. This file
# holds:
#
#   1. Columns made by hand: what ALL_TAB_COLUMNS says of each, what the
#      driver's reader of that view, DBIO::Oracle::Introspect::Columns,
#      returns for it, and what type map_dbio_type_to_oracle writes for the
#      result -- the type a diff would create the column with elsewhere
#      (DBIO::Oracle::Diff::Column renders ADD and MODIFY from the
#      introspected side).
#   2. That the reader's types are map_dbd_type_to_dbio's, and nothing else.
#   3. The way round from a Result class, for datetime, date, real, double
#      precision and float: which Oracle type the DDL makes, what comes back,
#      and what a column diff between "deployed, as read back" and "desired,
#      as declared" then reports.
#   4. The way round for the sized types, declared as the reader names them:
#      varchar2(20), NVARCHAR2(20), NCHAR(10), timestamp(3), timestamp(3)
#      with time zone -- declared, deployed, introspected, as declared, and
#      the second column diff empty. And integer and numeric.
#
# DBIO::Oracle::Deploy never compares a declared type with one read back.
# Both of its models are introspected, so the mapping says whatever it says
# twice. What the mapping does decide is (a) the type written when a diff adds
# or modifies a column, and (b) the data_type anything gets that reads a live
# Oracle schema through DBIO::Oracle::Introspect and holds it against Result
# classes, or makes Result classes from it.
#
# Measured 2026-10-05 and 2026-10-18 against Oracle Database 23ai Free
# (23.26.3), with DBD::Oracle 1.95. What this file does NOT claim:
#
#   * anything about inflation. Whether a column read back as "date" loses
#     its time of day in InflateColumn::DateTime was not run here.
#   * that real and double precision come back as declared. They are written
#     as BINARY_FLOAT / BINARY_DOUBLE and come back as binary_float /
#     binary_double (3).
#   * a declared float with size 126: it is written as FLOAT(126), which the
#     dictionary cannot tell from FLOAT, so it is read as float without a size.
#   * the numbers on another server version: data_length, data_precision and
#     data_scale are what 23.26 reports.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_ORA_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_oracle')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_oracle');

alarm 300;   # no handler: an OCI call that hangs ends the run instead of never

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0]; warn $_[0] };

sub connect_plain {
  return DBI->connect($dsn, $user, $pass, {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
}

# The connection the driver's reader works on ...
my $dbh = connect_plain();

# ... and another one, for setup and for looking at what the server really
# holds, through nothing of this driver.
my $admin;
sub admin { $admin ||= connect_plain() }

my ($SCHEMA) = admin()->selectrow_array('SELECT USER FROM DUAL');

my $OWN = q{LIKE 'K38\_LIVE%' ESCAPE '\'};

sub own_tables {
  return [ map { $_->[0] } @{ admin()->selectall_arrayref(qq{
    SELECT table_name FROM user_tables WHERE UPPER(table_name) $OWN
    ORDER BY table_name
  }) } ];
}

# PURGE keeps the tables out of the recycle bin, where they would still be
# something of this test.
sub wipe {
  admin()->do(qq{DROP TABLE "$_" PURGE}) for @{ own_tables() };
}

# The columns of a table as the driver's reader returns them: the model's
# list of column hashes, in the order of the table.
sub introspected {
  my ($table) = @_;

  return DBIO::Oracle::Introspect::Columns->fetch($dbh, $SCHEMA, {
    $table => { table_name => $table, kind => 'table', schema => $SCHEMA },
  })->{$table} || [];
}

# A table read back, both ways side by side. Per column:
#
#   dictionary  [ data_type, data_length, data_precision, data_scale ], as
#               ALL_TAB_COLUMNS holds them -- asked on the other connection,
#               through nothing of this driver
#   dbio        the type DBIO::Oracle::Introspect::Columns returns for the
#               column: its hash without the name and the nullability
#   again       the Oracle type map_dbio_type_to_oracle writes for that
# char_length and char_used of every column read back, by name
my %CHARS;

sub read_back {
  my ($table) = @_;

  my %column;
  for my $row (@{ admin()->selectall_arrayref(q{
    SELECT column_name, data_type, data_length, data_precision, data_scale,
           char_length, char_used
    FROM all_tab_columns
    WHERE table_name = ? AND owner = ?
    ORDER BY column_id
  }, undef, $table, $SCHEMA) }) {
    my ($name, @dictionary) = @$row;
    my @chars = splice @dictionary, 4;
    $column{$name} = { dictionary => \@dictionary };
    $CHARS{$name} = \@chars;
  }

  for my $introspected (@{ introspected($table) }) {
    my %dbio = %$introspected;
    my $name = delete $dbio{column_name};
    delete $dbio{not_null};

    $column{$name}{dbio}  = \%dbio;
    $column{$name}{again} = written_for(\%dbio);
  }

  return \%column;
}

sub written_for {
  my ($dbio) = @_;
  return DBIO::Oracle::Type::map_dbio_type_to_oracle(
    $dbio->{data_type}, size => $dbio->{size},
  );
}

my $live = 1;   # past every skip_all: from here on there is something to drop

wipe();         # what a run that died before its END block may have left

is_deeply own_tables(), [], '(the schema holds nothing of this test to begin with)';

# ===================================================================== 1
# Columns made by hand.

my @HAND = (
  [ C_DATE     => 'DATE'          ],
  [ C_BFLOAT   => 'BINARY_FLOAT'  ],
  [ C_BDOUBLE  => 'BINARY_DOUBLE' ],
  [ C_FLOAT63  => 'FLOAT(63)'     ],
  [ C_FLOAT126 => 'FLOAT(126)'    ],
  [ C_FLOAT    => 'FLOAT'         ],
  [ C_TS       => 'TIMESTAMP'     ],
  [ C_INT      => 'INTEGER'       ],
  [ C_SMALLINT => 'SMALLINT'      ],
  [ C_NUM      => 'NUMBER'        ],
  [ C_N38      => 'NUMBER(38)'    ],
  [ C_N380     => 'NUMBER(38,0)'  ],
  [ C_N102     => 'NUMBER(10,2)'  ],
  [ C_V20CHAR  => 'VARCHAR2(20 CHAR)' ],
  [ C_V20BYTE  => 'VARCHAR2(20 BYTE)' ],
  [ C_CH5CHAR  => 'CHAR(5 CHAR)'  ],
  [ C_TSLTZ    => 'TIMESTAMP WITH LOCAL TIME ZONE' ],
  [ C_TSLTZ3   => 'TIMESTAMP(3) WITH LOCAL TIME ZONE' ],
);

admin()->do(
  'CREATE TABLE K38_LIVE_HAND ('
  . join(', ', map { "$_->[0] $_->[1]" } @HAND) . ')'
);

my $hand = read_back('K38_LIVE_HAND');

is_deeply $hand->{C_DATE}, {
  dictionary => [ 'DATE', 7, undef, undef ],
  dbio       => { data_type => 'date' },
  again      => 'DATE',
}, 'IS: a DATE column is reported as DATE, is the DBIO type date, and is '
 . 'written as DATE again -- the branch that would make it datetime is not '
 . 'reached';

is_deeply $hand->{C_BFLOAT}, {
  dictionary => [ 'BINARY_FLOAT', 4, undef, undef ],
  dbio       => { data_type => 'binary_float' },
  again      => 'BINARY_FLOAT',
}, 'IS: BINARY_FLOAT stays binary_float (not real), and is written as '
 . 'BINARY_FLOAT again -- by the fall-through that upper-cases a type '
 . 'map_dbio_type_to_oracle does not know';

is_deeply $hand->{C_BDOUBLE}, {
  dictionary => [ 'BINARY_DOUBLE', 8, undef, undef ],
  dbio       => { data_type => 'binary_double' },
  again      => 'BINARY_DOUBLE',
}, 'IS: BINARY_DOUBLE stays binary_double (not double precision), and is '
 . 'written as BINARY_DOUBLE again, the same way';

# FLOAT is the one of these types the early branch does not catch: float,
# with data_precision as the size; 126, the precision of a FLOAT without one,
# carries none.

is_deeply $hand->{C_FLOAT63}, {
  dictionary => [ 'FLOAT', 22, 63, undef ],
  dbio       => { data_type => 'float', size => 63 },
  again      => 'FLOAT(63)',
}, 'FLOAT(63) is reported as FLOAT with data_precision 63 and data_length '
 . '22, is float of size 63, and is written as FLOAT(63) again';

is_deeply $hand->{C_FLOAT126}, {
  dictionary => [ 'FLOAT', 22, 126, undef ],
  dbio       => { data_type => 'float' },
  again      => 'FLOAT',
}, 'FLOAT(126) is float without a size, and is written as FLOAT, which is '
 . 'FLOAT(126)';

is_deeply $hand->{C_FLOAT}, $hand->{C_FLOAT126},
  'a FLOAT without precision is a FLOAT(126) to the dictionary, and so the same';

is_deeply $hand->{C_TS}, {
  dictionary => [ 'TIMESTAMP(6)', 11, undef, 6 ],
  dbio       => { data_type => 'timestamp' },
  again      => 'TIMESTAMP',
}, 'IS: TIMESTAMP is reported as TIMESTAMP(6), is timestamp, and is '
 . 'written as TIMESTAMP again';

# NUMBER (karr k38). INTEGER and SMALLINT are NUMBER with a scale of 0 and no
# precision in the dictionary; a bare NUMBER has neither precision nor scale;
# NUMBER(38) and NUMBER(38,0) are precision 38, scale 0.
is_deeply
  { map { $_ => $hand->{$_}{dictionary} } qw(C_INT C_SMALLINT C_NUM C_N38 C_N380 C_N102) },
  {
    C_INT      => [ 'NUMBER', 22, undef, 0 ],
    C_SMALLINT => [ 'NUMBER', 22, undef, 0 ],
    C_NUM      => [ 'NUMBER', 22, undef, undef ],
    C_N38      => [ 'NUMBER', 22, 38, 0 ],
    C_N380     => [ 'NUMBER', 22, 38, 0 ],
    C_N102     => [ 'NUMBER', 22, 10, 2 ],
  },
  'IS: what the dictionary holds for INTEGER, SMALLINT, NUMBER, NUMBER(38), NUMBER(38,0), NUMBER(10,2)';

is_deeply
  { map { $_ => $hand->{$_}{dbio} } qw(C_INT C_SMALLINT C_NUM C_N38 C_N380 C_N102) },
  {
    C_INT      => { data_type => 'integer' },
    C_SMALLINT => { data_type => 'integer' },
    C_NUM      => { data_type => 'numeric' },
    C_N38      => { data_type => 'numeric', size => [ 38, 0 ] },
    C_N380     => { data_type => 'numeric', size => [ 38, 0 ] },
    C_N102     => { data_type => 'numeric', size => [ 10, 2 ] },
  },
  'INTEGER and SMALLINT (scale 0, no precision) are integer; NUMBER(38) and '
. 'NUMBER(38,0) (precision 38) are numeric, as is a bare NUMBER';

# Length semantics (karr k38): data_length is bytes (80 for 20 CHAR), char_used
# says 'C' or 'B'; a CHAR-semantics size is read as the string "N CHAR".
is_deeply
  { map { $_ => $hand->{$_}{dbio} } qw(C_V20CHAR C_V20BYTE C_CH5CHAR) },
  {
    C_V20CHAR => { data_type => 'varchar2', size => '20 CHAR' },
    C_V20BYTE => { data_type => 'varchar2', size => 20 },
    C_CH5CHAR => { data_type => 'char',     size => '5 CHAR' },
  },
  'VARCHAR2(20 CHAR) and CHAR(5 CHAR) are read with their length semantics, '
. 'a BYTE column keeps the plain size';

is_deeply
  { map { $_ => $hand->{$_}{dbio} } qw(C_TSLTZ C_TSLTZ3) },
  {
    C_TSLTZ  => { data_type => 'timestamp with local time zone' },
    C_TSLTZ3 => { data_type => 'timestamp with local time zone', size => 3 },
  },
  'TIMESTAMP WITH LOCAL TIME ZONE is its own type, not timestamp with time zone; '
. 'the default precision 6 carries no size';

# ===================================================================== 2
# The reader and the mapping. 1 took the DBIO types from the reader; here
# the same dictionary rows are put through map_dbd_type_to_dbio by hand, with
# the arguments the reader gives it.

is_deeply
  [ map { [ $_->{column_name}, $_->{not_null} ] } @{ introspected('K38_LIVE_HAND') } ],
  [ map { [ $_->[0], 0 ] } @HAND ],
  'DBIO::Oracle::Introspect::Columns returns the columns of the hand-made table by name, in '
. 'the order of the table, each nullable';

is_deeply
  { map { $_->[0] => $hand->{ $_->[0] }{dbio} } @HAND },
  { map {
      my ($type, $length, $precision, $scale) = @{ $hand->{ $_->[0] }{dictionary} };
      $_->[0] => DBIO::Oracle::Type::map_dbd_type_to_dbio(
        $type,
        data_length    => $length,
        data_precision => $precision,
        data_scale     => $scale,
        char_length    => $CHARS{ $_->[0] }[0],
        char_used      => $CHARS{ $_->[0] }[1],
      );
    } @HAND },
  '... and the type of each is what map_dbd_type_to_dbio makes of the '
. 'dictionary\'s row: from a live schema, the mapping is reached and is all '
. 'there is';

# ===================================================================== 3
# The way round from a Result class.

{
  package T::K38::Class;
  use base 'DBIO::Core';
  __PACKAGE__->table('k38_live_class');
  __PACKAGE__->add_columns(
    c_datetime => { data_type => 'datetime',         is_nullable => 1 },
    c_date     => { data_type => 'date',             is_nullable => 1 },
    c_real     => { data_type => 'real',             is_nullable => 1 },
    c_double   => { data_type => 'double precision', is_nullable => 1 },
    c_float    => { data_type => 'float',            is_nullable => 1 },
  );
}

{
  package T::K38::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Class => 'T::K38::Class');
}

my $ddl = DBIO::Oracle::DDL->install_ddl('T::K38::Schema');

is $ddl, <<'SQL' =~ s/\n\z//r, 'IS: the DDL for datetime, date, real, double precision and float';
CREATE TABLE "k38_live_class" (
  "c_datetime" TIMESTAMP,
  "c_date" DATE,
  "c_real" BINARY_FLOAT,
  "c_double" BINARY_DOUBLE,
  "c_float" FLOAT
);
SQL

admin()->do($_) for DBIO::SQL::Util::_split_statements($ddl);

my $class = read_back('k38_live_class');

my @DECLARED = map {
  [ $_, T::K38::Class->column_info($_)->{data_type} ]
} T::K38::Class->columns;

# declared type => [ what the dictionary reports, the DBIO type that is,
# the Oracle type written for it again ]
is_deeply
  [ map { [
      $_->[1],
      $class->{ $_->[0] }{dictionary}[0],
      $class->{ $_->[0] }{dbio}{data_type},
      $class->{ $_->[0] }{again},
    ] } @DECLARED ],
  [
    [ 'datetime',         'TIMESTAMP(6)',  'timestamp',     'TIMESTAMP'     ],
    [ 'date',             'DATE',          'date',          'DATE'          ],
    [ 'real',             'BINARY_FLOAT',  'binary_float',  'BINARY_FLOAT'  ],
    [ 'double precision', 'BINARY_DOUBLE', 'binary_double', 'BINARY_DOUBLE' ],
    [ 'float',            'FLOAT',         'float',         'FLOAT'         ],
  ],
  'IS: of the five declared types date and float come back as declared. '
. 'Each comes back as a type that is written as the Oracle type the column '
. 'has: the way round is stable on the server\'s side';

# A column diff with what was read back as the source and what was declared
# as the target: one line per column it reports, with the statement it would
# send.
sub diff_against_declared {
  my @source = map { {
    %{ $class->{ $_->[0] }{dbio} },
    column_name => $_->[0], not_null => 0,
  } } @DECLARED;

  my @target = map { {
    column_name => $_->[0], data_type => $_->[1], not_null => 0,
  } } @DECLARED;

  my $table = { k38_live_class => {} };

  return [ map {
    $_->column_name . ': ' . ( $_->as_sql || 'no statement' )
  } DBIO::Oracle::Diff::Column->diff(
    { k38_live_class => \@source }, { k38_live_class => \@target },
    $table, $table,
  ) ];
}

is_deeply diff_against_declared(), [],
  'held against the declared types, no column is reported on a schema that was '
. 'deployed from those very declarations: datetime and timestamp, real and '
. 'binary_float, double precision and binary_double are one Oracle type each, '
. 'and a type change that renders the same cannot be altered. Before, three '
. 'columns were reported "no statement" on every run';

# ===================================================================== 4
# The sized types, declared as the reader names them, and integer.

{
  package T::K38::Sized;
  use base 'DBIO::Core';
  __PACKAGE__->table('k38_live_sized');
  __PACKAGE__->add_columns(
    c_varchar2  => { data_type => 'varchar2',  size => 20, is_nullable => 1 },
    c_nvarchar2 => { data_type => 'NVARCHAR2', size => 20, is_nullable => 1 },
    c_nchar     => { data_type => 'NCHAR',     size => 10, is_nullable => 1 },
    c_ts3       => { data_type => 'timestamp', size => 3,  is_nullable => 1 },
    c_tstz3     => { data_type => 'timestamp with time zone', size => 3,
                     is_nullable => 1 },
    c_integer   => { data_type => 'integer',   is_nullable => 1 },
    c_numeric   => { data_type => 'numeric',   is_nullable => 1 },
    c_varchar   => { data_type => 'varchar',   size => 20, is_nullable => 1 },
    c_float63   => { data_type => 'float',     size => 63,      is_nullable => 1 },
    c_num380    => { data_type => 'numeric',   size => [38, 0], is_nullable => 1 },
    c_num38     => { data_type => 'numeric',   size => 38,      is_nullable => 1 },
    c_tsltz     => { data_type => 'timestamp with local time zone', is_nullable => 1 },
    c_tsltz3    => { data_type => 'timestamp with local time zone', size => 3,
                     is_nullable => 1 },
    c_v20char   => { data_type => 'varchar2',  size => '20 CHAR', is_nullable => 1 },
    c_ch5char   => { data_type => 'char',      size => '5 CHAR',  is_nullable => 1 },
  );
}

{
  package T::K38::SizedSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Sized => 'T::K38::Sized');
}

my $sized_ddl = DBIO::Oracle::DDL->install_ddl('T::K38::SizedSchema');

like $sized_ddl, qr/"c_varchar2" VARCHAR2\(20\),\s+"c_nvarchar2" NVARCHAR2\(20\),\s+"c_nchar" NCHAR\(10\),\s+"c_ts3" TIMESTAMP\(3\),\s+"c_tstz3" TIMESTAMP\(3\) WITH TIME ZONE,\s+"c_integer" INTEGER,\s+"c_numeric" NUMBER,\s+"c_varchar" VARCHAR2\(20\),\s+"c_float63" FLOAT\(63\),\s+"c_num380" NUMBER\(38,0\),\s+"c_num38" NUMBER\(38\),\s+"c_tsltz" TIMESTAMP WITH LOCAL TIME ZONE,\s+"c_tsltz3" TIMESTAMP\(3\) WITH LOCAL TIME ZONE,\s+"c_v20char" VARCHAR2\(20 CHAR\),\s+"c_ch5char" CHAR\(5 CHAR\)/,
  'the DDL for the sized types carries the sizes';

admin()->do($_) for DBIO::SQL::Util::_split_statements($sized_ddl);

my $sized = read_back('k38_live_sized');

for my $c (
  [ c_varchar2  => 'VARCHAR2'     => { data_type => 'varchar2',  size => 20 } ],
  [ c_nvarchar2 => 'NVARCHAR2'    => { data_type => 'NVARCHAR2', size => 20 } ],
  [ c_nchar     => 'NCHAR'        => { data_type => 'NCHAR',     size => 10 } ],
  [ c_ts3       => 'TIMESTAMP(3)' => { data_type => 'timestamp', size => 3 } ],
  [ c_tstz3     => 'TIMESTAMP(3) WITH TIME ZONE'
                                  => { data_type => 'timestamp with time zone', size => 3 } ],
  [ c_float63   => 'FLOAT'        => { data_type => 'float', size => 63 } ],
  [ c_tsltz     => 'TIMESTAMP(6) WITH LOCAL TIME ZONE'
                                  => { data_type => 'timestamp with local time zone' } ],
  [ c_tsltz3    => 'TIMESTAMP(3) WITH LOCAL TIME ZONE'
                                  => { data_type => 'timestamp with local time zone', size => 3 } ],
  [ c_v20char   => 'VARCHAR2'     => { data_type => 'varchar2', size => '20 CHAR' } ],
  [ c_ch5char   => 'CHAR'         => { data_type => 'char',     size => '5 CHAR' } ],
) {
  my ($name, $dictionary, $declared) = @$c;
  is $sized->{$name}{dictionary}[0], $dictionary,
    "$name: the server holds $dictionary";
  is_deeply $sized->{$name}{dbio}, $declared,
    "$name: comes back from the introspection as declared";
}

{
  my @names = qw(c_varchar2 c_nvarchar2 c_nchar c_ts3 c_tstz3 c_varchar c_float63 c_tsltz c_tsltz3 c_v20char c_ch5char);
  my @source = map { {
    %{ $sized->{$_}{dbio} }, column_name => $_, not_null => 0,
  } } @names;
  my @target = map {
    my $d = T::K38::Sized->column_info($_);
    { column_name => $_, not_null => 0, data_type => $d->{data_type}, size => $d->{size} };
  } @names;
  my $t = { k38_live_sized => {} };
  is_deeply [ map { $_->column_name } DBIO::Oracle::Diff::Column->diff(
    { k38_live_sized => \@source }, { k38_live_sized => \@target }, $t, $t,
  ) ], [], 'a second column diff, read back against declared, is empty for '
         . 'every sized type';

  is_deeply
    [ map { $sized->{$_}{again} } @names ],
    [ 'VARCHAR2(20)', 'NVARCHAR2(20)', 'NCHAR(10)', 'TIMESTAMP(3)',
      'TIMESTAMP(3) WITH TIME ZONE', 'VARCHAR2(20)', 'FLOAT(63)', 'TIMESTAMP WITH LOCAL TIME ZONE',
      'TIMESTAMP(3) WITH LOCAL TIME ZONE', 'VARCHAR2(20 CHAR)', 'CHAR(5 CHAR)' ],
    'and what is written for them again is what the table has';
}

# A declared numeric(38,0) or numeric(38) is NUMBER(38,0) / NUMBER(38), which
# the dictionary holds as precision 38, scale 0 -- not what INTEGER is
# (precision NULL, scale 0), the type integer is written as. They come back
# as numeric, and the second diff is empty.
is_deeply [ map { $sized->{$_}{dbio} } qw(c_num380 c_num38) ],
  [ { data_type => 'numeric', size => [ 38, 0 ] }, { data_type => 'numeric', size => [ 38, 0 ] } ],
  'numeric of precision 38 comes back as numeric (NUMBER(38) and NUMBER(38,0) are one to the dictionary)';
{
  my @names = qw(c_num380 c_num38);
  my @source = map { { %{ $sized->{$_}{dbio} }, column_name => $_, not_null => 0 } } @names;
  my @target = map {
    my $d = T::K38::Sized->column_info($_);
    { column_name => $_, not_null => 0, data_type => $d->{data_type}, size => $d->{size} };
  } @names;
  my $t = { k38_live_sized => {} };
  is_deeply [ map { $_->column_name } DBIO::Oracle::Diff::Column->diff(
    { k38_live_sized => \@source }, { k38_live_sized => \@target }, $t, $t,
  ) ], [], 'a second column diff is empty for numeric(38) and numeric(38,0)';
}

# integer is written as INTEGER and comes back as integer; numeric with no
# size is written as a bare NUMBER and comes back as numeric.
is_deeply $sized->{c_integer}, {
  dictionary => [ 'NUMBER', 22, undef, 0 ],
  dbio       => { data_type => 'integer' },
  again      => 'INTEGER',
}, 'integer is deployed as INTEGER (precision NULL, scale 0) and comes back as integer';

is_deeply $sized->{c_numeric}, {
  dictionary => [ 'NUMBER', 22, undef, undef ],
  dbio       => { data_type => 'numeric' },
  again      => 'NUMBER',
}, 'numeric without size is deployed as a bare NUMBER and comes back as numeric';

# ===================================================================== 5
# Sizes the dictionary does not keep, and national types (karr k38). A
# precision of 6 on a timestamp and 126 on a float are the defaults: they come
# back without a size, and the column diff must not report them. A national
# column is always of character semantics, Oracle refuses NCHAR(5 CHAR).

{
  package T::K38::Dflt;
  use base 'DBIO::Core';
  __PACKAGE__->table('k38_live_dflt');
  __PACKAGE__->add_columns(
    c_ts6     => { data_type => 'timestamp', size => 6, is_nullable => 1 },
    c_tstz6   => { data_type => 'timestamp with time zone', size => 6, is_nullable => 1 },
    c_tsltz6  => { data_type => 'timestamp with local time zone', size => 6, is_nullable => 1 },
    c_float126 => { data_type => 'float', size => 126, is_nullable => 1 },
    c_num10   => { data_type => 'numeric', size => 10, is_nullable => 1 },
    c_num102  => { data_type => 'numeric', size => [10, 2], is_nullable => 1 },
    c_nchar5  => { data_type => 'NCHAR', size => '5 CHAR', is_nullable => 1 },
    c_nvar5   => { data_type => 'NVARCHAR2', size => '5 CHAR', is_nullable => 1 },
    c_v20     => { data_type => 'varchar2', size => '20 byte', is_nullable => 1 },
  );
}

{
  package T::K38::DfltSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Dflt => 'T::K38::Dflt');
}

my $dflt_ddl = DBIO::Oracle::DDL->install_ddl('T::K38::DfltSchema');

like $dflt_ddl, qr/"c_ts6" TIMESTAMP\(6\),\s+"c_tstz6" TIMESTAMP\(6\) WITH TIME ZONE,\s+"c_tsltz6" TIMESTAMP\(6\) WITH LOCAL TIME ZONE,\s+"c_float126" FLOAT\(126\),\s+"c_num10" NUMBER\(10\),\s+"c_num102" NUMBER\(10,2\),\s+"c_nchar5" NCHAR\(5\),\s+"c_nvar5" NVARCHAR2\(5\),\s+"c_v20" VARCHAR2\(20 BYTE\)/,
  'the DDL writes the default precisions, and a national type without CHAR';

admin()->do($_) for DBIO::SQL::Util::_split_statements($dflt_ddl);

my $dflt = read_back('k38_live_dflt');

is_deeply
  { map { $_ => $dflt->{$_}{dbio} } keys %$dflt },
  {
    c_ts6     => { data_type => 'timestamp' },
    c_tstz6   => { data_type => 'timestamp with time zone' },
    c_tsltz6  => { data_type => 'timestamp with local time zone' },
    c_float126 => { data_type => 'float' },
    c_num10   => { data_type => 'numeric', size => [10, 0] },
    c_num102  => { data_type => 'numeric', size => [10, 2] },
    c_nchar5  => { data_type => 'NCHAR', size => 5 },
    c_nvar5   => { data_type => 'NVARCHAR2', size => 5 },
    c_v20     => { data_type => 'varchar2', size => 20 },
  },
  'the default precisions come back without a size, national types as a number';

{
  my @names = T::K38::Dflt->columns;
  my @source = map { {
    %{ $dflt->{$_}{dbio} }, column_name => $_, not_null => 0,
  } } @names;
  my @target = map {
    my $d = T::K38::Dflt->column_info($_);
    { column_name => $_, not_null => 0, data_type => $d->{data_type}, size => $d->{size} };
  } @names;
  my $t = { k38_live_dflt => {} };
  is_deeply [ map { $_->column_name . ': ' . ($_->as_sql || '-') } DBIO::Oracle::Diff::Column->diff(
    { k38_live_dflt => \@source }, { k38_live_dflt => \@target }, $t, $t,
  ) ], [], 'the second column diff is empty for the default precisions, numeric(10), '
         . 'national types and a BYTE size';
}

# A new table through DBIO::Oracle::Diff::Table: the server takes its types.
{
  my @create = DBIO::Oracle::Diff::Table->diff(
    {}, { k38_live_made => { table_name => 'k38_live_made' } },
    { k38_live_made => [
      { column_name => 'c_char', data_type => 'varchar2', size => '20 CHAR' },
      { column_name => 'c_tsltz3', data_type => 'timestamp with local time zone', size => 3 },
      { column_name => 'c_tstz3', data_type => 'timestamp with time zone', size => 3 },
      { column_name => 'c_nchar', data_type => 'NCHAR', size => '5 CHAR' },
      { column_name => 'c_raw', data_type => 'raw', size => 16 },
    ] },
    {},
  );
  my $sql = $create[0]->as_sql;
  $sql =~ s/;\s*\z//;
  my $ok = eval { admin()->do($sql); 1 };
  ok $ok, 'CREATE TABLE of Diff::Table is accepted by the server' or diag $@, $sql;
  is_deeply
    [ map { $_->[1] } @{ admin()->selectall_arrayref(q{
        SELECT column_name, data_type FROM all_tab_columns
        WHERE table_name = 'k38_live_made' AND owner = ? ORDER BY column_id
      }, undef, $SCHEMA) } ],
    [ 'VARCHAR2', 'TIMESTAMP(3) WITH LOCAL TIME ZONE', 'TIMESTAMP(3) WITH TIME ZONE', 'NCHAR', 'RAW' ],
    '... with the types that were declared';
}

# ===================================================================== 6
# Older mapping (karr k38): RAW, nvarchar, interval and numeric with a scale
# of undef, deployed and read back.

{
  package T::K38::Legacy;
  use base 'DBIO::Core';
  __PACKAGE__->table('k38_live_legacy');
  __PACKAGE__->add_columns(
    c_raw     => { data_type => 'raw',      size => 16, is_nullable => 1 },
    c_nvarchar => { data_type => 'nvarchar', size => 10, is_nullable => 1 },
    c_ym3     => { data_type => 'interval year to month', size => 3, is_nullable => 1 },
    c_ym      => { data_type => 'interval year to month', is_nullable => 1 },
    c_ym2     => { data_type => 'interval year to month', size => 2, is_nullable => 1 },
    c_ds34    => { data_type => 'interval day to second', size => [3, 4], is_nullable => 1 },
    c_ds      => { data_type => 'interval day to second', is_nullable => 1 },
    c_ds26    => { data_type => 'interval day to second', size => [2, 6], is_nullable => 1 },
    c_num10u  => { data_type => 'numeric',  size => [10, undef], is_nullable => 1 },
  );
}

{
  package T::K38::LegacySchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Legacy => 'T::K38::Legacy');
}

my $legacy_ddl = DBIO::Oracle::DDL->install_ddl('T::K38::LegacySchema');

like $legacy_ddl, qr/"c_raw" RAW\(16\),\s+"c_nvarchar" NVARCHAR2\(10\),\s+"c_ym3" INTERVAL YEAR\(3\) TO MONTH,\s+"c_ym" INTERVAL YEAR TO MONTH,\s+"c_ym2" INTERVAL YEAR\(2\) TO MONTH,\s+"c_ds34" INTERVAL DAY\(3\) TO SECOND\(4\),\s+"c_ds" INTERVAL DAY TO SECOND,\s+"c_ds26" INTERVAL DAY\(2\) TO SECOND\(6\),\s+"c_num10u" NUMBER\(10\)/,
  'the DDL writes RAW with its size, nvarchar as NVARCHAR2, the interval precisions, numeric without a trailing comma';

my $ok = eval { admin()->do($_) for DBIO::SQL::Util::_split_statements($legacy_ddl); 1 };
ok $ok, 'the server takes that DDL' or diag $@;

SKIP: {
  skip 'no table', 3 unless $ok;
  my $legacy = read_back('k38_live_legacy');

  is_deeply $legacy->{c_raw}{dictionary}, [ 'RAW', 16, undef, undef ],
    'IS: the dictionary holds the length of a RAW in bytes: 16, not 32';

  is_deeply
    { map { $_ => $legacy->{$_}{dbio} } keys %$legacy },
    {
      c_raw      => { data_type => 'raw', size => 16 },
      c_nvarchar => { data_type => 'NVARCHAR2', size => 10 },
      c_ym3      => { data_type => 'interval year to month', size => 3 },
      c_ym       => { data_type => 'interval year to month' },
      c_ym2      => { data_type => 'interval year to month' },
      c_ds34     => { data_type => 'interval day to second', size => [ 3, 4 ] },
      c_ds       => { data_type => 'interval day to second' },
      c_ds26     => { data_type => 'interval day to second' },
      c_num10u   => { data_type => 'numeric', size => [ 10, 0 ] },
    },
    'RAW, NVARCHAR2, the intervals and numeric(10) come back as declared '
  . '(the default precisions without a size)';

  my @names = T::K38::Legacy->columns;
  my @source = map { { %{ $legacy->{$_}{dbio} }, column_name => $_, not_null => 0 } } @names;
  my @target = map {
    my $d = T::K38::Legacy->column_info($_);
    { column_name => $_, not_null => 0, data_type => $d->{data_type}, size => $d->{size} };
  } @names;
  my $t = { k38_live_legacy => {} };
  is_deeply [ map { $_->column_name . ': ' . ($_->as_sql || '-') } DBIO::Oracle::Diff::Column->diff(
    { k38_live_legacy => \@source }, { k38_live_legacy => \@target }, $t, $t,
  ) ], [], 'the second column diff is empty';
}

# ================================================================ the end

wipe();

is_deeply own_tables(), [], 'nothing of this test is left in the schema';

is_deeply
  admin()->selectall_arrayref(
    qq{SELECT original_name FROM user_recyclebin WHERE UPPER(original_name) $OWN}
  ),
  [],
  '... and nothing in its recycle bin';

is_deeply \@warnings, [],
  'no warning on the way';

done_testing;

# Again on a new connection: for a run that died on the way.
END {
  if ($live) {
    local $?;
    undef $admin;
    eval { wipe(); 1 }
      or diag "Could not drop the k38_live_* tables: $@";
  }
}
