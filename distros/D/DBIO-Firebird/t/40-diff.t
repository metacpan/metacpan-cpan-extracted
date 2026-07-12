use strict;
use warnings;
use Test::More;

# Offline diff tests -- no live Firebird DB required. Exercises the diff op
# classes directly with mock introspected models.

use_ok 'DBIO::Firebird::Diff::Table';
use_ok 'DBIO::Firebird::Diff::Column';
use_ok 'DBIO::Firebird::Diff::Index';
use_ok 'DBIO::Firebird::Diff';

# --- Diff::Table create ---
{
  my @ops = DBIO::Firebird::Diff::Table->diff(
    {},
    { author => { table_name => 'author', kind => 'table' } },
    {
      author => [
        { column_name => 'id',   data_type => 'INTEGER', is_pk => 1, not_null => 0 },
        { column_name => 'name', data_type => 'VARCHAR', size => 255, not_null => 1 },
      ],
    },
    { author => [] },
  );
  is(scalar @ops, 1, 'one create op');
  is($ops[0]->action, 'create', 'action create');
  is($ops[0]->table_name, 'author', 'table_name');
  my $sql = $ops[0]->as_sql;
  like($sql, qr/CREATE TABLE author/,        'create table');
  like($sql, qr/id INTEGER/,                 'id column inline');
  like($sql, qr/name VARCHAR\(255\) NOT NULL/, 'name column with size + NOT NULL');
  like($sql, qr/PRIMARY KEY \(id\)/,         'PK constraint');
  is($ops[0]->summary, '+ table: author',    'create summary');
}

# --- Diff::Table create with FK + composite size ---
{
  my @ops = DBIO::Firebird::Diff::Table->diff(
    {},
    { book => { table_name => 'book' } },
    {
      book => [
        { column_name => 'id',        data_type => 'INTEGER', is_pk => 1 },
        { column_name => 'price',     data_type => 'NUMERIC', size => [10, 2] },
        { column_name => 'author_id', data_type => 'INTEGER', not_null => 1 },
      ],
    },
    {
      book => [
        { from_columns => ['author_id'], to_table => 'author', to_columns => ['id'] },
      ],
    },
  );
  my $sql = $ops[0]->as_sql;
  like($sql, qr/price NUMERIC\(10,2\)/, 'composite size (precision,scale)');
  like($sql, qr/FOREIGN KEY \(author_id\) REFERENCES author\(id\)/, 'inline FK');
}

# --- Diff::Table multi-column PK ---
{
  my @ops = DBIO::Firebird::Diff::Table->diff(
    {},
    { mtm => { table_name => 'mtm' } },
    {
      mtm => [
        { column_name => 'a', data_type => 'INTEGER', is_pk => 1 },
        { column_name => 'b', data_type => 'INTEGER', is_pk => 1 },
      ],
    },
    {},
  );
  like($ops[0]->as_sql, qr/PRIMARY KEY \(a, b\)/, 'multi-col PK as constraint');
}

# --- Diff::Table drop ---
{
  my @ops = DBIO::Firebird::Diff::Table->diff(
    { gone => { table_name => 'gone' } },
    {},
  );
  is(scalar @ops, 1,                       'one drop op');
  is($ops[0]->action, 'drop',              'drop op');
  is($ops[0]->as_sql, 'DROP TABLE gone;',  'drop SQL');
  is($ops[0]->summary, '- table: gone',    'drop summary');
}

# --- Diff::Column add ---
{
  my @ops = DBIO::Firebird::Diff::Column->diff(
    { t => [ { column_name => 'id', data_type => 'INTEGER' } ] },
    {
      t => [
        { column_name => 'id',    data_type => 'INTEGER' },
        { column_name => 'extra', data_type => 'VARCHAR', not_null => 0 },
      ],
    },
    { t => { table_name => 't' } }, { t => { table_name => 't' } },
  );
  is(scalar @ops, 1, 'one add op');
  is($ops[0]->action, 'add', 'action add');
  is($ops[0]->as_sql, 'ALTER TABLE t ADD extra VARCHAR;', 'add SQL (no COLUMN keyword)');
  is($ops[0]->summary, '  +column: t.extra (VARCHAR)', 'add summary');
}

# --- Diff::Column add NOT NULL with default ---
{
  my @ops = DBIO::Firebird::Diff::Column->diff(
    { t => [ { column_name => 'id', data_type => 'INTEGER' } ] },
    {
      t => [
        { column_name => 'id',   data_type => 'INTEGER' },
        { column_name => 'flag', data_type => 'INTEGER', not_null => 1, default_value => '0' },
      ],
    },
    { t => { table_name => 't' } }, { t => { table_name => 't' } },
  );
  like($ops[0]->as_sql, qr/NOT NULL DEFAULT 0/, 'NOT NULL DEFAULT in add');
}

# --- Diff::Column drop ---
{
  my @ops = DBIO::Firebird::Diff::Column->diff(
    {
      t => [
        { column_name => 'id',  data_type => 'INTEGER' },
        { column_name => 'old', data_type => 'VARCHAR' },
      ],
    },
    { t => [ { column_name => 'id', data_type => 'INTEGER' } ] },
    { t => { table_name => 't' } }, { t => { table_name => 't' } },
  );
  is(scalar @ops, 1, 'one drop op');
  is($ops[0]->action, 'drop', 'action drop');
  is($ops[0]->as_sql, 'ALTER TABLE t DROP old;', 'drop SQL (no COLUMN keyword)');
}

# --- Diff::Column alter type / not_null / default ---
{
  my @ops = DBIO::Firebird::Diff::Column->diff(
    { t => [ { column_name => 'c', data_type => 'INTEGER', not_null => 0 } ] },
    { t => [ { column_name => 'c', data_type => 'BIGINT',  not_null => 1, default_value => '5' } ] },
    { t => { table_name => 't' } }, { t => { table_name => 't' } },
  );
  is(scalar @ops, 1, 'one alter op');
  is($ops[0]->action, 'alter', 'action alter');
  my $sql = $ops[0]->as_sql;
  like($sql, qr/ALTER TABLE t ALTER c TYPE BIGINT;/,   'alter type');
  like($sql, qr/ALTER TABLE t ALTER c SET NOT NULL;/,  'set not null');
  like($sql, qr/ALTER TABLE t ALTER c SET DEFAULT 5;/, 'set default');
  is($ops[0]->summary, '  ~column: t.c (BIGINT)', 'alter summary');
}

# --- Diff::Column alter drop not_null / drop default ---
{
  my @ops = DBIO::Firebird::Diff::Column->diff(
    { t => [ { column_name => 'c', data_type => 'INTEGER', not_null => 1, default_value => '9' } ] },
    { t => [ { column_name => 'c', data_type => 'INTEGER', not_null => 0 } ] },
    { t => { table_name => 't' } }, { t => { table_name => 't' } },
  );
  my $sql = $ops[0]->as_sql;
  like($sql, qr/ALTER TABLE t ALTER c DROP NOT NULL;/, 'drop not null');
  like($sql, qr/ALTER TABLE t ALTER c DROP DEFAULT;/,  'drop default');
}

# --- Diff::Column skips tables not present in both models ---
{
  my @ops = DBIO::Firebird::Diff::Column->diff(
    {},
    { newtbl => [ { column_name => 'id', data_type => 'INTEGER' } ] },
    {},                              # source_tables: newtbl absent
    { newtbl => { table_name => 'newtbl' } },
  );
  is(scalar @ops, 0, 'no column ops for table only in target (handled by Table diff)');
}

# --- Diff::Index create ---
{
  my @ops = DBIO::Firebird::Diff::Index->diff(
    { t => {} },
    { t => { idx_name => { columns => ['name'], is_unique => 0 } } },
  );
  is(scalar @ops, 1, 'one create op');
  is($ops[0]->action, 'create', 'action create');
  is($ops[0]->as_sql, 'CREATE INDEX idx_name ON t (name);', 'create index SQL');
  is($ops[0]->summary, '  +index: idx_name on t', 'create index summary');
}

# --- Diff::Index create unique multi-column ---
{
  my @ops = DBIO::Firebird::Diff::Index->diff(
    { t => {} },
    { t => { idx_uniq => { columns => ['a', 'b'], is_unique => 1 } } },
  );
  is($ops[0]->as_sql, 'CREATE UNIQUE INDEX idx_uniq ON t (a, b);', 'unique multi-col index');
}

# --- Diff::Index drop ---
{
  my @ops = DBIO::Firebird::Diff::Index->diff(
    { t => { idx_gone => { columns => ['x'], is_unique => 0 } } },
    { t => {} },
  );
  is(scalar @ops, 1, 'one drop op');
  is($ops[0]->action, 'drop', 'action drop');
  is($ops[0]->as_sql, 'DROP INDEX idx_gone;', 'drop index SQL');
  is($ops[0]->summary, '  -index: idx_gone on t', 'drop index summary');
}

# --- Diff::Index changed definition -> drop + create pair ---
{
  my @ops = DBIO::Firebird::Diff::Index->diff(
    { t => { idx => { columns => ['a'],      is_unique => 0 } } },
    { t => { idx => { columns => ['a', 'b'], is_unique => 1 } } },
  );
  is(scalar @ops, 2, 'changed index -> two ops');
  is($ops[0]->action, 'drop',   'first op drop');
  is($ops[1]->action, 'create', 'second op create');
  like($ops[1]->as_sql, qr/CREATE UNIQUE INDEX idx ON t \(a, b\);/, 'recreated with new def');
}

# --- Diff::Index suppresses drop for an index of a dropped table (karr #14) ---
# When the owning table is itself being dropped in the same pass (present in
# source tables, absent from target tables), Firebird's DROP TABLE already
# removes the table's indexes, so no standalone DROP INDEX must be emitted.
{
  my @ops = DBIO::Firebird::Diff::Index->diff(
    { leftover => { idx_leftover_id => { columns => ['id'], is_unique => 1 } } },
    {},
    { leftover => { table_name => 'leftover' } },  # source tables: leftover exists
    {},                                            # target tables: gone -> dropped
  );
  is(scalar @ops, 0, 'no standalone DROP INDEX when owning table is dropped');
}

# --- Diff::Index over-suppression guard (karr #14) ---
# A table that STAYS but loses an unrelated index must still get its standalone
# DROP INDEX; the suppression is scoped to indexes of dropped tables only.
{
  my @ops = DBIO::Firebird::Diff::Index->diff(
    { t => { idx_gone => { columns => ['x'], is_unique => 0 } } },
    { t => {} },
    { t => { table_name => 't' } },  # source tables: t exists
    { t => { table_name => 't' } },  # target tables: t survives
  );
  is(scalar @ops, 1, 'index drop still emitted when the table itself survives');
  is($ops[0]->action, 'drop', 'surviving-table index drop is a drop op');
  is($ops[0]->as_sql, 'DROP INDEX idx_gone;', 'surviving-table index still dropped standalone');
}

# --- Full Diff orchestration via _build_operations ---
{
  my $source = {
    tables      => { keep => { table_name => 'keep' }, gone => { table_name => 'gone' } },
    columns     => { keep => [ { column_name => 'id', data_type => 'INTEGER' } ] },
    indexes     => { keep => {} },
    foreign_keys => {},
  };
  my $target = {
    tables      => { keep => { table_name => 'keep' }, fresh => { table_name => 'fresh' } },
    columns     => {
      keep  => [ { column_name => 'id', data_type => 'INTEGER' },
                 { column_name => 'note', data_type => 'VARCHAR' } ],
      fresh => [ { column_name => 'id', data_type => 'INTEGER', is_pk => 1 } ],
    },
    indexes     => { keep => { keep_idx => { columns => ['note'], is_unique => 0 } } },
    foreign_keys => {},
  };

  my $diff = DBIO::Firebird::Diff->new(source => $source, target => $target);
  ok($diff->has_changes, 'diff reports changes');

  my @ops = @{ $diff->operations };
  my @sql = map { $_->as_sql } @ops;
  my $all = join "\n", @sql;

  like($all, qr/CREATE TABLE fresh/,          'creates new table');
  like($all, qr/DROP TABLE gone;/,            'drops removed table');
  like($all, qr/ALTER TABLE keep ADD note/,   'adds column to kept table');
  like($all, qr/CREATE INDEX keep_idx ON keep/, 'creates index');

  ok(length $diff->as_sql,  'as_sql renders');
  ok(length $diff->summary, 'summary renders');
}

# --- No changes ---
{
  my $model = {
    tables => { t => { table_name => 't' } },
    columns => { t => [ { column_name => 'id', data_type => 'INTEGER' } ] },
    indexes => { t => {} },
    foreign_keys => {},
  };
  my $diff = DBIO::Firebird::Diff->new(source => $model, target => $model);
  ok(!$diff->has_changes, 'identical models -> no changes');
}

done_testing;
