use strict;
use warnings;
use Test::More;

use_ok 'DBIO::SQLite::Diff::Table';
use_ok 'DBIO::SQLite::Diff::Column';
use_ok 'DBIO::SQLite::Diff::Index';
use_ok 'DBIO::SQLite::Diff';

# --- Diff::Table create ---
{
  my @ops = DBIO::SQLite::Diff::Table->diff(
    {},
    { author => { table_name => 'author', kind => 'table' } },
    {
      author => [
        { column_name => 'id',   data_type => 'INTEGER', is_pk => 1, not_null => 0 },
        { column_name => 'name', data_type => 'TEXT',    is_pk => 0, not_null => 1 },
      ],
    },
    { author => [] },
  );
  is(scalar @ops, 1, 'one create op');
  is($ops[0]->action, 'create', 'action create');
  is($ops[0]->table_name, 'author', 'table_name');
  my $sql = $ops[0]->as_sql;
  like($sql, qr/CREATE TABLE author/, 'create table');
  like($sql, qr/id INTEGER/,          'id column inline');
  like($sql, qr/name TEXT NOT NULL/,  'name column with NOT NULL');
}

# --- Diff::Table create with FK ---
{
  my @ops = DBIO::SQLite::Diff::Table->diff(
    {},
    { book => { table_name => 'book' } },
    {
      book => [
        { column_name => 'id',        data_type => 'INTEGER', is_pk => 1 },
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
  like($sql, qr/FOREIGN KEY \(author_id\) REFERENCES author\(id\)/, 'inline FK');
}

# --- Diff::Table multi-column PK ---
{
  my @ops = DBIO::SQLite::Diff::Table->diff(
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
  my @ops = DBIO::SQLite::Diff::Table->diff(
    { gone => { table_name => 'gone' } },
    {},
  );
  is($ops[0]->action, 'drop',               'drop op');
  is($ops[0]->as_sql, 'DROP TABLE gone;',   'drop SQL');
}

# --- Diff::Column add ---
{
  my @ops = DBIO::SQLite::Diff::Column->diff(
    { t => [ { column_name => 'id', data_type => 'INTEGER' } ] },
    {
      t => [
        { column_name => 'id',    data_type => 'INTEGER' },
        { column_name => 'extra', data_type => 'TEXT', not_null => 0 },
      ],
    },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'one add op');
  is($ops[0]->action, 'add', 'action add');
  is($ops[0]->as_sql, 'ALTER TABLE t ADD COLUMN extra TEXT;', 'add SQL');
}

# --- Diff::Column add NOT NULL with default ---
{
  my @ops = DBIO::SQLite::Diff::Column->diff(
    { t => [ { column_name => 'id', data_type => 'INTEGER' } ] },
    {
      t => [
        { column_name => 'id',     data_type => 'INTEGER' },
        { column_name => 'flag',   data_type => 'INTEGER', not_null => 1, default_value => '0' },
      ],
    },
    { t => {} }, { t => {} },
  );
  like($ops[0]->as_sql, qr/NOT NULL DEFAULT 0/, 'NOT NULL DEFAULT in add');
}

# --- Diff::Column drop ---
{
  my @ops = DBIO::SQLite::Diff::Column->diff(
    {
      t => [
        { column_name => 'id',  data_type => 'INTEGER' },
        { column_name => 'old', data_type => 'TEXT' },
      ],
    },
    { t => [ { column_name => 'id', data_type => 'INTEGER' } ] },
    { t => {} }, { t => {} },
  );
  is($ops[0]->action, 'drop', 'drop op');
  like($ops[0]->as_sql, qr/DROP COLUMN old/, 'drop column SQL');
}

# --- Diff::Column alter (unsupported) ---
{
  my @ops = DBIO::SQLite::Diff::Column->diff(
    { t => [ { column_name => 'a', data_type => 'INTEGER', not_null => 0 } ] },
    { t => [ { column_name => 'a', data_type => 'TEXT',    not_null => 1 } ] },
    { t => {} }, { t => {} },
  );
  is($ops[0]->action, 'alter', 'alter op');
  like($ops[0]->as_sql, qr/not supported/, 'alter renders as comment');
}

# --- Diff::Column skips brand-new tables ---
{
  my @ops = DBIO::SQLite::Diff::Column->diff(
    {},
    { newtab => [ { column_name => 'id', data_type => 'INTEGER' } ] },
    {},
    { newtab => {} },
  );
  is(scalar @ops, 0, 'no col ops for tables also being created');
}

# --- Diff::Index create ---
{
  my @ops = DBIO::SQLite::Diff::Index->diff(
    {},
    {
      t => {
        idx_t_name => {
          index_name => 'idx_t_name',
          is_unique  => 1,
          columns    => ['name'],
          origin     => 'c',
          sql        => 'CREATE UNIQUE INDEX idx_t_name ON t(name)',
        },
      },
    },
  );
  is(scalar @ops, 1, 'one index create');
  is($ops[0]->as_sql, 'CREATE UNIQUE INDEX idx_t_name ON t(name);', 'preserves sqlite_master sql');
}

# --- Diff::Index skips auto-generated ---
{
  my @ops = DBIO::SQLite::Diff::Index->diff(
    {},
    {
      t => {
        sqlite_autoindex_t_1 => {
          index_name => 'sqlite_autoindex_t_1',
          is_unique  => 1,
          columns    => ['id'],
          origin     => 'pk',
        },
      },
    },
  );
  is(scalar @ops, 0, 'auto PK index skipped');
}

# --- Diff::Index drop ---
{
  my @ops = DBIO::SQLite::Diff::Index->diff(
    { t => { gone_idx => { index_name => 'gone_idx', columns => ['x'], origin => 'c' } } },
    {},
  );
  is($ops[0]->as_sql, 'DROP INDEX gone_idx;', 'drop index SQL');
}

# --- Diff::Index alter (drop+create pair) ---
{
  my @ops = DBIO::SQLite::Diff::Index->diff(
    { t => { idx => { index_name => 'idx', columns => ['a'], is_unique => 0, origin => 'c' } } },
    { t => { idx => { index_name => 'idx', columns => ['a', 'b'], is_unique => 0, origin => 'c' } } },
  );
  is(scalar @ops, 2, 'changed index produces drop+create');
  is($ops[0]->action, 'drop',   'drop first');
  is($ops[1]->action, 'create', 'create second');
}

# --- Top-level Diff orchestrator ---
{
  my $source = {
    tables       => {},
    columns      => {},
    indexes      => {},
    foreign_keys => {},
  };
  my $target = {
    tables  => { author => { table_name => 'author' } },
    columns => {
      author => [ { column_name => 'id', data_type => 'INTEGER', is_pk => 1 } ],
    },
    indexes      => {},
    foreign_keys => {},
  };
  my $diff = DBIO::SQLite::Diff->new(source => $source, target => $target);
  ok($diff->has_changes, 'has_changes');
  like($diff->as_sql,  qr/CREATE TABLE author/, 'as_sql contains create');
  like($diff->summary, qr/\+ table: author/,    'summary contains create line');
}

# --- No changes ---
{
  my $model = {
    tables       => { t => { table_name => 't' } },
    columns      => { t => [ { column_name => 'id', data_type => 'INTEGER' } ] },
    indexes      => {},
    foreign_keys => {},
  };
  my $diff = DBIO::SQLite::Diff->new(source => $model, target => $model);
  ok(!$diff->has_changes, 'identical models have no changes');
}

done_testing;
