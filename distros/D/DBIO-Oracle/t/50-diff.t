use strict;
use warnings;
use Test::More;

use_ok 'DBIO::Oracle::Diff::Table';
use_ok 'DBIO::Oracle::Diff::Column';
use_ok 'DBIO::Oracle::Diff::Index';
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
  like($sql, qr/CREATE TABLE author/,        'create table');
  like($sql, qr/id NUMBER NOT NULL/,         'id column inline');
  like($sql, qr/name VARCHAR2\(100\) NOT NULL/, 'name column with size + NOT NULL');
  like($sql, qr/PRIMARY KEY \(id\)/,         'primary key constraint');

  is($ops[0]->summary, '+ table: author', 'create summary');
}

# ---------------------------------------------------------------------------
# Diff::Table create with FK
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Table->diff(
    {},
    { book => { table_name => 'book' } },
    {
      book => [
        { column_name => 'id',        data_type => 'NUMBER', is_pk => 1, not_null => 1 },
        { column_name => 'author_id', data_type => 'NUMBER', not_null => 1 },
      ],
    },
    {
      book => [
        { from_columns => ['author_id'], to_table => 'author', to_columns => ['id'] },
      ],
    },
  );
  like($ops[0]->as_sql,
    qr/FOREIGN KEY \(author_id\) REFERENCES author\(id\)/,
    'inline FK');
}

# ---------------------------------------------------------------------------
# Diff::Table create with sequence (auto-increment)
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::Oracle::Diff::Table->diff(
    {},
    { thing => { table_name => 'thing' } },
    {
      thing => [
        { column_name => 'id', data_type => 'NUMBER', is_pk => 1, not_null => 1,
          is_auto_increment => 1, sequence => 'thing_seq' },
      ],
    },
    {},
  );
  my $sql = $ops[0]->as_sql;
  like($sql, qr/CREATE SEQUENCE thing_seq;/, 'sequence emitted');
  like($sql, qr/CREATE SEQUENCE.*CREATE TABLE/s, 'sequence before table');
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
  like($ops[0]->as_sql, qr/PRIMARY KEY \(a, b\)/, 'multi-col PK as constraint');
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
  is($ops[0]->as_sql, 'DROP TABLE gone CASCADE CONSTRAINTS;', 'drop SQL');
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
  is($ops[0]->as_sql, 'ALTER TABLE t ADD (extra VARCHAR2(255));', 'add SQL');
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
    q{ALTER TABLE t ADD (flag NUMBER DEFAULT '0' NOT NULL);},
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
  is($ops[0]->as_sql, 'ALTER TABLE t DROP COLUMN gone;', 'drop column SQL');
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
  like($ops[0]->as_sql, qr/ALTER TABLE t MODIFY \(val VARCHAR2\(50\)\);/, 'modify SQL honours size');
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
  like($ops[0]->as_sql, qr/ALTER TABLE t MODIFY \(val NOT NULL\);/, 'modify NOT NULL SQL');
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
  is($ops[0]->as_sql, 'CREATE INDEX idx_t_name ON t (name);', 'create index SQL');
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
  is($ops[0]->as_sql, 'CREATE UNIQUE INDEX uq_t_ab ON t (a, b);', 'unique multi-col index');
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
  is($ops[0]->as_sql, 'DROP INDEX idx_old;', 'drop index SQL');
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
  like($sql, qr/CREATE TABLE created/,   'sql has table create');
  like($sql, qr/ALTER TABLE keep ADD/,   'sql has column add');
  like($sql, qr/CREATE INDEX idx_keep_new/, 'sql has index create');

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

done_testing;
