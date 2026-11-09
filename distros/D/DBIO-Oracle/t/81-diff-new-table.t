use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use DBIO::SQL::Util ();
use DBIO::Oracle::Diff;

# OFFLINE (karr k37). A table only the target model has is created whole by
# DBIO::Oracle::Diff: its columns, primary key, unique constraints, sequence
# and trigger in one CREATE TABLE group, then its indexes, then its foreign
# keys -- written the way DBIO::Oracle::DDL writes the install, so that the
# table the diff makes is the table the install makes (every name quoted as the
# model spells it). t/55-diff-index-live.t runs the same against a server.
#
# The order of a diff: CREATE TABLE of every new table, DROP TABLE, columns,
# indexes (also those of the new tables), the foreign keys of the new tables.
# A foreign key of a new table may point to a table that comes after it, so
# keys come after every CREATE TABLE. No DROP INDEX is sent behind a DROP
# TABLE: the index went with the table, and Oracle refuses it (ORA-01418).

no warnings 'redefine';
local *DBI::connect = sub { die 'the diff must not connect' };

my $empty = {
  tables => {}, columns => {}, indexes => {}, foreign_keys => {},
  primary_keys => {}, unique_constraints => {},
};

sub statements { [ DBIO::SQL::Util::_split_statements($_[0]->as_sql) ] }

# An existing table, in both models; the target gives it an index.
my $keep_table = { table_name => 'keep', kind => 'table', schema => 'U' };
my @keep_cols  = ( { column_name => 'x', data_type => 'varchar2', size => 10, not_null => 0 } );

my $with = {
  tables => {
    keep   => $keep_table,
    item   => { table_name => 'item',   kind => 'table', schema => 'U' },
    parent => { table_name => 'parent', kind => 'table', schema => 'U' },
  },
  columns => {
    keep => [ @keep_cols ],
    item => [
      { column_name => 'id',        data_type => 'numeric', not_null => 1, is_pk => 1, pk_position => 1 },
      { column_name => 'parent_id', data_type => 'numeric', not_null => 0 },
      { column_name => 'code',      data_type => 'varchar2', size => 20, not_null => 1 },
      { column_name => 'email',     data_type => 'varchar2', size => 100, not_null => 0 },
    ],
    parent => [
      { column_name => 'id', data_type => 'numeric', not_null => 1, is_pk => 1, pk_position => 1,
        is_auto_increment => 1, sequence => 'U.parent_id_seq' },
      { column_name => 'name', data_type => 'varchar2', size => 100, not_null => 0 },
    ],
  },
  indexes => {
    keep => { keep_x_ix => { index_name => 'keep_x_ix', is_unique => 0, columns => ['x'] } },
    item => {
      item_email_ux  => { index_name => 'item_email_ux',  is_unique => 1, columns => ['email'] },
      item_parent_ix => { index_name => 'item_parent_ix', is_unique => 0, columns => ['parent_id'] },
    },
    parent => {},
  },
  foreign_keys => {
    keep => [],
    item => [ {
      constraint_name => 'fk_item_parent_id_parent', from_table => 'item',
      from_columns => ['parent_id'], to_table => 'parent', to_columns => ['id'],
      on_update => 'NO ACTION', on_delete => 'CASCADE', is_deferrable => 1,
    } ],
    parent => [],
  },
  primary_keys       => { keep => [], item => ['id'], parent => ['id'] },
  unique_constraints => { keep => [], item => [ [ item_code_uq => ['code'] ] ], parent => [] },
};

# the same model without the two new tables
my $without = {
  tables  => { keep => $keep_table },
  columns => { keep => [ @keep_cols ] },
  indexes => { keep => {} },
  foreign_keys => { keep => [] },
  primary_keys => { keep => [] },
  unique_constraints => { keep => [] },
};

my @expect_create = (
  qq{CREATE TABLE "item" (\n}
. qq{  "id" NUMBER NOT NULL,\n}
. qq{  "parent_id" NUMBER,\n}
. qq{  "code" VARCHAR2(20) NOT NULL,\n}
. qq{  "email" VARCHAR2(100),\n}
. qq{  PRIMARY KEY ("id"),\n}
. qq{  CONSTRAINT "item_code_uq" UNIQUE ("code")\n}
. qq{)},

  qq{CREATE TABLE "parent" (\n}
. qq{  "id" NUMBER NOT NULL,\n}
. qq{  "name" VARCHAR2(100),\n}
. qq{  PRIMARY KEY ("id")\n}
. qq{)},
  qq{CREATE SEQUENCE "parent_id_seq"},
  qq{CREATE OR REPLACE TRIGGER "parent_id_trg"\n}
. qq{BEFORE INSERT ON "parent" FOR EACH ROW WHEN (new."id" IS NULL)\n}
. qq{BEGIN\n}
. qq{  SELECT "parent_id_seq".NEXTVAL INTO :new."id" FROM DUAL;\n}
. qq{END},
);

# the index of the table both models have first, then those of the new ones
my @expect_index = (
  q{CREATE INDEX "keep_x_ix" ON "keep" ("x")},
  q{CREATE UNIQUE INDEX "item_email_ux" ON "item" ("email")},
  q{CREATE INDEX "item_parent_ix" ON "item" ("parent_id")},
);

my @expect_fk = (
  q{ALTER TABLE "item" ADD CONSTRAINT "fk_item_parent_id_parent" }
. q{FOREIGN KEY ("parent_id") REFERENCES "parent" ("id") ON DELETE CASCADE DEFERRABLE},
);

# ---------------------------------------------------------------- 1 create

{
  my $diff = DBIO::Oracle::Diff->new(source => $without, target => $with);

  is_deeply statements($diff), [ @expect_create, @expect_index, @expect_fk ],
    'a table only the target has: CREATE TABLE with columns, key and '
  . 'unique constraint, sequence and trigger, then the indexes (also those of '
  . 'the new tables), then the foreign keys';

  my $sql = join "\n", @{ statements($diff) };
  my $last_table = rindex $sql, 'CREATE TABLE';
  my $first_idx  = index  $sql, 'CREATE UNIQUE INDEX';
  my $first_fk   = index  $sql, 'ALTER TABLE';
  ok $last_table < $first_idx && $first_idx < $first_fk,
    'every CREATE TABLE precedes the first index, the first index precedes '
  . 'the first foreign key';

  unlike $diff->as_sql, qr/\(\s*\)/, 'no CREATE TABLE X ( ) any more';

  is_deeply [ split /\n/, $diff->summary ], [
    '+ table: item',
    '+ table: parent',
    '  +index: keep_x_ix on keep',
    '  +index: item_email_ux on item',
    '  +index: item_parent_ix on item',
    '  +foreign key: fk_item_parent_id_parent on item',
  ], 'the summary names tables, indexes and the foreign key';
}

# --------------------------------------------------------------- 2 no change

{
  my $diff = DBIO::Oracle::Diff->new(source => $with, target => $with);
  ok !$diff->has_changes, 'a model against itself: no change, new-table rules or not';
}

# ----------------------------------------------------------------- 3 drop

{
  my $target = { %$without,
    indexes => { keep => {} } };
  my $diff = DBIO::Oracle::Diff->new(source => $with, target => $target);

  is_deeply statements($diff), [
    'DROP TABLE "item" CASCADE CONSTRAINTS',
    'DROP TABLE "parent" CASCADE CONSTRAINTS',
    'DROP SEQUENCE "parent_id_seq"',
    'DROP INDEX "keep_x_ix"',
  ], 'tables only the source has are dropped with CASCADE CONSTRAINTS, with the sequence of the install (karr k61); the '
   . 'DROP INDEX of the table that stays follows, and none is sent for the '
   . 'indexes of the dropped tables (ORA-01418)';
}

# ------------------------------------------------ 4 drop and create together

{
  my $old = { tables => { gone => { table_name => 'gone' } },
    columns => { gone => [ { column_name => 'a', data_type => 'numeric' } ] },
    indexes => { gone => { gone_a_ix => { index_name => 'gone_a_ix', is_unique => 0, columns => ['a'] } } } };
  my $new = { tables => { fresh => { table_name => 'fresh' } },
    columns => { fresh => [ { column_name => 'a', data_type => 'numeric' } ] },
    indexes => { fresh => { fresh_a_ix => { index_name => 'fresh_a_ix', is_unique => 0, columns => ['a'] } } } };

  is_deeply statements(DBIO::Oracle::Diff->new(source => $old, target => $new)), [
    qq{CREATE TABLE "fresh" (\n  "a" NUMBER\n)},
    'DROP TABLE "gone" CASCADE CONSTRAINTS',
    'CREATE INDEX "fresh_a_ix" ON "fresh" ("a")',
  ], 'one table replaced by another: the new one is created, the old one '
   . 'dropped without a DROP INDEX behind it, the index of the new one created';
}

# ----------------------------------------------- 5 a key to an existing table

{
  my $src = { %$without };
  my $tgt = {
    tables  => { %{ $without->{tables} }, child => { table_name => 'child' } },
    columns => { %{ $without->{columns} }, child => [
      { column_name => 'x', data_type => 'varchar2', size => 10, not_null => 0 } ] },
    indexes => { keep => {}, child => {} },
    foreign_keys => { keep => [], child => [ {
      constraint_name => 'fk_child_x_keep', from_columns => ['x'],
      to_table => 'keep', to_columns => ['x'], on_delete => 'NO ACTION', is_deferrable => 0,
    } ] },
  };
  is_deeply statements(DBIO::Oracle::Diff->new(source => $src, target => $tgt)), [
    qq{CREATE TABLE "child" (\n  "x" VARCHAR2(10)\n)},
    q{ALTER TABLE "child" ADD CONSTRAINT "fk_child_x_keep" FOREIGN KEY ("x") REFERENCES "keep" ("x")},
  ], 'a new table with a foreign key to an existing one: the key is created '
   . '(a NO ACTION key writes no ON DELETE, a plain one no DEFERRABLE)';

  # a name the model does not carry is made the way the install makes it
  delete $tgt->{foreign_keys}{child}[0]{constraint_name};
  like(DBIO::Oracle::Diff->new(source => $src, target => $tgt)->as_sql,
    qr/ADD CONSTRAINT "fk_child_x_keep" FOREIGN KEY/,
    'a foreign key without a name gets the name of the install, fk_<table>_<columns>_<target>');
}

# -------------------------------------------- 6 a key of a table both have

{
  my $changed = { %$with, foreign_keys => { %{ $with->{foreign_keys} }, item => [] } };
  is_deeply statements(DBIO::Oracle::Diff->new(source => $with, target => $changed)),
    [ q{ALTER TABLE "item" DROP CONSTRAINT "fk_item_parent_id_parent"} ],
    'the foreign key of a table both models have, gone in the target, is dropped (karr k64, t/80)';
}

# --------------------------------------------------- 7 what the model cannot say

{
  my $identity = { tables => { t => { table_name => 't', schema => 'U' } },
    columns => { t => [ { column_name => 'id', data_type => 'numeric', not_null => 1,
      is_auto_increment => 1 } ] }, indexes => { t => {} } };

  throws_ok { DBIO::Oracle::Diff->new(source => $empty, target => $identity)->operations }
    'DBIO::Exception','an auto-increment column without a sequence is refused ...';
  throws_ok { DBIO::Oracle::Diff->new(source => $empty, target => $identity)->operations }
    qr/table 't'.*column 'id'.*IDENTITY/s, '... naming table and column';

  my $foreign = { tables => { t => { table_name => 't', schema => 'U' } },
    columns => { t => [ { column_name => 'id', data_type => 'numeric', not_null => 1,
      is_auto_increment => 1, sequence => 'OTHER.s_seq' } ] }, indexes => { t => {} } };
  throws_ok { DBIO::Oracle::Diff->new(source => $empty, target => $foreign)->operations }
    qr/table 't'.*sequence.*OTHER/s,
    'a sequence of another schema than the table is refused';

  my $bare = { tables => { t => { table_name => 't' } }, columns => {}, indexes => {} };
  throws_ok { DBIO::Oracle::Diff->new(source => $empty, target => $bare)->operations }
    qr/table 't'.*no columns/s,
    'a new table the model gives no columns is refused, never CREATE TABLE t ( )';
}

done_testing;
