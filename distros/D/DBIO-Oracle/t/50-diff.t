use strict;
use warnings;
use Test::More;

use_ok 'DBIO::Oracle::Diff::Table';
use_ok 'DBIO::Oracle::Diff::Column';
use_ok q{DBIO::Oracle::Diff::Index};
use_ok q{DBIO::Oracle::Diff::ForeignKey};
use_ok 'DBIO::Oracle::Diff';

# ---------------------------------------------------------------------------
# Diff::Table create
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Table->diff(
    {},
    { author => { table_name => 'author' } },
    {
      author => [
        { column_name => 'id',   data_type => 'NUMBER',   is_pk => 1, not_null => 1 },
        { column_name => 'name', data_type => 'VARCHAR2', size => 100, not_null => 1 },
      ],
    },
    { author => [] },
  );
  is(scalar @ops, 1,         'one create op');
  is($ops[0]->action, 'create',  'action create');
  is($ops[0]->table_name, 'author', 'table_name');

  my $sql = $ops[0]->as_sql;
  like($sql, qr/CREATE TABLE "author"/,        'create table');
  like($sql, qr/"id" NUMBER NOT NULL/,         'id column inline');
  like($sql, qr/"name" VARCHAR2\(100\) NOT NULL/, 'name column with size + NOT NULL');
  like($sql, qr/PRIMARY KEY \("id"\)/,         'primary key constraint');

  is($ops[0]->summary, '+ table: author', 'create summary');
}

# ---------------------------------------------------------------------------
# Diff::Table create with unique constraints; the foreign keys of a new table
# are Diff::ForeignKey's, after every CREATE TABLE (karr k37)
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Table->diff(
    {},
    { book => { table_name => 'book' } },
    {
      book => [
        { column_name => 'id',        data_type => 'NUMBER', is_pk => 1, not_null => 1 },
        { column_name => 'author_id', data_type => 'NUMBER', not_null => 1 },
        { column_name => 'isbn',      data_type => 'VARCHAR2', size => 13 },
      ],
    },
    { book => [ [ book_isbn_uq => ['isbn'] ] ] },
  );
  my $sql = $ops[0]->as_sql;
  like($sql, qr/PRIMARY KEY \("id"\),\n  CONSTRAINT "book_isbn_uq" UNIQUE \("isbn"\)\n\);/,
    'unique constraint inline, named, after the primary key');
  unlike($sql, qr/FOREIGN KEY/, 'no foreign key inside the CREATE TABLE');

  my @fk = DBIO::Oracle::Diff::ForeignKey->diff(
    { book => [] },
    {
      book => [
        { from_columns => ['author_id'], to_table => 'author', to_columns => ['id'] },
      ],
    },
    {},
    { book => {} },
  );
  is(scalar @fk, 1, 'one foreign key op for the new table');
  is($fk[0]->as_sql,
    'ALTER TABLE "book" ADD CONSTRAINT "fk_book_author_id_author" '
  . 'FOREIGN KEY ("author_id") REFERENCES "author" ("id");',
    'FK as ALTER TABLE, named as the install names it');
}

# ---------------------------------------------------------------------------
# Diff::Table create with sequence (auto-increment): the sequence and the
# trigger after the table, as the install writes them (karr k37)
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Table->diff(
    {},
    { thing => { table_name => 'thing', schema => 'U' } },
    {
      thing => [
        { column_name => 'id', data_type => 'NUMBER', is_pk => 1, not_null => 1,
          is_auto_increment => 1, sequence => 'U.thing_seq' },
      ],
    },
    {},
  );
  my $sql = $ops[0]->as_sql;
  like($sql, qr/CREATE SEQUENCE "thing_seq";/, 'sequence emitted, without the schema of the model');
  like($sql, qr/CREATE TABLE.*CREATE SEQUENCE.*CREATE OR REPLACE TRIGGER "thing_id_trg"/s,
    'table, sequence, trigger: the order of the install');
  like($sql, qr/SELECT "thing_seq"\.NEXTVAL INTO :new\."id" FROM DUAL;\nEND;\z/,
    'the trigger fills the column from the sequence');
}

# ---------------------------------------------------------------------------
# Diff::Table multi-column PK
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Table->diff(
    {},
    { mtm => { table_name => 'mtm' } },
    {
      mtm => [
        { column_name => 'a', data_type => 'NUMBER', is_pk => 1, not_null => 1 },
        { column_name => 'b', data_type => 'NUMBER', is_pk => 1, not_null => 1 },
      ],
    },
    {},
  );
  like($ops[0]->as_sql, qr/PRIMARY KEY \("a", "b"\)/, 'multi-col PK as constraint');
}

# ---------------------------------------------------------------------------
# Diff::Table create with defaults (karr k45). Oracle's column definition is
# "datatype [DEFAULT expr] [inline_constraint ...]": DEFAULT stands before
# NOT NULL, as Diff::Column writes it for ADD further down. The server
# refuses the other order (ORA-03076 on 23.26, measured in
# t/54-deploy-live.t, 1e).
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Table->diff(
    {},
    { defaulted => { table_name => 'defaulted' } },
    {
      defaulted => [
        { column_name => 'code',  data_type => 'VARCHAR2', size => 20, not_null => 1, default_value => 'x' },
        { column_name => 'n',     data_type => 'NUMBER',   not_null => 1, default_value => '0' },
        { column_name => 'twice', data_type => 'NUMBER',   not_null => 1, default_value => \'1 + 1' },
        { column_name => 'note',  data_type => 'VARCHAR2', size => 20, not_null => 0, default_value => 'none' },
      ],
    },
    {},
  );
  my $sql = $ops[0]->as_sql;
  like($sql, qr/^\s*"code" VARCHAR2\(20\) DEFAULT 'x' NOT NULL,$/m,
    'create: a literal default is written before NOT NULL');
  like($sql, qr/^\s*"n" NUMBER DEFAULT 0 NOT NULL,$/m,
    'create: ... a false one (0) as well, and a number is not quoted (karr k47)');
  like($sql, qr/^\s*"twice" NUMBER DEFAULT 1 \+ 1 NOT NULL,$/m,
    'create: ... and so is an expression default (scalar ref)');
  like($sql, qr/^\s*"note" VARCHAR2\(20\) DEFAULT 'none'$/m,
    'create: a nullable column keeps its default and gets no NOT NULL');
  unlike($sql, qr/NOT NULL\s+DEFAULT/,
    'create: no column definition has NOT NULL in front of DEFAULT');
}

# ---------------------------------------------------------------------------
# Diff::Table drop
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Table->diff(
    { gone => { table_name => 'gone' } },
    {},
  );
  is(scalar @ops, 1, 'one drop op');
  is($ops[0]->action, 'drop', 'drop op');
  is($ops[0]->as_sql, q{DROP TABLE "gone" CASCADE CONSTRAINTS;}, 'drop SQL');
  is($ops[0]->summary, '- table: gone', 'drop summary');
}

# ---------------------------------------------------------------------------
# Diff::Column add
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Column->diff(
    { t => [ { column_name => 'id', data_type => 'integer' } ] },
    {
      t => [
        { column_name => 'id',    data_type => 'integer' },
        { column_name => 'extra', data_type => 'varchar', not_null => 0 },
      ],
    },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'one add op');
  is($ops[0]->action, 'add', 'action add');
  is($ops[0]->as_sql, 'ALTER TABLE "t" ADD ("extra" VARCHAR2(255));', 'add SQL');
  is($ops[0]->summary, '  +column: t.extra (varchar)', 'add summary');
}

# ---------------------------------------------------------------------------
# Diff::Column add NOT NULL with default
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Column->diff(
    { t => [ { column_name => 'id', data_type => 'integer' } ] },
    {
      t => [
        { column_name => 'id',   data_type => 'integer' },
        { column_name => 'flag', data_type => 'integer', not_null => 1, default_value => '0' },
      ],
    },
    { t => {} }, { t => {} },
  );
  is($ops[0]->as_sql,
    q{ALTER TABLE "t" ADD ("flag" INTEGER DEFAULT 0 NOT NULL);},
    'add NOT NULL with default SQL');
}

# ---------------------------------------------------------------------------
# Diff::Column drop
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Column->diff(
    {
      t => [
        { column_name => 'id',   data_type => 'integer' },
        { column_name => 'gone', data_type => 'varchar' },
      ],
    },
    { t => [ { column_name => 'id', data_type => 'integer' } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'one drop op');
  is($ops[0]->action, 'drop', 'action drop');
  is($ops[0]->as_sql, 'ALTER TABLE "t" DROP COLUMN "gone" CASCADE CONSTRAINTS;', 'drop column SQL');
}

# ---------------------------------------------------------------------------
# Diff::Column alter (type change)
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Column->diff(
    { t => [ { column_name => 'val', data_type => 'integer' } ] },
    { t => [ { column_name => 'val', data_type => 'varchar', size => 50 } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'one alter op');
  is($ops[0]->action, 'alter', 'action alter');
  like($ops[0]->as_sql, qr/ALTER TABLE "t" MODIFY \("val" VARCHAR2\(50\)\);/, 'modify SQL honours size');
  is($ops[0]->summary, '  ~column: t.val (varchar)', 'alter summary');
}

# ---------------------------------------------------------------------------
# Diff::Column alter (NOT NULL change)
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Column->diff(
    { t => [ { column_name => 'val', data_type => 'integer', not_null => 0 } ] },
    { t => [ { column_name => 'val', data_type => 'integer', not_null => 1 } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'one alter op');
  like($ops[0]->as_sql, qr/ALTER TABLE "t" MODIFY \("val" NOT NULL\);/, 'modify NOT NULL SQL');
}

# ---------------------------------------------------------------------------
# Diff::Column - no change when identical
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Column->diff(
    { t => [ { column_name => 'val', data_type => 'integer', not_null => 1 } ] },
    { t => [ { column_name => 'val', data_type => 'integer', not_null => 1 } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 0, 'no ops for identical columns');
}

# ---------------------------------------------------------------------------
# Diff::Index create
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Index->diff(
    { t => {} },
    {
      t => {
        idx_t_name => { index_name => 'idx_t_name', columns => ['name'] },
      },
    },
  );
  is(scalar @ops, 1, 'one create op');
  is($ops[0]->action, 'create', 'action create');
  is($ops[0]->as_sql, q{CREATE INDEX "idx_t_name" ON "t" ("name");}, 'create index SQL');
  is($ops[0]->summary, '  +index: idx_t_name on t', 'create index summary');
}

# ---------------------------------------------------------------------------
# Diff::Index create unique multi-column
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Index->diff(
    { t => {} },
    {
      t => {
        uq_t_ab => { index_name => 'uq_t_ab', columns => ['a', 'b'], is_unique => 1 },
      },
    },
  );
  is($ops[0]->as_sql, q{CREATE UNIQUE INDEX "uq_t_ab" ON "t" ("a", "b");}, 'unique multi-col index');
}

# ---------------------------------------------------------------------------
# Diff::Index changed (same name, different columns) — must emit a
# drop+create pair, not silence (karr k19).
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Index->diff(
    {
      t => {
        idx_t_name => { index_name => 'idx_t_name', columns => ['name'] },
      },
    },
    {
      t => {
        idx_t_name => { index_name => 'idx_t_name', columns => ['email'] },
      },
    },
  );
  is(scalar @ops, 2, 'changed index yields two ops');
  is($ops[0]->action, 'drop',   'first op is drop');
  is($ops[0]->as_sql, q{DROP INDEX "idx_t_name";}, 'drop SQL for old definition');
  is($ops[1]->action, 'create', 'second op is create');
  is($ops[1]->as_sql, q{CREATE INDEX "idx_t_name" ON "t" ("email");}, 'create SQL for new definition');
}

# ---------------------------------------------------------------------------
# Diff::Index changed (same columns, uniqueness flips) — also a change.
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Index->diff(
    {
      t => {
        idx_t_a => { index_name => 'idx_t_a', columns => ['a'], is_unique => 0 },
      },
    },
    {
      t => {
        idx_t_a => { index_name => 'idx_t_a', columns => ['a'], is_unique => 1 },
      },
    },
  );
  is(scalar @ops, 2, 'uniqueness-only change yields drop+create');
  is($ops[1]->as_sql, q{CREATE UNIQUE INDEX "idx_t_a" ON "t" ("a");}, 'create SQL is unique');
}

# ---------------------------------------------------------------------------
# Diff::Index unchanged (same name, same columns/uniqueness) — no ops.
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Index->diff(
    {
      t => {
        idx_t_name => { index_name => 'idx_t_name', columns => ['name'] },
      },
    },
    {
      t => {
        idx_t_name => { index_name => 'idx_t_name', columns => ['name'] },
      },
    },
  );
  is(scalar @ops, 0, 'no ops for identical indexes');
}

# ---------------------------------------------------------------------------
# Diff::Index drop
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Index->diff(
    {
      t => {
        idx_old => { index_name => 'idx_old', columns => ['x'] },
      },
    },
    { t => {} },
  );
  is(scalar @ops, 1, 'one drop op');
  is($ops[0]->action, 'drop', 'action drop');
  is($ops[0]->as_sql, q{DROP INDEX "idx_old";}, 'drop index SQL');
  is($ops[0]->summary, '  -index: idx_old on t', 'drop index summary');
}

# ---------------------------------------------------------------------------
# Diff orchestrator — full model, ordering + has_changes/as_sql/summary
# ---------------------------------------------------------------------------
{
  my $source = {
    tables  => { keep => { table_name => 'keep' } },
    columns => { keep => [ { column_name => 'id', data_type => 'integer' } ] },
    indexes => { keep => {} },
  };
  my $target = {
    tables  => {
      keep    => { table_name => 'keep' },
      created => { table_name => 'created' },
    },
    columns => {
      keep => [
        { column_name => 'id',  data_type => 'integer' },
        { column_name => 'new', data_type => 'varchar' },
      ],
      created => [
        { column_name => 'id', data_type => 'NUMBER', is_pk => 1, not_null => 1 },
      ],
    },
    indexes => {
      keep => {
        idx_keep_new => { index_name => 'idx_keep_new', columns => ['new'] },
      },
    },
  };

  my $diff = DBIO::Oracle::Diff->new(source => $source, target => $target);
  ok($diff->has_changes, 'has_changes true');

  my @ops = @{ $diff->operations };
  ok(scalar @ops >= 3, 'multiple operations');

  # ordering: tables before columns before indexes
  my %first;
  for my $i (0 .. $#ops) {
    my $cls = ref $ops[$i];
    $first{$cls} //= $i;
  }
  ok($first{'DBIO::Oracle::Diff::Table'}  < $first{'DBIO::Oracle::Diff::Column'},
    'tables before columns');
  ok($first{'DBIO::Oracle::Diff::Column'} < $first{'DBIO::Oracle::Diff::Index'},
    'columns before indexes');

  my $sql = $diff->as_sql;
  like($sql, qr/CREATE TABLE "created"/,   'sql has table create');
  like($sql, qr/ALTER TABLE "keep" ADD/,   'sql has column add');
  like($sql, qr/CREATE INDEX "idx_keep_new"/, 'sql has index create');

  my $summary = $diff->summary;
  like($summary, qr/\+ table: created/,        'summary has table');
  like($summary, qr/\+column: keep\.new/,      'summary has column');
  like($summary, qr/\+index: idx_keep_new/,    'summary has index');
}

# ---------------------------------------------------------------------------
# Diff orchestrator — empty diff
# ---------------------------------------------------------------------------
{
  my $model = {
    tables  => { t => { table_name => 't' } },
    columns => { t => [ { column_name => 'id', data_type => 'integer' } ] },
    indexes => { t => {} },
  };
  my $diff = DBIO::Oracle::Diff->new(source => $model, target => $model);
  ok(!$diff->has_changes, 'no changes for identical models');
  is($diff->as_sql, '', 'empty sql');
}

# ---------------------------------------------------------------------------
# Diff::Column — expression defaults (SCALAR refs) must not phantom-diff.
# Introspection stores e.g. sysdate as \'current_timestamp'; two distinct
# refs with the same content must compare equal.
# ---------------------------------------------------------------------------
{
  my $src_expr = \'current_timestamp';
  my $tgt_expr = \'CURRENT_TIMESTAMP';   # different ref, different case
  my @ops = DBIO::Oracle::Diff::Column->diff(
    { t => [ { column_name => 'created', data_type => 'timestamp', default_value => $src_expr } ] },
    { t => [ { column_name => 'created', data_type => 'timestamp', default_value => $tgt_expr } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 0, 'identical expression defaults produce no diff');
}

{
  # a genuine default change is still detected
  my @ops = DBIO::Oracle::Diff::Column->diff(
    { t => [ { column_name => 'state', data_type => 'varchar', size => 10, default_value => 'old' } ] },
    { t => [ { column_name => 'state', data_type => 'varchar', size => 10, default_value => 'new' } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'changed literal default detected');
}

# ---------------------------------------------------------------------------
# Diff::Column — size-only change (same data_type) must be detected and
# emit a MODIFY with the new size (karr k19).
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Column->diff(
    { t => [ { column_name => 'val', data_type => 'varchar', size => 50 } ] },
    { t => [ { column_name => 'val', data_type => 'varchar', size => 100 } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'size-only VARCHAR2 change detected as alter');
  is($ops[0]->action, 'alter', 'action alter');
  like($ops[0]->as_sql, qr/ALTER TABLE "t" MODIFY \("val" VARCHAR2\(100\)\);/,
    'modify SQL carries the new size');
}

{
  # NUMBER(precision, scale) — size is a [precision, scale] arrayref.
  my @ops = DBIO::Oracle::Diff::Column->diff(
    { t => [ { column_name => 'amount', data_type => 'numeric', size => [10, 2] } ] },
    { t => [ { column_name => 'amount', data_type => 'numeric', size => [12, 2] } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'size-only NUMBER(p,s) change detected as alter');
  like($ops[0]->as_sql, qr/ALTER TABLE "t" MODIFY \("amount" NUMBER\(12,2\)\);/,
    'modify SQL carries the new precision');
}

# ---------------------------------------------------------------------------
# Diff orchestrator — a table only one of the models has, with an index
# (karr k37). A new table is created with its columns, and its index follows
# the CREATE TABLE. t/81-diff-new-table.t pins the whole order (keys, sequence,
# trigger), t/55-diff-index-live.t runs it against a server. The drop side is
# what has to stay: no DROP INDEX behind the DROP TABLE, where Oracle has none
# left to drop (ORA-01418, t/55).
# ---------------------------------------------------------------------------
{
  my $with = {
    tables  => { created => { table_name => 'created' } },
    columns => {
      created => [
        { column_name => 'id',   data_type => 'numeric',  not_null => 1 },
        { column_name => 'name', data_type => 'varchar2', size => 100, not_null => 0 },
      ],
    },
    indexes => {
      created => {
        idx_created_name => { index_name => 'idx_created_name', columns => ['name'], is_unique => 0 },
      },
    },
  };
  my $without = { tables => {}, columns => {}, indexes => {} };

  my $create = DBIO::Oracle::Diff->new(source => $without, target => $with);

  is_deeply([ map { ref } @{ $create->operations } ],
    [ 'DBIO::Oracle::Diff::Table', 'DBIO::Oracle::Diff::Index' ],
    'a table only the target has is a table op and an op for its index');

  like($create->as_sql, qr/CREATE TABLE "created" \(\s*"id" NUMBER NOT NULL,/,
    'the CREATE TABLE of a new table names its columns');
  like($create->as_sql,
    qr/CREATE TABLE "created".*CREATE INDEX "idx_created_name" ON "created" \("name"\);/s,
    '... and its index is created, after the table');

  my $drop = DBIO::Oracle::Diff->new(source => $with, target => $without);

  is($drop->as_sql, 'DROP TABLE "created" CASCADE CONSTRAINTS;',
    'a table only the source has is dropped, with no DROP INDEX behind it');
}

# ---------------------------------------------------------------------------
# Defaults are SQL literals (karr k47). One renderer for ADD, MODIFY and the
# CREATE TABLE of Diff::Table, and the comparison key is built from the same
# rendering -- so that what the introspector reads back (Introspect::Columns
# undoes the doubling) is equal to what was declared and nothing is reported
# twice (ADR 0009).
# ---------------------------------------------------------------------------
{
  my @add = DBIO::Oracle::Diff::Column->diff(
    { t => [ { column_name => 'id', data_type => 'integer' } ] },
    { t => [
        { column_name => 'id', data_type => 'integer' },
        { column_name => 'msg', data_type => 'varchar', size => 20, default_value => "it's" },
    ] },
    { t => {} }, { t => {} },
  );
  is($add[0]->as_sql, q{ALTER TABLE "t" ADD ("msg" VARCHAR2(20) DEFAULT 'it''s');},
    'add: the apostrophe of a string default is doubled');

  my @mod = DBIO::Oracle::Diff::Column->diff(
    { t => [ { column_name => 'msg', data_type => 'varchar', size => 20 } ] },
    { t => [ { column_name => 'msg', data_type => 'varchar', size => 20, default_value => "it's" } ] },
    { t => {} }, { t => {} },
  );
  is($mod[0]->as_sql, q{ALTER TABLE "t" MODIFY ("msg" DEFAULT 'it''s');},
    'modify: ... and so is it there');

  my @num = DBIO::Oracle::Diff::Column->diff(
    { t => [ { column_name => 'n', data_type => 'integer', default_value => 1 } ] },
    { t => [ { column_name => 'n', data_type => 'integer', default_value => 0 } ] },
    { t => {} }, { t => {} },
  );
  is($num[0]->as_sql, 'ALTER TABLE "t" MODIFY ("n" DEFAULT 0);',
    'modify: a number default is not quoted');

  my @create = DBIO::Oracle::Diff::Table->diff(
    {}, { t => { table_name => 't' } },
    { t => [ { column_name => 'msg', data_type => 'VARCHAR2', size => 20, default_value => "it's" } ] },
    {},
  );
  like($create[0]->as_sql, qr/^\s*"msg" VARCHAR2\(20\) DEFAULT 'it''s'$/m,
    'create: ... and in a CREATE TABLE');

  # declared versus introspected: no phantom diff
  for my $pair (
    [ "it's",   "it's"   ],
    [ 0,        '0'      ],
    [ '007',    '007'    ],
    [ -2.5,     '-2.5'   ],
    [ \'1 + 1', \'1 + 1' ],
  ) {
    my ($declared, $read) = @$pair;
    my @ops = DBIO::Oracle::Diff::Column->diff(
      { t => [ { column_name => 'c', data_type => 'varchar', size => 20, default_value => $read } ] },
      { t => [ { column_name => 'c', data_type => 'varchar', size => 20, default_value => $declared } ] },
      { t => {} }, { t => {} },
    );
    is(scalar @ops, 0, 'no diff between declared and read back: '
      . ( ref $declared ? $$declared : $declared ));
  }

  my @changed = DBIO::Oracle::Diff::Column->diff(
    { t => [ { column_name => 'c', data_type => 'varchar', size => 20, default_value => "its" } ] },
    { t => [ { column_name => 'c', data_type => 'varchar', size => 20, default_value => "it's" } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @changed, 1, 'a default that differs by the apostrophe is a change');
}

# ---------------------------------------------------------------------------
# A view is a view (karr k47, family line for DDL and diff). Introspection
# lists views beside tables, with kind => 'view'. The diff never emits DROP
# TABLE or CREATE TABLE for one (ORA-00942 / a table that was never declared):
# a view is DBIO::Oracle::Diff::View's, dropped as a view, created and replaced
# from its definition (karr k65, t/94-diff-view.t).
# ---------------------------------------------------------------------------
{
  my $view  = { table_name => 'v_open', kind => 'view',  schema => 'U' };
  my $table = { table_name => 'v_open', kind => 'table', schema => 'U' };

  is(scalar(my @none = DBIO::Oracle::Diff::Table->diff({ v_open => $view }, {})), 0,
    'the table diff leaves a view that is gone to the view diff');

  my $whole = DBIO::Oracle::Diff->new(
    source => { tables => { v_open => $view } },
    target => { tables => {} },
  );
  is($whole->as_sql, q{DROP VIEW "v_open";}, 'a view that is gone is dropped as a view through DBIO::Oracle::Diff');
  is($whole->operations->[0]->summary, '- view: v_open', '... and summarised as one');

  my $e = do { local $@; eval { DBIO::Oracle::Diff->new(
    source => { tables => {} }, target => { tables => { v_open => $view } },
  )->operations; 1 } ? '' : $@ };
  like($e, qr/v_open/, 'a new view without a definition is refused: the exception names it');
  like($e, qr/view/i, '... says it is a view');
  like($e, qr/definition/i, '... and why: there is no definition to create it from');

  $e = do { local $@; eval { DBIO::Oracle::Diff::Table->diff({ v_open => $table }, { v_open => $view }); 1 } ? '' : $@ };
  like($e, qr/v_open.*table.*view|v_open.*kind/is,
    'a table that became a view (or the reverse) is refused, naming the object');

  my @cols = DBIO::Oracle::Diff::Column->diff(
    { v_open => [ { column_name => 'id', data_type => 'integer' } ] },
    { v_open => [ { column_name => 'id', data_type => 'integer' },
                  { column_name => 'x',  data_type => 'integer' } ] },
    { v_open => $view }, { v_open => $view },
  );
  is(scalar @cols, 0, 'the columns of a view are not altered: its definition is replaced instead');
}

# ---------------------------------------------------------------------------
# The comparison key of a size (karr k38): what the server cannot keep apart
# is not a difference.
# ---------------------------------------------------------------------------
{
  my $key = sub {
    my ($type, $size) = @_;
    DBIO::Oracle::Diff::Column::_size_key({ data_type => $type, size => $size });
  };
  is_deeply($key->('numeric', [10, 0]), 10, 'numeric [10,0] is 10');
  is_deeply($key->('numeric', [10, 2]), [10, 2], '... [10,2] is not 10');
  for my $t ('timestamp', 'datetime', 'timestamp with time zone', 'timestamp with local time zone', 'timestamptz') {
    is($key->($t, 6), undef, "$t of size 6 is the default, no size");
    is($key->($t, 3), 3, "$t of size 3 keeps it");
  }
  is($key->('float', 126), undef, 'float of size 126 is the default, no size');
  is($key->('float', 63), 63, 'float of size 63 keeps it');
  is($key->('varchar2', 6), 6, '6 on a varchar2 is a size');
  is($key->('varchar2', '20 CHAR'), '20 CHAR', '20 CHAR');
  is($key->('varchar2', ' 20  char '), '20 CHAR', '... in any spelling');
  is($key->('varchar2', '20 byte'), 20, '20 BYTE is 20');
  is($key->('char', '5 Byte'), 5, '... for CHAR as well');
  isnt($key->('varchar2', '20 CHAR'), $key->('varchar2', 20), 'CHAR and BYTE stay a change');
  is($key->('NCHAR', '5 CHAR'), 5, 'a national type is of CHAR semantics: 5');
  is($key->('NVARCHAR2', '5 char'), 5, '... NVARCHAR2 too');
}

# A CREATE TABLE writes its types through the one renderer (karr k38).
{
  my @create = DBIO::Oracle::Diff::Table->diff(
    {}, { t => { table_name => 't' } },
    { t => [
      { column_name => 'a', data_type => 'varchar2', size => '20 CHAR' },
      { column_name => 'b', data_type => 'timestamp with local time zone', size => 3 },
      { column_name => 'c', data_type => 'timestamp with time zone', size => 3 },
      { column_name => 'd', data_type => 'NCHAR', size => '5 CHAR' },
      { column_name => 'e', data_type => 'raw', size => 16 },
      { column_name => 'f', data_type => 'float', size => 63 },
      { column_name => 'g', data_type => 'numeric', size => [10, 2] },
    ] },
    {},
  );
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  my $sql = $create[0]->as_sql;
  like($sql, qr/^\s*"a" VARCHAR2\(20 CHAR\),$/m, 'create: 20 CHAR');
  like($sql, qr/^\s*"b" TIMESTAMP\(3\) WITH LOCAL TIME ZONE,$/m, 'create: timestamp(3) with local time zone');
  like($sql, qr/^\s*"c" TIMESTAMP\(3\) WITH TIME ZONE,$/m, 'create: timestamp(3) with time zone');
  like($sql, qr/^\s*"d" NCHAR\(5\),$/m, 'create: NCHAR(5)');
  like($sql, qr/^\s*"e" RAW\(16\),$/m, 'create: RAW(16)');
  like($sql, qr/^\s*"f" FLOAT\(63\),$/m, 'create: FLOAT(63)');
  like($sql, qr/^\s*"g" NUMBER\(10,2\)$/m, 'create: NUMBER(10,2)');
  is_deeply(\@warn, [], 'no warning');
}

done_testing;
