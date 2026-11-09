use strict;
use warnings;
use Test::More;

# Offline diff tests — no live DB. Diff op classes are pure: they take
# introspected model hashrefs and return op objects responding to
# as_sql / summary. See dbio-sqlite/t/31-diff.t for the model.

use_ok 'DBIO::Informix::Diff::Table';
use_ok 'DBIO::Informix::Diff::Column';
use_ok 'DBIO::Informix::Diff::Index';
use_ok 'DBIO::Informix::Diff::ForeignKey';
use_ok 'DBIO::Informix::Diff';

# --- Diff::Table create ---
{
  my @ops = DBIO::Informix::Diff::Table->diff(
    {},
    { author => { table_name => 'author' } },
    {
      author => [
        { column_name => 'id',   data_type => 'integer', is_pk => 1, not_null => 0 },
        { column_name => 'name', data_type => 'varchar(255)', is_pk => 0, not_null => 1 },
      ],
    },
    { author => [] },
  );
  is(scalar @ops, 1, 'one create op');
  is($ops[0]->action, 'create', 'action create');
  is($ops[0]->table_name, 'author', 'table_name');
  my $sql = $ops[0]->as_sql;
  like($sql, qr/CREATE TABLE author/,        'create table');
  like($sql, qr/id integer/,                 'id column inline');
  like($sql, qr/name varchar\(255\) NOT NULL/, 'name column with NOT NULL');
  is($ops[0]->summary, '+ table: author',    'create summary');
}

# --- Diff::Table create with FK ---
{
  my @ops = DBIO::Informix::Diff::Table->diff(
    {},
    { book => { table_name => 'book' } },
    {
      book => [
        { column_name => 'id',        data_type => 'integer', is_pk => 1 },
        { column_name => 'author_id', data_type => 'integer', not_null => 1 },
      ],
    },
    {
      book => [
        { from_columns => ['author_id'], to_table => 'author', to_columns => ['id'] },
      ],
    },
  );
  unlike($ops[0]->as_sql, qr/FOREIGN KEY/,
    'no inline FK: the referenced table may be created later (karr k19)');
}

# --- Diff::Table single-column PK (karr k16) ---
{
  my @ops = DBIO::Informix::Diff::Table->diff(
    {},
    { solo => { table_name => 'solo' } },
    {
      solo => [
        { column_name => 'id',   data_type => 'integer', is_pk => 1, not_null => 1 },
        { column_name => 'name', data_type => 'varchar(255)', is_pk => 0 },
      ],
    },
    {},
  );
  like($ops[0]->as_sql, qr/PRIMARY KEY \(id\)/, 'single-column PK emitted');
}

# --- Diff::Table composite PK follows pk_position, not column order ---
{
  my @ops = DBIO::Informix::Diff::Table->diff(
    {},
    { ord => { table_name => 'ord' } },
    {
      ord => [
        { column_name => 'a', data_type => 'integer', is_pk => 1, pk_position => 2 },
        { column_name => 'b', data_type => 'integer', is_pk => 1, pk_position => 1 },
      ],
    },
    {},
  );
  like($ops[0]->as_sql, qr/PRIMARY KEY \(b, a\)/, 'PK columns in pk_position order');
}

# --- Diff::Table multi-column PK ---
{
  my @ops = DBIO::Informix::Diff::Table->diff(
    {},
    { mtm => { table_name => 'mtm' } },
    {
      mtm => [
        { column_name => 'a', data_type => 'integer', is_pk => 1 },
        { column_name => 'b', data_type => 'integer', is_pk => 1 },
      ],
    },
    {},
  );
  like($ops[0]->as_sql, qr/PRIMARY KEY \(a, b\)/, 'multi-col PK as constraint');
}

# --- Diff::Table drop ---
{
  my @ops = DBIO::Informix::Diff::Table->diff(
    { gone => { table_name => 'gone' } },
    {},
  );
  is($ops[0]->action, 'drop',             'drop op');
  is($ops[0]->as_sql, 'DROP TABLE gone;', 'drop SQL');
  is($ops[0]->summary, '- table: gone',   'drop summary');
}

# --- Diff::Column add ---
{
  my @ops = DBIO::Informix::Diff::Column->diff(
    { t => [ { column_name => 'id', data_type => 'integer' } ] },
    {
      t => [
        { column_name => 'id',    data_type => 'integer' },
        { column_name => 'extra', data_type => 'varchar(255)', not_null => 0 },
      ],
    },
    { t => 1 }, { t => 1 },
  );
  is(scalar @ops, 1, 'one add op');
  is($ops[0]->action, 'add', 'action add');
  is($ops[0]->as_sql, 'ALTER TABLE t ADD (extra varchar(255));', 'add SQL');
  is($ops[0]->summary, '+ column: t.extra', 'add summary');
}

# --- Diff::Column add NOT NULL with default ---
{
  my @ops = DBIO::Informix::Diff::Column->diff(
    { t => [ { column_name => 'id', data_type => 'integer' } ] },
    {
      t => [
        { column_name => 'id',   data_type => 'integer' },
        { column_name => 'flag', data_type => 'integer', not_null => 1, default_value => '0' },
      ],
    },
    { t => 1 }, { t => 1 },
  );
  like($ops[0]->as_sql, qr/integer DEFAULT 0 NOT NULL/, 'DEFAULT before NOT NULL in add');
}

# --- Diff::Column drop ---
{
  my @ops = DBIO::Informix::Diff::Column->diff(
    {
      t => [
        { column_name => 'id',  data_type => 'integer' },
        { column_name => 'old', data_type => 'varchar(255)' },
      ],
    },
    { t => [ { column_name => 'id', data_type => 'integer' } ] },
    { t => 1 }, { t => 1 },
  );
  is(scalar @ops, 1, 'one drop op');
  is($ops[0]->action, 'drop', 'action drop');
}

# --- Diff::Column alter: data type change ---
{
  my @ops = DBIO::Informix::Diff::Column->diff(
    { t => [ { column_name => 'name', data_type => 'varchar(64)' } ] },
    { t => [ { column_name => 'name', data_type => 'varchar(255)' } ] },
    { t => 1 }, { t => 1 },
  );
  is(scalar @ops, 1, 'type change → one alter op');
  is($ops[0]->action, 'alter', 'action alter');
  is($ops[0]->as_sql, 'ALTER TABLE t MODIFY (name varchar(255));', 'MODIFY SQL for type change');
  is($ops[0]->summary, '~ column: t.name', 'alter summary');
}

# --- Diff::Column alter: nullability change ---
{
  my @ops = DBIO::Informix::Diff::Column->diff(
    { t => [ { column_name => 'name', data_type => 'varchar(255)', not_null => 0 } ] },
    { t => [ { column_name => 'name', data_type => 'varchar(255)', not_null => 1 } ] },
    { t => 1 }, { t => 1 },
  );
  is(scalar @ops, 1, 'null change → one alter op');
  is($ops[0]->as_sql, 'ALTER TABLE t MODIFY (name varchar(255) NOT NULL);', 'MODIFY with NOT NULL');
}

# --- Diff::Column alter: default change ---
{
  my @ops = DBIO::Informix::Diff::Column->diff(
    { t => [ { column_name => 'flag', data_type => 'integer', default_value => '0' } ] },
    { t => [ { column_name => 'flag', data_type => 'integer', default_value => '1' } ] },
    { t => 1 }, { t => 1 },
  );
  is(scalar @ops, 1, 'default change → one alter op');
  is($ops[0]->as_sql, 'ALTER TABLE t MODIFY (flag integer DEFAULT 1);', 'MODIFY with DEFAULT');
}

# --- Diff::Column alter: SCALAR ref default (literal) ---
{
  my @ops = DBIO::Informix::Diff::Column->diff(
    { t => [ { column_name => 'ts', data_type => 'datetime year to second', default_value => undef } ] },
    { t => [ { column_name => 'ts', data_type => 'datetime year to second', default_value => \'today' } ] },
    { t => 1 }, { t => 1 },
  );
  is(scalar @ops, 1, 'literal default change → one alter op');
  is($ops[0]->as_sql, 'ALTER TABLE t MODIFY (ts datetime year to second DEFAULT today);', 'literal default unquoted');
}

# --- Diff::Column: identical column → no op ---
{
  my @ops = DBIO::Informix::Diff::Column->diff(
    { t => [ { column_name => 'id', data_type => 'integer', not_null => 1, default_value => undef } ] },
    { t => [ { column_name => 'id', data_type => 'integer', not_null => 1, default_value => undef } ] },
    { t => 1 }, { t => 1 },
  );
  is(scalar @ops, 0, 'identical column produces no op');
}

# --- Diff::Index create ---
{
  my @ops = DBIO::Informix::Diff::Index->diff(
    {},
    { t => { idx_name => { columns => ['name'], unique => 0 } } },
  );
  is(scalar @ops, 1, 'one create index op');
  is($ops[0]->action, 'create', 'action create');
  is($ops[0]->as_sql, 'CREATE INDEX idx_name ON t (name);', 'create index SQL');
}

# --- Diff::Index create unique ---
{
  my @ops = DBIO::Informix::Diff::Index->diff(
    {},
    { t => { uq => { columns => ['a', 'b'], unique => 1 } } },
  );
  is($ops[0]->as_sql, 'CREATE UNIQUE INDEX uq ON t (a, b);', 'unique multi-col index');
}

# --- Diff::Index drop ---
{
  my @ops = DBIO::Informix::Diff::Index->diff(
    { t => { old_idx => { columns => ['x'], unique => 0 } } },
    {},
  );
  is($ops[0]->action, 'drop',                  'drop index op');
  is($ops[0]->as_sql, 'DROP INDEX old_idx;',   'drop index SQL');
}

# --- Diff::Index change: column list changed → drop + create pair ---
{
  my @ops = DBIO::Informix::Diff::Index->diff(
    { t => { idx => { columns => ['a'], unique => 0 } } },
    { t => { idx => { columns => ['a', 'b'], unique => 0 } } },
  );
  is(scalar @ops, 2, 'index change → drop + create pair');
  is($ops[0]->action, 'drop',   'first op is drop');
  is($ops[1]->action, 'create', 'second op is create');
  is($ops[0]->as_sql, 'DROP INDEX idx;',                 'drop SQL');
  like($ops[1]->as_sql, qr/CREATE INDEX idx ON t \(a, b\)/, 're-create SQL with new cols');
}

# --- Diff::Index change: unique flag flipped → drop + create pair ---
{
  my @ops = DBIO::Informix::Diff::Index->diff(
    { t => { idx => { columns => ['a'], unique => 0 } } },
    { t => { idx => { columns => ['a'], unique => 1 } } },
  );
  is(scalar @ops, 2, 'unique flag change → drop + create pair');
  like($ops[1]->as_sql, qr/CREATE UNIQUE INDEX/, 're-create as UNIQUE');
}

# --- Diff orchestrator: full model, mixed ops ---
{
  my $source = {
    tables  => { keep => { table_name => 'keep' }, gone => { table_name => 'gone' } },
    columns => {
      keep => [ { column_name => 'id', data_type => 'integer', not_null => 1 } ],
      gone => [ { column_name => 'id', data_type => 'integer' } ],
    },
    indexes      => {},
    foreign_keys => {},
  };
  my $target = {
    tables  => { keep => { table_name => 'keep' }, fresh => { table_name => 'fresh' } },
    columns => {
      keep  => [ { column_name => 'id', data_type => 'bigint', not_null => 1 } ],
      fresh => [ { column_name => 'id', data_type => 'integer', is_pk => 1 } ],
    },
    indexes      => { fresh => { fresh_idx => { columns => ['id'], unique => 1 } } },
    foreign_keys => {},
  };

  my $diff = DBIO::Informix::Diff->new(source => $source, target => $target);
  ok($diff->has_changes, 'has_changes true');

  my $sql = $diff->as_sql;
  like($sql, qr/CREATE TABLE fresh/,                  'creates fresh table');
  like($sql, qr/DROP TABLE gone;/,                    'drops gone table');
  like($sql, qr/ALTER TABLE keep MODIFY \(id bigint NOT NULL\);/, 'alters keep.id type');
  like($sql, qr/CREATE UNIQUE INDEX fresh_idx/,       'creates fresh index');

  my $summary = $diff->summary;
  like($summary, qr/~ column: keep\.id/, 'summary includes alter');
}

# --- Diff orchestrator: no changes ---
{
  my $model = {
    tables       => { t => { table_name => 't' } },
    columns      => { t => [ { column_name => 'id', data_type => 'integer' } ] },
    indexes      => {},
    foreign_keys => {},
  };
  my $diff = DBIO::Informix::Diff->new(source => $model, target => $model);
  ok(!$diff->has_changes, 'identical model → no changes');
  is($diff->as_sql, '', 'empty SQL');
}

done_testing;
