use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Oracle::Introspect;
use DBIO::Oracle::Introspect::Tables;
use DBIO::Oracle::Introspect::Columns;
use DBIO::Oracle::Introspect::Indexes;
use DBIO::Oracle::Introspect::ForeignKeys;
use DBIO::Oracle::Introspect::Keys;

# LIVE. DBIO::Oracle::Introspect against a real Oracle schema: tables made by
# hand, and the model the introspection returns for them held against what
# was made.
#
# t/60-introspect-contract.t and t/61-introspect-submodules.t check the same
# classes offline, the first on a model written by hand, the second on rows a
# mock hands out. Neither can know what a server answers, and until this file
# existed the classes had not met one: the foreign key query named an alias
# it never defined (ORA-00904), every row was read by lower-case hash keys
# where DBD::Oracle delivers upper-case ones, the foreign key query joined
# its constraints to an index they do not have and its columns to each other
# without their position, and the two LONG columns the column reader fetches
# -- a default, a trigger body -- were read with the 80 bytes DBI allows
# unless told otherwise (ORA-24345). The tables below have something for
# each of these: a trigger and a default longer than 80 bytes, a foreign key
# over two columns whose order is neither that of the table nor of the
# alphabet.
#
#   1. The model, section by section: tables and a view, columns, indexes,
#      primary keys, unique constraints, foreign keys.
#   2. The parts by themselves, as DBIO::Oracle::Introspect calls them.
#   3. The normalized contract of DBIO::Introspect::Base on top of the model:
#      what a generator of Result classes is given.
#
# The schema of a test user holds what other tests left, and the model is of
# the whole schema. Everything here is asserted of this file's own objects
# (t57_live_*) and of nothing else.
#
# Measured 2026-10-05 against Oracle Database 23ai Free (23.26.3), with
# DBD::Oracle 1.95. What this file does NOT claim:
#
#   * that the DBIO types are the right ones. They are what
#     DBIO::Oracle::Type::map_dbd_type_to_dbio makes of the dictionary today;
#     t/56-type-roundtrip-live.t is about that mapping (karr k38).
#     A change there changes the expectations here, knowingly.
#   * that "current_timestamp" is a faithful reading of DEFAULT SYSDATE. It
#     is what the column reader makes of it; asserted as what IS.
#   * anything about another schema than the connected user's, about
#     synonyms, partitions, materialized views, function-based or bitmap
#     indexes, check constraints, or comments. None is made here.
#   * a foreign key into another schema, or one that references a unique
#     constraint over an index of another name.
#   * Oracle before 12c: the IDENTITY column needs it, and the file skips
#     below that.
#   * the model of a test deploy: DBIO::Oracle::Deploy builds it in a
#     temporary user, t/54-deploy-live.t (karr k36).

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

# The connection the introspection works on: a plain DBI handle with DBI's
# defaults, LongReadLen 80 among them ...
my $dbh = connect_plain();

# ... and another one, for setup and for looking at what the server really
# holds, through nothing of this driver.
my $admin;
sub admin { $admin ||= connect_plain() }

plan skip_all => 'This test needs Oracle 12c or later: it creates an IDENTITY column'
  unless admin()->func('ora_server_version')->[0] >= 12;

my ($SCHEMA) = admin()->selectrow_array('SELECT USER FROM DUAL');

my $OWN = q{LIKE 'T57\_LIVE%' ESCAPE '\'};

sub own_objects {
  return [ map { "$_->[0] $_->[1]" } @{ admin()->selectall_arrayref(qq{
    SELECT object_type, object_name FROM user_objects
    WHERE object_type IN ('TABLE', 'VIEW', 'SEQUENCE', 'TRIGGER', 'INDEX')
      AND UPPER(object_name) $OWN
    ORDER BY object_type, object_name
  }) } ];
}

# PURGE keeps the tables out of the recycle bin, where they would still be
# something of this test. The sequence of the IDENTITY column goes with its
# table.
sub wipe {
  my $dbh = admin();
  for my $statement (
    'DROP VIEW T57_LIVE_V',
    'DROP TABLE T57_LIVE_ITEM CASCADE CONSTRAINTS PURGE',
    'DROP TABLE T57_LIVE_PARENT CASCADE CONSTRAINTS PURGE',
    'DROP TABLE T57_LIVE_IDENT CASCADE CONSTRAINTS PURGE',
    'DROP SEQUENCE T57_LIVE_ITEM_SEQ',
  ) {
    eval { $dbh->do($statement); 1 }
      or $@ =~ /ORA-(?:00942|02289)\b/   # nothing there to drop
      or die $@;
  }
}

# The part of a model section that is this file's: the entries of its own
# tables.
sub own {
  my ($section) = @_;
  return { map { $_ => $section->{$_} } grep { /\AT57_LIVE/ } keys %{ $section || {} } };
}

my $live = 1;   # past every skip_all: from here on there is something to drop

wipe();         # what a run that died before its END block may have left

is_deeply own_objects(), [], '(the schema holds nothing of this test to begin with)';

# --------------------------------------------------------------- the tables

# 90 characters: longer than the 80 bytes DBI reads of a LONG column -- which
# DATA_DEFAULT is -- unless LongReadLen says otherwise.
my $LONG_DEFAULT = join '', map { chr( ord('a') + $_ % 26 ) } 0 .. 89;

admin()->do($_) for (
  # The unique constraint is what the two-column foreign key references. Its
  # columns are in neither the table's order nor the alphabet's.
  'CREATE TABLE T57_LIVE_PARENT ('
. ' ID NUMBER(10) NOT NULL, TENANT NUMBER(5) NOT NULL, NAME VARCHAR2(50),'
. ' CONSTRAINT T57_LIVE_PARENT_PK PRIMARY KEY (ID),'
. ' CONSTRAINT T57_LIVE_PARENT_UQ UNIQUE (TENANT, ID))',

  'CREATE SEQUENCE T57_LIVE_ITEM_SEQ',

  'CREATE TABLE T57_LIVE_ITEM ('
. ' ID NUMBER NOT NULL,'
. ' PARENT_ID NUMBER(10),'
. ' P_ID NUMBER(10),'
. ' P_TENANT NUMBER(5),'
. ' CODE VARCHAR2(20) NOT NULL,'
. " NAME VARCHAR2(100) DEFAULT '$LONG_DEFAULT',"
. ' EMAIL VARCHAR2(100),'
. ' PRICE NUMBER(10,2) DEFAULT 0,'
. ' BORN DATE DEFAULT SYSDATE,'
. ' SEEN TIMESTAMP,'
. ' NOTE CLOB,'
. ' CONSTRAINT T57_LIVE_ITEM_PK PRIMARY KEY (ID),'
. ' CONSTRAINT T57_LIVE_ITEM_CODE_UQ UNIQUE (CODE),'
. ' CONSTRAINT T57_LIVE_ITEM_SFK FOREIGN KEY (PARENT_ID)'
. '   REFERENCES T57_LIVE_PARENT (ID) DEFERRABLE INITIALLY IMMEDIATE,'
. ' CONSTRAINT T57_LIVE_ITEM_MFK FOREIGN KEY (P_TENANT, P_ID)'
. '   REFERENCES T57_LIVE_PARENT (TENANT, ID) ON DELETE CASCADE)',

  'CREATE INDEX T57_LIVE_ITEM_NAME_IX ON T57_LIVE_ITEM (NAME)',
  'CREATE UNIQUE INDEX T57_LIVE_ITEM_EMAIL_UX ON T57_LIVE_ITEM (EMAIL)',
  'CREATE INDEX T57_LIVE_ITEM_PN_IX ON T57_LIVE_ITEM (PARENT_ID, NAME)',

  # The usual shape of an auto-increment trigger; its body is 139 bytes.
  'CREATE TRIGGER T57_LIVE_ITEM_BI BEFORE INSERT ON T57_LIVE_ITEM '
. 'FOR EACH ROW BEGIN IF :new.ID IS NULL THEN '
. 'SELECT T57_LIVE_ITEM_SEQ.nextval INTO :new.ID FROM DUAL; '
. 'END IF; /* a remark to make this body long enough */ END;',

  # No trigger, no sequence of its own to name, and a primary key Oracle
  # names.
  'CREATE TABLE T57_LIVE_IDENT ('
. ' ID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,'
. ' LABEL VARCHAR2(10))',

  'CREATE VIEW T57_LIVE_V AS SELECT ID, CODE FROM T57_LIVE_ITEM WHERE CODE IS NOT NULL',
);

{
  local admin()->{LongReadLen} = 4000;

  cmp_ok
    length +( admin()->selectrow_array(q{
      SELECT trigger_body FROM user_triggers WHERE trigger_name = 'T57_LIVE_ITEM_BI'
    }) )[0], '>', 80,
    '(the trigger body is longer than DBI\'s default LongReadLen)';
}

# ---------------------------------------------------------------- expected

my %TABLES = (
  ( map { $_ => { table_name => $_, kind => 'table', schema => $SCHEMA } }
      qw(T57_LIVE_IDENT T57_LIVE_ITEM T57_LIVE_PARENT) ),
  T57_LIVE_V => { table_name => 'T57_LIVE_V', kind => 'view', schema => $SCHEMA },
);

my %COLUMNS = (
  T57_LIVE_ITEM => [
    { column_name => 'ID', data_type => 'numeric', not_null => 1,
      is_auto_increment => 1, sequence => "$SCHEMA.T57_LIVE_ITEM_SEQ" },
    { column_name => 'PARENT_ID', data_type => 'numeric', size => [ 10, 0 ], not_null => 0 },
    { column_name => 'P_ID',      data_type => 'numeric', size => [ 10, 0 ], not_null => 0 },
    { column_name => 'P_TENANT',  data_type => 'numeric', size => [ 5, 0 ],  not_null => 0 },
    { column_name => 'CODE',  data_type => 'varchar2', size => 20,  not_null => 1 },
    { column_name => 'NAME',  data_type => 'varchar2', size => 100, not_null => 0,
      default_value => $LONG_DEFAULT },
    { column_name => 'EMAIL', data_type => 'varchar2', size => 100, not_null => 0 },
    { column_name => 'PRICE', data_type => 'numeric', size => [ 10, 2 ], not_null => 0,
      default_value => 0 },
    { column_name => 'BORN',  data_type => 'date', not_null => 0,
      default_value => \'current_timestamp' },
    { column_name => 'SEEN',  data_type => 'timestamp', not_null => 0 },
    { column_name => 'NOTE',  data_type => 'clob',      not_null => 0 },
  ],
  T57_LIVE_PARENT => [
    { column_name => 'ID',     data_type => 'numeric', size => [ 10, 0 ], not_null => 1 },
    { column_name => 'TENANT', data_type => 'numeric', size => [ 5, 0 ],  not_null => 1 },
    { column_name => 'NAME',   data_type => 'varchar2', size => 50, not_null => 0 },
  ],
  T57_LIVE_V => [
    { column_name => 'ID',   data_type => 'numeric',  not_null => 1 },
    { column_name => 'CODE', data_type => 'varchar2', size => 20, not_null => 1 },
  ],
);

# The model marks the columns of a primary key (is_pk, pk_position); the
# Columns part by itself does not (karr k60). The expectation of the model is
# %COLUMNS with the marks of the primary keys set in the CREATE TABLEs above.
sub with_pk {
  my ($cols, %pos) = @_;
  return [ map {
    exists $pos{ $_->{column_name} }
      ? { %$_, is_pk => 1, pk_position => $pos{ $_->{column_name} } }
      : $_
  } @$cols ];
}

my %MODEL_COLUMNS = (
  T57_LIVE_ITEM   => with_pk($COLUMNS{T57_LIVE_ITEM},   ID => 1),
  T57_LIVE_PARENT => with_pk($COLUMNS{T57_LIVE_PARENT}, ID => 1),
);

my %INDEXES = (
  T57_LIVE_ITEM => {
    T57_LIVE_ITEM_EMAIL_UX => {
      index_name => 'T57_LIVE_ITEM_EMAIL_UX', is_unique => 1,
      columns    => ['EMAIL'],
    },
    T57_LIVE_ITEM_NAME_IX => {
      index_name => 'T57_LIVE_ITEM_NAME_IX', is_unique => 0,
      columns    => ['NAME'],
    },
    T57_LIVE_ITEM_PN_IX => {
      index_name => 'T57_LIVE_ITEM_PN_IX', is_unique => 0,
      columns    => [ 'PARENT_ID', 'NAME' ],
    },
  },
  T57_LIVE_PARENT => {},
  T57_LIVE_IDENT  => {},
  T57_LIVE_V      => {},
);

my %PRIMARY = (
  T57_LIVE_ITEM   => ['ID'],
  T57_LIVE_PARENT => ['ID'],
  T57_LIVE_IDENT  => ['ID'],
  T57_LIVE_V      => [],
);

my %UNIQUE = (
  T57_LIVE_ITEM   => [ [ T57_LIVE_ITEM_CODE_UQ => ['CODE'] ] ],
  T57_LIVE_PARENT => [ [ T57_LIVE_PARENT_UQ => [ 'TENANT', 'ID' ] ] ],
  T57_LIVE_IDENT  => [],
  T57_LIVE_V      => [],
);

my %FOREIGN = (
  T57_LIVE_ITEM => [
    {
      constraint_name      => 'T57_LIVE_ITEM_MFK',
      from_table   => 'T57_LIVE_ITEM',   from_columns => [ 'P_TENANT', 'P_ID' ],
      to_table     => 'T57_LIVE_PARENT', to_columns   => [ 'TENANT', 'ID' ],
      on_update    => 'NO ACTION',       on_delete    => 'CASCADE',
      is_deferrable => 0,
    },
    {
      constraint_name      => 'T57_LIVE_ITEM_SFK',
      from_table   => 'T57_LIVE_ITEM',   from_columns => ['PARENT_ID'],
      to_table     => 'T57_LIVE_PARENT', to_columns   => ['ID'],
      on_update    => 'NO ACTION',       on_delete    => 'NO ACTION',
      is_deferrable => 1,
    },
  ],
  T57_LIVE_PARENT => [],
  T57_LIVE_IDENT  => [],
  T57_LIVE_V      => [],
);

# ===================================================================== 1
# The model.

my $intro = DBIO::Oracle::Introspect->new(dbh => $dbh);
my $model = eval { $intro->model };

is $@, '', 'the model of a live schema can be had: the introspection lives';

$model ||= {};

is_deeply [ sort keys %$model ],
  [ qw(columns foreign_keys indexes primary_keys tables unique_constraints views) ],
  '... with the seven sections its documentation names';

is_deeply own($model->{tables}), \%TABLES,
  'tables: the three tables and the view, each under its name, the view as '
. 'a view';

is_deeply $model->{columns}{T57_LIVE_ITEM}, $MODEL_COLUMNS{T57_LIVE_ITEM},
  'columns: the item\'s eleven in the order of the table, each with its '
. 'name, type, size and nullability; the default of 90 characters whole; '
. 'the sequence found in a trigger body of more than 80 bytes';

is_deeply $model->{columns}{T57_LIVE_PARENT}, $MODEL_COLUMNS{T57_LIVE_PARENT},
  'columns: the parent\'s three';

is_deeply $model->{columns}{T57_LIVE_V}, $COLUMNS{T57_LIVE_V},
  'columns: the view\'s two, with the types of the columns behind them';

# The IDENTITY column: auto-increment, and not an expression default -- the
# "ISEQ$$_n".nextval Oracle shows in data_default is its generator (karr k41).
is_deeply $model->{columns}{T57_LIVE_IDENT}, [
  { column_name => 'ID',    data_type => 'numeric',  not_null => 1, is_auto_increment => 1,
    is_pk => 1, pk_position => 1 },
  { column_name => 'LABEL', data_type => 'varchar2', size => 10, not_null => 0 },
], 'columns: the IDENTITY column is auto-increment, without a default_value, and a key column';

is_deeply own($model->{indexes}), \%INDEXES,
  'indexes: the three made by hand, with their uniqueness and their columns '
. 'in order -- and none of the four Oracle keeps for the primary keys and '
. 'the unique constraints';

is_deeply own($model->{primary_keys}), \%PRIMARY,
  'primary keys: one column each, the one Oracle named among them; none for '
. 'the view';

is_deeply own($model->{views}), {
  T57_LIVE_V => { view_name => 'T57_LIVE_V',
                  definition => 'SELECT ID, CODE FROM T57_LIVE_ITEM WHERE CODE IS NOT NULL',
                  columns => [ qw(ID CODE) ],
                  depends_on => [] },
}, 'views: the definition of the view as Oracle stores it, and the names of its columns in order (karr k65)';

is_deeply own($model->{unique_constraints}), \%UNIQUE,
  'unique constraints: by name, the two-column one with its columns in the '
. 'order of the constraint';

is_deeply own($model->{foreign_keys}), \%FOREIGN,
  'foreign keys: both of the item, once each. The two-column one with its '
. 'columns paired in the order of the constraint and ON DELETE CASCADE, the '
. 'other one deferrable';

# ===================================================================== 2
# The parts, each by itself and handed what DBIO::Oracle::Introspect hands
# it. A part that dies says so in its own test.

sub part {
  my ($class, @args) = @_;
  my $result = eval { $class->fetch($dbh, $SCHEMA, @args) };
  diag "$class: $@" unless $result;
  return $result || {};
}

is_deeply own( part('DBIO::Oracle::Introspect::Tables') ), \%TABLES,
  'Tables: the same four';

{
  my $columns = part('DBIO::Oracle::Introspect::Columns', \%TABLES);

  is_deeply
    { map { $_ => [ map { $_->{column_name} } @{ $columns->{$_} || [] } ] } keys %TABLES },
    {
      ( map { $_ => [ map { $_->{column_name} } @{ $COLUMNS{$_} } ] } keys %COLUMNS ),
      T57_LIVE_IDENT => [ 'ID', 'LABEL' ],
    },
    'Columns: the columns of all four, by name';

  is_deeply $columns->{T57_LIVE_ITEM}, $COLUMNS{T57_LIVE_ITEM},
    'Columns: ... and the item\'s as expected, read on a handle whose '
  . 'LongReadLen is DBI\'s default';
}

is $dbh->{LongReadLen}, 80,
  '(that handle\'s LongReadLen is 80 before and after: it was raised for '
. 'the reading only)';

# (This part reads the indexes of the schema and does not go by the tables
# it is handed, hence the filter: another test's table is in its answer.)
is_deeply own( part('DBIO::Oracle::Introspect::Indexes', \%TABLES) ), \%INDEXES,
  'Indexes: for the four, exactly the three indexes of the item';

is_deeply part('DBIO::Oracle::Introspect::Keys', \%TABLES),
  { primary => \%PRIMARY, unique => \%UNIQUE },
  'Keys: the primary keys and the unique constraints';

is_deeply part('DBIO::Oracle::Introspect::ForeignKeys', \%TABLES), \%FOREIGN,
  'ForeignKeys: the two, and an empty list for every other table';

# ===================================================================== 3
# The normalized contract.

my $contract = eval { {
  keys    => [ grep { /\AT57_LIVE/ } @{ $intro->table_keys } ],
  columns => $intro->table_columns('T57_LIVE_ITEM'),
  info    => $intro->table_columns_info('T57_LIVE_ITEM'),
  pk      => $intro->table_pk_info('T57_LIVE_ITEM'),
  unique  => $intro->table_uniq_info('T57_LIVE_PARENT'),
  fk      => $intro->table_fk_info('T57_LIVE_ITEM'),
  is_view => [ map { $intro->table_is_view($_) ? 1 : 0 } qw(T57_LIVE_ITEM T57_LIVE_V) ],
  view    => $intro->view_definition('T57_LIVE_V'),
} } || {};

diag "the contract methods: $@" if $@;

is_deeply $contract->{keys},
  [ qw(T57_LIVE_IDENT T57_LIVE_ITEM T57_LIVE_PARENT T57_LIVE_V) ],
  'contract: table_keys names the four';

is_deeply $contract->{columns},
  [ qw(ID PARENT_ID P_ID P_TENANT CODE NAME EMAIL PRICE BORN SEEN NOTE) ],
  'contract: table_columns in the order of the table';

is_deeply
  { map { $_ => $contract->{info}{$_} } qw(ID CODE NAME PRICE) },
  {
    ID    => { data_type => 'numeric', is_nullable => 0, is_auto_increment => 1,
               sequence => "$SCHEMA.T57_LIVE_ITEM_SEQ" },
    CODE  => { data_type => 'varchar2', is_nullable => 0, size => 20 },
    NAME  => { data_type => 'varchar2', is_nullable => 1, size => 100,
               default_value => $LONG_DEFAULT },
    PRICE => { data_type => 'numeric', is_nullable => 1, size => [ 10, 2 ],
               default_value => 0 },
  },
  'contract: table_columns_info, with the sequence of the auto-increment '
. 'column';

is_deeply $contract->{pk}, ['ID'], 'contract: table_pk_info';

is_deeply $contract->{unique}, $UNIQUE{T57_LIVE_PARENT},
  'contract: table_uniq_info';

is_deeply $contract->{fk}, [
  {
    local_columns  => [ 'P_TENANT', 'P_ID' ],
    remote_table   => 'T57_LIVE_PARENT', remote_schema => undef,
    remote_columns => [ 'TENANT', 'ID' ],
    attrs => { on_delete => 'CASCADE', on_update => 'NO ACTION', is_deferrable => 0 },
  },
  {
    local_columns  => ['PARENT_ID'],
    remote_table   => 'T57_LIVE_PARENT', remote_schema => undef,
    remote_columns => ['ID'],
    attrs => { on_delete => 'NO ACTION', on_update => 'NO ACTION', is_deferrable => 1 },
  },
], 'contract: table_fk_info, both keys with what a relationship needs';

is_deeply $contract->{is_view}, [ 0, 1 ], 'contract: table_is_view';

like $contract->{view} // 'no definition',
  qr/\ASELECT ID, CODE FROM T57_LIVE_ITEM WHERE CODE IS NOT NULL\z/,
  'contract: view_definition is the text of the view';

# ================================================================ the end

wipe();

is_deeply own_objects(), [], 'nothing of this test is left in the schema';

is_deeply
  admin()->selectall_arrayref(
    qq{SELECT original_name FROM user_recyclebin WHERE UPPER(original_name) $OWN}
  ),
  [],
  '... and nothing in its recycle bin';

is_deeply \@warnings, [], 'no warning on the way';

done_testing;

# Again on a new connection: for a run that died on the way.
END {
  if ($live) {
    local $?;
    undef $admin;
    eval { wipe(); 1 }
      or diag "Could not drop the t57_live_* objects: $@";
  }
}
