use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::SQL::Util ();
use DBIO::Schema;
use DBIO::Oracle::Deploy;
use DBIO::Oracle::Introspect;
use DBIO::Oracle::Diff;
use DBIO::Oracle::Diff::Index;
use DBIO::Oracle::Identifier;

# LIVE (karr k37). What DBIO::Oracle::Diff makes of the tables and indexes of
# a model, applied to a real Oracle schema.
#
# The card was opened for measuring: "Diff::Table::as_sql emits no CREATE
# INDEX, Diff::Index skips target-only tables -> the indexes of a newly
# created table are missing after an upgrade." The measuring showed more:
# the diff did not create the new table either (the orchestrator gave
# Diff::Table the tables and not their columns, "CREATE TABLE X ( )",
# ORA-00931), and a candidate fix in a scratch copy sent a sequence named
# "<schema>.k37_live_item_seq", a foreign key to a table created after it and
# a DROP INDEX behind the DROP TABLE (ORA-01418). The maintainer decided
# (2026-10-25): Diff::Table emits the whole CREATE TABLE inline, as the install
# does it; the indexes of a new table follow, the foreign keys come after every
# CREATE TABLE, and no DROP INDEX is sent behind a DROP TABLE. What is
# pinned here is the result on a server; t/81-diff-new-table.t pins the text.
#
# The models are introspected: A from the schema without the tables, B from
# the schema with them (made by hand: a primary key, a unique constraint,
# a plain, a unique and a two-column index, a foreign key, a sequence and a
# trigger), and one in between, the tables before anybody made an index. The
# model is of the whole schema of the user; what is diffed here is the part of
# it that is this file's own tables.
#
#   1. The models: introspected, and what was expected of them.
#   2. What the diff does for indexes of a table both models have: CREATE
#      INDEX, CREATE UNIQUE INDEX and DROP INDEX run, the indexes Oracle keeps
#      for a primary key and a unique constraint are left alone, and making one
#      of those a second time is refused.
#   3. The drop side: a table that goes takes its indexes along, the diff
#      sends no DROP INDEX after it, and one sent there would fail.
#   4. Tables only the target has: A -> B applied gives B, a second diff is
#      empty; B -> A drops the tables.
#   5. DBIO::Oracle::Deploy->upgrade of a DBIO schema (two tables, a foreign
#      key, an index, a unique constraint, a key from a sequence) over an empty
#      schema and over a schema that has the parent already: the schema is what
#      install makes, the next upgrade finds nothing.
#
# Measured 2026-10-05 against Oracle Database 23ai Free (23.26.3), with
# DBD::Oracle 1.95; 4 and 5 2026-10-25, same server. What this file does NOT
# claim:
#
#   * anything about the diff of primary keys, sequences or triggers of a
#     table both models have. The orchestrator compares tables, columns,
#     indexes, foreign keys and unique constraints (the last two: t/87, the
#     conformance cases of karr k64).
#   * that a unique constraint laid over an index of another name
#     (USING INDEX) comes back as it was. Not made, not measured.
#   * function-based, bitmap, descending, partitioned or invisible indexes.
#     The model has a name, a uniqueness and column names for an index.
#   * the recycle bin: that DROP TABLE without PURGE puts the table there is
#     the server's setting. What landed there is printed as a note in 3 and
#     purged at the end.
#   * the error numbers on another server version. ORA-00955, ORA-01408 and
#     ORA-01418 are what 23.26 says.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_ORA_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_oracle')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_oracle');

alarm 300;   # no handler: an OCI call that hangs ends the run instead of never

my @warnings;
# (core says once per process that Oracle's DDL loop is not atomic, when an
# upgrade runs; t/52-deploy-transactional-ddl.t pins it. Known.)
local $SIG{__WARN__} = sub {
  return if $_[0] =~ /\Anon-transactional DDL on DBIO::Oracle::Deploy\b/;
  push @warnings, $_[0];
  warn $_[0];
};

sub connect_plain {
  return DBI->connect($dsn, $user, $pass, {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
}

# The connection the driver's classes work on ...
my $dbh = connect_plain();

# ... and another one, for setup and for looking at what the server really
# holds: from another session, and through nothing of this driver.
my $admin;
sub admin { $admin ||= connect_plain() }

sub server_rows { admin()->selectall_arrayref(@_) }

my ($SCHEMA) = admin()->selectrow_array('SELECT USER FROM DUAL');

# Anywhere in the name and in any case (it is used on UPPER(name)): what a
# diff makes of a model is not bound to the names the tables were made with
# (the model spells a sequence "<schema>.K37_LIVE_ITEM_SEQ", as the server has
# it; the diff makes "K37_LIVE_ITEM_SEQ", without the schema and the dot).
my $OWN = q{LIKE '%K37\_LIVE%' ESCAPE '\'};

# --------------------------------------------------------------- the tables
#
# Two tables. The item has everything the card names: a primary key and a
# unique constraint -- Oracle keeps an index for each, under the constraint's
# name -- and three indexes somebody made: a plain one, a unique one and one
# over two columns. The foreign key, the sequence and the trigger are there
# for what the diff does not carry (3, 5); the trigger is longer than the 80
# bytes DBI reads of a LONG column unless told otherwise.

my @TABLES = (
  'CREATE TABLE K37_LIVE_PARENT ('
. ' ID NUMBER NOT NULL, CONSTRAINT K37_LIVE_PARENT_PK PRIMARY KEY (ID))',
  'CREATE SEQUENCE K37_LIVE_ITEM_SEQ',
  'CREATE TABLE K37_LIVE_ITEM ('
. ' ID NUMBER NOT NULL, PARENT_ID NUMBER, CODE VARCHAR2(20) NOT NULL,'
. ' NAME VARCHAR2(100), EMAIL VARCHAR2(100),'
. ' CONSTRAINT K37_LIVE_ITEM_PK PRIMARY KEY (ID),'
. ' CONSTRAINT K37_LIVE_ITEM_CODE_UQ UNIQUE (CODE),'
. ' CONSTRAINT K37_LIVE_ITEM_FK FOREIGN KEY (PARENT_ID)'
. ' REFERENCES K37_LIVE_PARENT (ID))',
  'CREATE TRIGGER K37_LIVE_ITEM_BI BEFORE INSERT ON K37_LIVE_ITEM '
. 'FOR EACH ROW BEGIN IF :new.ID IS NULL THEN '
. 'SELECT K37_LIVE_ITEM_SEQ.nextval INTO :new.ID FROM DUAL; END IF; END;',
);

my @INDEXES = (
  'CREATE INDEX K37_LIVE_ITEM_NAME_IX ON K37_LIVE_ITEM (NAME)',
  'CREATE UNIQUE INDEX K37_LIVE_ITEM_EMAIL_UX ON K37_LIVE_ITEM (EMAIL)',
  'CREATE INDEX K37_LIVE_ITEM_PN_IX ON K37_LIVE_ITEM (PARENT_ID, NAME)',
);

# What the data dictionary says about the indexes of the two tables.
my @KEPT_BY_ORACLE = (
  'UNIQUE INDEX K37_LIVE_ITEM_CODE_UQ ON K37_LIVE_ITEM (CODE)',
  'UNIQUE INDEX K37_LIVE_ITEM_PK ON K37_LIVE_ITEM (ID)',
  'UNIQUE INDEX K37_LIVE_PARENT_PK ON K37_LIVE_PARENT (ID)',
);

my @MADE_BY_HAND = (
  'UNIQUE INDEX K37_LIVE_ITEM_EMAIL_UX ON K37_LIVE_ITEM (EMAIL)',
  'INDEX K37_LIVE_ITEM_NAME_IX ON K37_LIVE_ITEM (NAME)',
  'INDEX K37_LIVE_ITEM_PN_IX ON K37_LIVE_ITEM (PARENT_ID, NAME)',
);

# All six, in the order of their names: the way indexes_held lists them.
my @ALL_SIX = map { $_->[1] } sort { $a->[0] cmp $b->[0] }
  map { [ ( /INDEX (\S+)/ )[0], $_ ] } @KEPT_BY_ORACLE, @MADE_BY_HAND;

# --------------------------------------------------------------- the models
#
# What the introspection is expected to return for the tables above, in the
# shape DBIO::Oracle::Introspect documents. Section 1 holds the introspected
# models against these; everything after it works with the introspected
# ones.

my %EXPECT_A = map { $_ => {} } qw(
  tables columns indexes foreign_keys primary_keys unique_constraints views
);

my %EXPECT_B = (
  views => {},
  tables => {
    map { $_ => { table_name => $_, kind => 'table', schema => $SCHEMA } }
      qw(K37_LIVE_ITEM K37_LIVE_PARENT)
  },
  columns => {
    K37_LIVE_ITEM => [
      { column_name => 'ID', data_type => 'numeric', not_null => 1,
        is_auto_increment => 1, sequence => "$SCHEMA.K37_LIVE_ITEM_SEQ",
        is_pk => 1, pk_position => 1 },
      { column_name => 'PARENT_ID', data_type => 'numeric', not_null => 0 },
      { column_name => 'CODE',  data_type => 'varchar2', size => 20,  not_null => 1 },
      { column_name => 'NAME',  data_type => 'varchar2', size => 100, not_null => 0 },
      { column_name => 'EMAIL', data_type => 'varchar2', size => 100, not_null => 0 },
    ],
    K37_LIVE_PARENT => [
      { column_name => 'ID', data_type => 'numeric', not_null => 1,
        is_pk => 1, pk_position => 1 },
    ],
  },
  indexes => {
    K37_LIVE_ITEM => {
      K37_LIVE_ITEM_EMAIL_UX => {
        index_name => 'K37_LIVE_ITEM_EMAIL_UX', is_unique => 1,
        columns    => ['EMAIL'],
      },
      K37_LIVE_ITEM_NAME_IX => {
        index_name => 'K37_LIVE_ITEM_NAME_IX', is_unique => 0,
        columns    => ['NAME'],
      },
      K37_LIVE_ITEM_PN_IX => {
        index_name => 'K37_LIVE_ITEM_PN_IX', is_unique => 0,
        columns    => [ 'PARENT_ID', 'NAME' ],
      },
    },
    K37_LIVE_PARENT => {},
  },
  foreign_keys => {
    K37_LIVE_ITEM => [ {
      constraint_name      => 'K37_LIVE_ITEM_FK',
      from_table   => 'K37_LIVE_ITEM',   from_columns => ['PARENT_ID'],
      to_table     => 'K37_LIVE_PARENT', to_columns   => ['ID'],
      on_update    => 'NO ACTION',       on_delete    => 'NO ACTION',
      is_deferrable => 0,
    } ],
    K37_LIVE_PARENT => [],
  },
  primary_keys => {
    K37_LIVE_ITEM   => ['ID'],
    K37_LIVE_PARENT => ['ID'],
  },
  unique_constraints => {
    K37_LIVE_ITEM   => [ [ K37_LIVE_ITEM_CODE_UQ => ['CODE'] ] ],
    K37_LIVE_PARENT => [],
  },
);

# B as it is before somebody made the three indexes.
my %EXPECT_BARE
  = ( %EXPECT_B, indexes => { K37_LIVE_ITEM => {}, K37_LIVE_PARENT => {} } );

# The model of the schema as it is now, reduced to this file's own tables:
# every section with the entries whose key is one of them.
sub introspect {
  my $model = DBIO::Oracle::Introspect->new(dbh => $dbh)->model;

  return { map {
    my $section = $model->{$_};
    $_ => { map { $_ => $section->{$_} } grep { /K37_LIVE/i } keys %$section };
  } keys %$model };
}

# ------------------------------------------------- looking at the server

# Everything of this test the data dictionary holds, one line each: tables
# with their columns, primary, unique and foreign keys, indexes, sequences,
# triggers.
sub snapshot {
  my @is;

  my (%columns, @tables);
  for my $row (@{ server_rows(qq{
    SELECT table_name, column_name, data_type, char_length, nullable
    FROM user_tab_columns WHERE UPPER(table_name) $OWN
    ORDER BY table_name, column_id
  }) }) {
    my ($table, $column, $type, $chars, $nullable) = @$row;
    push @tables, $table unless $columns{$table};
    push @{ $columns{$table} }, join ' ', $column,
      ( $chars ? "$type($chars)" : $type ), ( $nullable eq 'N' ? 'NOT NULL' : () );
  }
  push @is, map { "TABLE $_ (" . join(', ', @{ $columns{$_} }) . ')' } @tables;

  my (%key, @keys);
  for my $row (@{ server_rows(qq{
    SELECT c.constraint_type, c.table_name, c.constraint_name, cc.column_name, c.generated
    FROM user_constraints c
    JOIN user_cons_columns cc ON cc.constraint_name = c.constraint_name
    WHERE c.constraint_type IN ('P', 'U', 'R') AND UPPER(c.table_name) $OWN
    ORDER BY c.table_name, c.constraint_type, c.constraint_name, cc.position
  }) }) {
    my ($type, $table, $name, $column, $generated) = @$row;
    $name = '(system)' if $generated eq 'GENERATED NAME';
    my $kind = { P => 'PRIMARY KEY', U => 'UNIQUE', R => 'FOREIGN KEY' }->{$type};
    my $id = "$kind $name ON $table";
    push @keys, $id unless $key{$id};
    push @{ $key{$id} }, $column;
  }
  push @is, map { "$_ (" . join(', ', @{ $key{$_} }) . ')' } @keys;

  my (%index, @indexes);
  for my $row (@{ server_rows(qq{
    SELECT i.table_name, i.index_name, i.uniqueness, c.column_name, i.generated
    FROM user_indexes i
    JOIN user_ind_columns c ON c.index_name = i.index_name
    WHERE UPPER(i.table_name) $OWN
    ORDER BY i.index_name, c.column_position
  }) }) {
    my ($table, $name, $uniqueness, $column, $generated) = @$row;
    $name = '(system)' if $generated eq 'Y';
    my $id = ( $uniqueness eq 'UNIQUE' ? 'UNIQUE ' : '' ) . "INDEX $name ON $table";
    push @indexes, $id unless $index{$id};
    push @{ $index{$id} }, $column;
  }
  push @is, map { "$_ (" . join(', ', @{ $index{$_} }) . ')' } @indexes;

  push @is, map { "SEQUENCE $_->[0]" } @{ server_rows(qq{
    SELECT sequence_name FROM user_sequences
    WHERE UPPER(sequence_name) $OWN ORDER BY sequence_name
  }) };

  push @is, map { "TRIGGER $_->[0] ON $_->[1]" } @{ server_rows(qq{
    SELECT trigger_name, table_name FROM user_triggers
    WHERE UPPER(table_name) $OWN ORDER BY trigger_name
  }) };

  return \@is;
}

sub indexes_held { [ grep { /\A(?:UNIQUE )?INDEX / } @{ snapshot() } ] }

# The snapshot in one fixed order, for comparing two schemas that were made in
# another order (the names the server gave are '(system)', not sorted by it).
sub normal { [ sort @{ snapshot() } ] }

sub in_recycle_bin {
  return server_rows(qq{
    SELECT type, original_name, object_name FROM user_recyclebin
    WHERE UPPER(original_name) $OWN ORDER BY type, original_name
  });
}

# The tables with PURGE, and what an earlier DROP TABLE without it -- the
# diff's -- has put into the recycle bin.
sub wipe {
  my $dbh = admin();
  $dbh->do(qq{DROP TABLE "$_->[0]" CASCADE CONSTRAINTS PURGE})
    for @{ server_rows(qq{SELECT table_name FROM user_tables WHERE UPPER(table_name) $OWN}) };
  $dbh->do(qq{DROP SEQUENCE "$_->[0]"})
    for @{ server_rows(qq{SELECT sequence_name FROM user_sequences WHERE UPPER(sequence_name) $OWN}) };
  $dbh->do(qq{PURGE TABLE "$_->[2]"})
    for grep { $_->[0] eq 'TABLE' } @{ in_recycle_bin() };
}

sub make { admin()->do($_) for @_ }

# apply($sql) runs a diff's SQL the way DBIO::Deploy::Base::_execute_ddl
# splits it, each statement by itself, and says how each one went: "ok" or
# the ORA number. It goes on after an error, so that every statement is seen.
# The splitter reads the dialect oracle, as the storage declares it, so a
# trigger keeps the semicolon after its END.
sub apply {
  my ($sql) = @_;

  return [ map {
    my $statement = $_;
    my $went = eval { admin()->do($statement); 1 }
      ? 'ok' : ( $@ =~ /(ORA-\d+)/ )[0] // "no ORA number: $@";
    ( my $short = $statement ) =~ s/\s+/ /g;
    "$short -- $went";
  } DBIO::SQL::Util::_split_statements($sql, { dialect => 'oracle' }) ];
}

sub diff_of {
  my ($source, $target) = @_;
  return DBIO::Oracle::Diff->new(source => $source, target => $target);
}

sub summary_of { [ split /\n/, $_[0]->summary ] }

# Deploy->upgrade (5) works on the whole schema of the user, not on the tables
# of this test: beside somebody else's tables it would drop them.
{
  my @foreign = map { $_->[0] } @{ server_rows(qq{
    SELECT table_name FROM user_tables
    WHERE table_name NOT LIKE 'BIN\$%' AND UPPER(table_name) NOT $OWN
    UNION ALL
    SELECT view_name FROM user_views
  }) };

  plan skip_all => "The schema of $user must hold no tables or views but "
    . "this test's own (k37_live_*); found: @foreign"
    if @foreign;
}

my $live = 1;   # past every skip_all: from here on there is something to drop

wipe();         # what a run that died before its END block may have left

is_deeply snapshot(), [], '(the schema holds nothing of this test to begin with)';

# ===================================================================== 1
# The models, introspected.

my $A = introspect();

is_deeply $A, \%EXPECT_A,
  'A: the model of the schema without the tables holds nothing of them';

make(@TABLES);

my $B_BARE = introspect();

is_deeply $B_BARE, \%EXPECT_BARE,
  'the model of the tables before anybody made an index: both tables with '
. 'their columns, the sequence behind the trigger, the keys and the '
. 'foreign key -- and no index, though Oracle keeps three for the primary '
. 'keys and the unique constraint';

make(@INDEXES);

my $B    = introspect();
my $MADE = snapshot();

is_deeply indexes_held(), \@ALL_SIX,
  '(the tables are made: three indexes Oracle keeps for the keys, three '
. 'made by hand)';

is_deeply $B->{indexes}, $EXPECT_B{indexes},
  'B: the model lists the three indexes made by hand, with their '
. 'uniqueness and their columns in order, and not the ones Oracle keeps '
. 'for the keys';

is_deeply $B, \%EXPECT_B,
  'B: ... and everything else about the two tables as it was made';

# ===================================================================== 2
# Indexes of a table both models have: the part of the diff that works.

wipe();
make(@TABLES);

is_deeply indexes_held(), \@KEPT_BY_ORACLE,
  '(the tables once more, without the indexes made by hand)';

{
  my $diff = diff_of($B_BARE, $B);

  is_deeply summary_of($diff), [
    '  +index: K37_LIVE_ITEM_EMAIL_UX on K37_LIVE_ITEM',
    '  +index: K37_LIVE_ITEM_NAME_IX on K37_LIVE_ITEM',
    '  +index: K37_LIVE_ITEM_PN_IX on K37_LIVE_ITEM',
  ], 'IS: for a table both models have, the diff creates the indexes only '
   . 'the target has';

  is_deeply apply($diff->as_sql), [
    'CREATE UNIQUE INDEX "K37_LIVE_ITEM_EMAIL_UX" ON "K37_LIVE_ITEM" ("EMAIL") -- ok',
    'CREATE INDEX "K37_LIVE_ITEM_NAME_IX" ON "K37_LIVE_ITEM" ("NAME") -- ok',
    'CREATE INDEX "K37_LIVE_ITEM_PN_IX" ON "K37_LIVE_ITEM" ("PARENT_ID", "NAME") -- ok',
  ], 'IS: ... and Oracle takes all three statements';

  is_deeply snapshot(), $MADE,
    'IS: the schema is what was made by hand: the indexes are there, with '
  . 'their uniqueness and their columns in order, and nothing else moved';
}

# What a correction for new tables must not send: an index for what Oracle
# already keeps one for. The model leaves those out (1: an index named like
# a primary or unique constraint is not listed), so the diff has nothing to
# send here -- these two are made up.

{
  my @twice = map { DBIO::Oracle::Diff::Index->new(
    action => 'create', table_name => 'K37_LIVE_ITEM', %$_,
  )->as_sql } (
    { index_name => 'K37_LIVE_ITEM_ID_IX',
      index_info => { is_unique => 0, columns => ['ID'] } },
    { index_name => 'K37_LIVE_ITEM_CODE_UQ',
      index_info => { is_unique => 1, columns => ['CODE'] } },
  );

  is_deeply apply(join "\n", @twice), [
    'CREATE INDEX "K37_LIVE_ITEM_ID_IX" ON "K37_LIVE_ITEM" ("ID") -- ORA-01408',
    'CREATE UNIQUE INDEX "K37_LIVE_ITEM_CODE_UQ" ON "K37_LIVE_ITEM" ("CODE") -- ORA-00955',
  ], 'IS: an index over the columns of the primary key is refused (the '
   . 'column list is indexed), and so is one under the name of the unique '
   . 'constraint (the name is taken)';
}

{
  my $diff = diff_of($B, $B_BARE);

  is_deeply apply($diff->as_sql), [
    'DROP INDEX "K37_LIVE_ITEM_EMAIL_UX" -- ok',
    'DROP INDEX "K37_LIVE_ITEM_NAME_IX" -- ok',
    'DROP INDEX "K37_LIVE_ITEM_PN_IX" -- ok',
  ], 'IS: the other way round the diff drops them, and Oracle takes that';

  is_deeply indexes_held(), \@KEPT_BY_ORACLE,
    'IS: ... the indexes of the keys stay';
}

# ===================================================================== 3
# The drop side: both tables go.

make(@INDEXES);

{
  my $diff = diff_of($B, $A);

  is_deeply summary_of($diff), [
    '- table: K37_LIVE_ITEM',
    '- table: K37_LIVE_PARENT',
  ], 'IS: for tables only the source has, the diff drops the tables and '
   . 'sends nothing for their indexes';

  is_deeply apply($diff->as_sql), [
    'DROP TABLE "K37_LIVE_ITEM" CASCADE CONSTRAINTS -- ok',
    'DROP SEQUENCE "K37_LIVE_ITEM_SEQ" -- ok',
    'DROP TABLE "K37_LIVE_PARENT" CASCADE CONSTRAINTS -- ok',
  ], 'IS: ... and Oracle takes the statements, the sequence of the item '
   . 'table too (karr k61)';

  is_deeply snapshot(), [],
    'IS: the tables are gone with their indexes, keys and trigger, and the '
  . 'sequence with them: the diff dropped it (karr k61)';

  # What walking the dropped tables too (scope "all" of
  # DBIO::Diff::Op::diff_nested as it stands, the way another driver
  # does it) would add behind the DROP TABLE.
  my $drop_index = DBIO::Oracle::Diff::Index->new(
    action     => 'drop',
    table_name => 'K37_LIVE_ITEM',
    index_name => 'K37_LIVE_ITEM_NAME_IX',
    index_info => $B->{indexes}{K37_LIVE_ITEM}{K37_LIVE_ITEM_NAME_IX},
  );

  is_deeply apply($drop_index->as_sql),
    [ 'DROP INDEX "K37_LIVE_ITEM_NAME_IX" -- ORA-01418' ],
    'IS: a DROP INDEX after the DROP TABLE fails -- the index went with '
  . 'the table. A walk over new tables must not bring one over dropped '
  . 'tables with it';

  note 'in the recycle bin after the diff\'s DROP TABLE (no PURGE): '
     . join(', ', map { "$_->[0] $_->[1]" } @{ in_recycle_bin() });
}

# ===================================================================== 4
# Tables only the target has (karr k37): A -> B, applied to a server.

wipe();

# The way a caller comes by such a diff is DBIO::Oracle::Deploy: diff holds
# the live schema against the desired one, upgrade applies what comes out.
# This schema declares no source, so the desired state is empty and so is the
# live schema after the wipe: nothing to diff.
{
  package T::K37::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
}

{
  my $deploy = DBIO::Oracle::Deploy->new(
    schema => T::K37::Schema->connect($dsn, $user, $pass),
  );

  my $diff = eval { $deploy->diff };
  is "$@", '', 'DBIO::Oracle::Deploy->diff runs (karr k36)';
  ok $diff && !$diff->has_changes, '... and finds nothing between two empty schemas';

  my $upgraded = eval { $deploy->upgrade };
  is "$@", '', 'upgrade runs too ...';
  ok !$upgraded, '... and has nothing to apply';
}

# B holds a foreign key. The diff creates it with its table.
{
  my $new = diff_of($A, $B);

  is_deeply summary_of($new), [
    '+ table: K37_LIVE_ITEM',
    '+ table: K37_LIVE_PARENT',
    '  +index: K37_LIVE_ITEM_EMAIL_UX on K37_LIVE_ITEM',
    '  +index: K37_LIVE_ITEM_NAME_IX on K37_LIVE_ITEM',
    '  +index: K37_LIVE_ITEM_PN_IX on K37_LIVE_ITEM',
    '  +foreign key: K37_LIVE_ITEM_FK on K37_LIVE_ITEM',
  ], 'IS: for tables only the target has, the diff creates the tables, then '
   . 'their indexes, then the foreign key';

  my $went = apply($new->as_sql);

  is scalar(@$went), 8,
    'IS: ... eight statements: two tables, the sequence and the trigger, three '
  . 'indexes, the foreign key';
  is_deeply [ grep { !/ -- ok\z/ } @$went ], [],
    'IS: ... and Oracle takes every one of them (no ORA-00931 any more)';

  # A -> B gives B: everything the model holds, as it was made by hand.
  my $after = introspect();

  is_deeply $after, $B,
    'IS: A -> B gives B: the model introspected afterwards is B -- columns, '
  . 'primary keys, the unique constraint, indexes, the foreign key, the sequence';

  ok !diff_of($after, $B)->has_changes && !diff_of($B, $after)->has_changes,
    'IS: ... and a second diff, either way, is empty';

  # What the model does not hold, but the install writes: the names of the
  # primary keys and the trigger differ from the ones made by hand (the model
  # carries neither), the rest is the same.
  is_deeply [ grep { !/\(system\)|_PK / } @{ indexes_held() } ],
    [ grep { !/_PK / } @ALL_SIX ],
    'IS: ... with the unique constraint, and the plain and the unique indexes '
  . 'there';

  is_deeply [ grep { /\A(?:SEQUENCE|TRIGGER) / } @{ snapshot() } ], [
    'SEQUENCE K37_LIVE_ITEM_SEQ',
    'TRIGGER K37_LIVE_ITEM_ID_trg ON K37_LIVE_ITEM',
  ], 'IS: ... the sequence of the model (spelled as the server has it) and the '
   . 'trigger the install would have written, named after table and column';

  is_deeply server_rows(q{
    SELECT object_name, status FROM user_objects
    WHERE object_type = 'TRIGGER' AND object_name LIKE 'K37\_LIVE%' ESCAPE '\'
  }), [ [ 'K37_LIVE_ITEM_ID_trg', 'VALID' ] ],
    'IS: ... the trigger is valid';

  admin()->do(q{INSERT INTO "K37_LIVE_ITEM" ("CODE") VALUES ('first')});
  admin()->do(q{INSERT INTO "K37_LIVE_ITEM" ("CODE") VALUES ('second')});
  is_deeply server_rows(q{SELECT "ID" FROM "K37_LIVE_ITEM" ORDER BY "ID"}), [ [1], [2] ],
    'IS: ... and it fills the key from the sequence';
}

# The way back: both tables go, with no DROP INDEX after them.
{
  my $before = introspect();
  my $diff   = diff_of($before, $A);

  is_deeply apply($diff->as_sql), [
    'DROP TABLE "K37_LIVE_ITEM" CASCADE CONSTRAINTS -- ok',
    'DROP SEQUENCE "K37_LIVE_ITEM_SEQ" -- ok',
    'DROP TABLE "K37_LIVE_PARENT" CASCADE CONSTRAINTS -- ok',
  ], 'IS: B -> A drops both tables and the sequence, and Oracle takes the statements';

  is_deeply snapshot(), [],
    'IS: ... nothing of the dropped tables stays, the sequence neither (karr k61)';
}

# ===================================================================== 5
# Deploy->upgrade: the desired state is a DBIO schema with two tables, a
# foreign key between them, an index, a unique constraint and a key from a
# sequence. An upgrade of an empty schema makes what install makes, and the
# next upgrade finds nothing to do.

{
  package T::K37::Target::Parent;
  use base 'DBIO::Core';
  __PACKAGE__->table('k37_live_parent');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K37::Target::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('k37_live_item');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer' },
    code      => { data_type => 'varchar', size => 20 },
    name      => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(['code']);
  __PACKAGE__->belongs_to(parent => 'T::K37::Target::Parent', 'parent_id',
    { on_delete => 'CASCADE', is_deferrable => 1 });
  __PACKAGE__->result_source_instance->add_index_declaration({
    name => 'k37_live_item_name_ix', columns => ['name'],
  });
}

{
  package T::K37::Target;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Parent => 'T::K37::Target::Parent');
  __PACKAGE__->register_class(Item   => 'T::K37::Target::Item');
}

# the older state of the second run: the parent alone
{
  package T::K37::Old;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Parent => 'T::K37::Target::Parent');
}

sub deploy_of { DBIO::Oracle::Deploy->new(schema => $_[0]->connect($dsn, $user, $pass)) }

sub temp_users {
  return [ map { $_->[0] } @{ server_rows(
    q{SELECT username FROM all_users WHERE username LIKE 'DBIO\_TMP\_%' ESCAPE '\'}
  ) } ];
}

wipe();
deploy_of('T::K37::Target')->install;
my $INSTALLED = normal();

is_deeply [ grep { /\A(?:FOREIGN KEY|SEQUENCE|TRIGGER|UNIQUE k)/ } @$INSTALLED ], [
  'FOREIGN KEY ' . DBIO::Oracle::Identifier::shorten('fk_k37_live_item_parent_id_k37_live_parent')
    . ' ON k37_live_item (parent_id)',
  'SEQUENCE k37_live_item_id_seq',
  'SEQUENCE k37_live_parent_id_seq',
  'TRIGGER k37_live_item_id_trg ON k37_live_item',
  'TRIGGER k37_live_parent_id_trg ON k37_live_parent',
  'UNIQUE k37_live_item_code ON k37_live_item (code)',
], '(what install makes of the desired schema: the state an upgrade has to reach)';

for my $case (
  [ 'an empty schema',      undef ],
  [ 'a schema with the parent only', 'T::K37::Old' ],
) {
  my ($what, $old) = @$case;

  wipe();
  deploy_of($old)->install if $old;

  my $deploy = deploy_of('T::K37::Target');
  my $diff   = eval { $deploy->diff };
  is "$@", '', "diff over $what lives";
  ok $diff && $diff->has_changes, '... and finds the tables the schema lacks';
  unlike $diff->as_sql, qr/\(\s*\)/, '... none of its CREATE TABLE is empty';
  is_deeply temp_users(), [], '... and no temporary user is left';

  my $first = eval { $deploy->upgrade };
  is "$@", '', "upgrade of $what lives";
  isa_ok $first, 'DBIO::Oracle::Diff', '... and returns the diff it applied';

  is_deeply normal(), $INSTALLED,
    '... the schema is what install makes of the desired one: tables, keys, '
  . 'the unique constraint, the index, the foreign key, the sequences, the triggers';
  is_deeply temp_users(), [], '... no temporary user is left';

  my $second = eval { $deploy->upgrade };
  is "$@", '', 'a second upgrade lives';
  is $second, undef, '... and finds nothing left to do: the second diff is empty';
  is_deeply normal(), $INSTALLED, '... and the schema is as it was';

  # the foreign key is the one of the install, and enforced
  my $enforced = eval {
    admin()->do(q{INSERT INTO "k37_live_item" ("parent_id", "code") VALUES (4711, 'x')}); 1
  } ? 'accepted' : ( $@ =~ /(ORA-\d+)/ )[0];
  is $enforced, 'ORA-02291', '... the foreign key is enforced';
}

# ================================================================ the end

wipe();

is_deeply snapshot(), [], 'nothing of this test is left in the schema';

is_deeply in_recycle_bin(), [], '... and nothing in its recycle bin';

is_deeply \@warnings, [],
  'no warning on the way';

done_testing;

# Again on a new connection: for a run that died on the way.
END {
  if ($live) {
    local $?;
    undef $admin;
    eval { wipe(); 1 }
      or diag "Could not drop the k37_live_* objects: $@";
  }
}
