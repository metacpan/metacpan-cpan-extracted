use strict;
use warnings;
use Test::More;

use_ok 'DBIO::MSSQL::Diff::Table';
use_ok 'DBIO::MSSQL::Diff::Column';
use_ok 'DBIO::MSSQL::Diff::Index';
use_ok 'DBIO::MSSQL::Diff::ForeignKey';
use_ok 'DBIO::MSSQL::Diff';

# --- Diff::Table create with columns + PK + identity ---
{
  my @ops = DBIO::MSSQL::Diff::Table->diff(
    {},
    { book => { table_name => 'book' } },
    {
      book => [
        { column_name => 'id',        data_type => 'int',     is_pk => 1, is_identity => 1, not_null => 1 },
        { column_name => 'author_id', data_type => 'int',     not_null => 1 },
        { column_name => 'title',     data_type => 'varchar', size => 255, not_null => 1 },
      ],
    },
  );
  is(scalar @ops, 1, 'one create op');
  is($ops[0]->action, 'create', 'create action');
  my $sql = $ops[0]->as_sql;
  like($sql, qr/CREATE TABLE book \(/,                'CREATE TABLE');
  like($sql, qr/id int NOT NULL IDENTITY\(1,1\)/,     'inline identity');
  like($sql, qr/title nvarchar\(255\) NOT NULL/,      'varchar maps to sized nvarchar');
  like($sql, qr/PRIMARY KEY \(id\)/,                  'inline PK');
  # karr k71: the table is created without its FK; the FK is a standalone
  # ADD CONSTRAINT after every table exists (Diff::ForeignKey, ordered by Diff)
  unlike($sql, qr/FOREIGN KEY/, 'no inline FK: it is added after all tables exist');
  is($ops[0]->summary, '+ table: book', 'create summary');
}

# --- Diff::Table drop ---
{
  my @ops = DBIO::MSSQL::Diff::Table->diff(
    { gone => { table_name => 'gone' } }, {},
  );
  is(scalar @ops, 1, 'one drop op');
  is($ops[0]->action, 'drop', 'drop action');
  is($ops[0]->as_sql, 'DROP TABLE gone;', 'drop SQL');
  is($ops[0]->summary, '- table: gone', 'drop summary');
}

# --- Diff::Column add ---
{
  my @ops = DBIO::MSSQL::Diff::Column->diff(
    { t => [ { column_name => 'id', data_type => 'int' } ] },
    {
      t => [
        { column_name => 'id',    data_type => 'int' },
        { column_name => 'extra', data_type => 'varchar', size => 50, not_null => 1 },
      ],
    },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'one add op');
  is($ops[0]->action, 'add', 'add action');
  is($ops[0]->as_sql, 'ALTER TABLE t ADD extra nvarchar(50) NOT NULL;', 'add SQL');
}

# --- Diff::Column alter (type changed) ---
#     karr k31: the assertion used to stop at 'a bigint;'. Same property --
#     a type change renders one ALTER COLUMN to the new type -- but the
#     statement now spells the nullability out, because "ANSI_NULL defaults are
#     always on for ALTER COLUMN; if not specified, the column is nullable":
#     the old form silently made every retyped NOT NULL column nullable.
{
  my @ops = DBIO::MSSQL::Diff::Column->diff(
    { t => [ { column_name => 'a', data_type => 'int' } ] },
    { t => [ { column_name => 'a', data_type => 'bigint' } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'one alter op');
  is($ops[0]->action, 'alter', 'alter action');
  is($ops[0]->as_sql, 'ALTER TABLE t ALTER COLUMN a bigint NULL;', 'alter type SQL');
}

# --- Diff::Column alter (nullability changed) ---
#     karr k31, CLAIM REPLACED. This asserted
#         qr/ALTER TABLE t ALTER COLUMN a NOT NULL;/
#     and the property it was sampling is the right one: a nullability-only
#     drift is detected and rendered as one ALTER COLUMN that makes t.a NOT
#     NULL. The spelling it pinned was not -- Transact-SQL has no typeless
#     ALTER COLUMN ("If you specify NULL or NOT NULL with ALTER COLUMN, you
#     must also specify new_data_type ... If the data type, precision, and
#     scale aren't changing, specify the current column values"), so the test
#     could stay green while every statement it described was rejected. The
#     assertion below measures the same property against a statement that
#     parses, and tightened to an exact match so a future regression cannot
#     hide in a substring.
{
  my @ops = DBIO::MSSQL::Diff::Column->diff(
    { t => [ { column_name => 'a', data_type => 'int', not_null => 0 } ] },
    { t => [ { column_name => 'a', data_type => 'int', not_null => 1 } ] },
    { t => {} }, { t => {} },
  );
  is($ops[0]->action, 'alter', 'alter action');
  is($ops[0]->as_sql, 'ALTER TABLE t ALTER COLUMN a int NOT NULL;', 'alter NOT NULL SQL');
}

# --- Diff::Column drop ---
{
  my @ops = DBIO::MSSQL::Diff::Column->diff(
    { t => [
      { column_name => 'id',  data_type => 'int' },
      { column_name => 'old', data_type => 'text' },
    ] },
    { t => [ { column_name => 'id', data_type => 'int' } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'one drop op');
  is($ops[0]->action, 'drop', 'drop action');
  is($ops[0]->as_sql, 'ALTER TABLE t DROP COLUMN old;', 'drop SQL');
}

# --- Diff::Index create (unique, nonclustered) ---
{
  my @ops = DBIO::MSSQL::Diff::Index->diff(
    { t => {} },
    { t => { idx_email => { is_unique => 1, kind => 'nonclustered', columns => ['email'] } } },
  );
  is(scalar @ops, 1, 'one create op');
  is($ops[0]->action, 'create', 'create action');
  is($ops[0]->as_sql,
    'CREATE UNIQUE NONCLUSTERED INDEX idx_email ON t (email);',
    'create index SQL');
  is($ops[0]->summary, '  +index: idx_email on t', 'create index summary');
}

# --- Diff::Index drop ---
{
  my @ops = DBIO::MSSQL::Diff::Index->diff(
    { t => { idx_old => { columns => ['x'] } } },
    { t => {} },
  );
  is(scalar @ops, 1, 'one drop op');
  is($ops[0]->action, 'drop', 'drop action');
  is($ops[0]->as_sql, 'DROP INDEX idx_old ON t;', 'drop index SQL');
}

# --- Diff::Index recreate on column change (drop + create) ---
{
  my @ops = DBIO::MSSQL::Diff::Index->diff(
    { t => { idx => { is_unique => 0, columns => ['a'] } } },
    { t => { idx => { is_unique => 0, columns => ['a', 'b'] } } },
  );
  is(scalar @ops, 2, 'two ops (drop + create)');
  is($ops[0]->action, 'drop',   'first is drop');
  is($ops[1]->action, 'create', 'second is create');
  like($ops[1]->as_sql, qr/\(a, b\)/, 'recreated with new columns');
}

# --- Diff::Index recreate on kind change (nonclustered -> clustered) ---
#     (karr k16) 'kind' must be part of the comparison spec, not just
#     read by as_sql -- otherwise a clustered/nonclustered flip on an
#     unchanged name/columns/uniqueness is never detected as a change.
{
  my @ops = DBIO::MSSQL::Diff::Index->diff(
    { t => { idx => { is_unique => 0, kind => 'nonclustered', columns => ['a'] } } },
    { t => { idx => { is_unique => 0, kind => 'clustered',    columns => ['a'] } } },
  );
  is(scalar @ops, 2, 'kind-only change -> two ops (drop + create)');
  is($ops[0]->action, 'drop',   'first is drop');
  is($ops[1]->action, 'create', 'second is create');
  is($ops[1]->as_sql, 'CREATE CLUSTERED INDEX idx ON t (a);', 'recreated with new kind, CLUSTERED before INDEX');
}

# --- Diff::Index: no standalone DROP INDEX when the owning table is dropped ---
#     (karr k15) The table is present in source tables, absent from target
#     tables -> DROP TABLE removes its indexes, so the standalone DROP INDEX
#     must be suppressed.
{
  my @ops = DBIO::MSSQL::Diff::Index->diff(
    { leftover => { idx_leftover => { columns => ['id'] } } },
    {},
    { leftover => { table_name => 'leftover' } },  # source: table exists live
    {},                                            # target: table gone -> dropped
  );
  is(scalar @ops, 0, 'no standalone DROP INDEX when owning table is dropped');
}

# --- Diff::Index guard: do NOT over-suppress. A table that survives but loses
#     one of its indexes must still get the standalone DROP INDEX (karr k15). ---
{
  my @ops = DBIO::MSSQL::Diff::Index->diff(
    { t => { idx_email => { columns => ['email'] } } },
    { t => {} },
    { t => { table_name => 't' } },   # source: t exists
    { t => { table_name => 't' } },   # target: t still exists -> only index dropped
  );
  is(scalar @ops, 1, 'index drop still emitted when the table itself survives');
  is($ops[0]->action, 'drop', 'surviving-table index drop is a drop op');
  is($ops[0]->as_sql, 'DROP INDEX idx_email ON t;', 'surviving-table index still dropped standalone');
}

# --- Full Diff orchestrator: source vs target model ---
{
  my $source = {
    tables  => { keep => { table_name => 'keep' }, drop_me => { table_name => 'drop_me' } },
    columns => { keep => [ { column_name => 'id', data_type => 'int' } ] },
    indexes => {},
  };
  my $target = {
    tables  => { keep => { table_name => 'keep' }, new_tbl => { table_name => 'new_tbl' } },
    columns => {
      keep    => [
        { column_name => 'id',  data_type => 'int' },
        { column_name => 'name', data_type => 'varchar', size => 100, not_null => 1 },
      ],
      new_tbl => [ { column_name => 'id', data_type => 'int', is_pk => 1, not_null => 1 } ],
    },
    foreign_keys => {},
    indexes => { keep => { idx_name => { columns => ['name'] } } },
  };

  my $diff = DBIO::MSSQL::Diff->new(source => $source, target => $target);
  ok($diff->has_changes, 'has changes');

  my $sql = $diff->as_sql;
  like($sql, qr/CREATE TABLE new_tbl/,           'creates new table');
  like($sql, qr/DROP TABLE drop_me;/,            'drops removed table');
  like($sql, qr/ALTER TABLE keep ADD name/,      'adds column to kept table');
  like($sql, qr/CREATE INDEX idx_name ON keep/,  'creates index');

  my $summary = $diff->summary;
  like($summary, qr/\+ table: new_tbl/, 'summary lists new table');
  like($summary, qr/- table: drop_me/, 'summary lists dropped table');
}

# --- Empty diff: identical models, no changes ---
{
  my $model = { tables => {}, columns => {}, indexes => {}, foreign_keys => {} };
  my $diff = DBIO::MSSQL::Diff->new(source => $model, target => $model);
  ok(!$diff->has_changes, 'no changes for identical empty models');
  is($diff->as_sql,  '', 'empty SQL');
}

# --- Diff::ForeignKey add (FK new on a table present in both models) ---
{
  my $src_t = { cd => { table_name => 'cd' }, artist => { table_name => 'artist' } };
  my @ops = DBIO::MSSQL::Diff::ForeignKey->diff(
    { cd => [] },
    { cd => [ { constraint_name => 'FK_cd_artist', from_columns => ['artist_id'],
               to_table => 'artist', to_columns => ['id'],
               on_delete => 'CASCADE', on_update => 'NO ACTION' } ] },
    $src_t, $src_t,
  );
  is(scalar @ops, 1, 'one add op');
  is($ops[0]->action, 'add', 'add action');
  is($ops[0]->as_sql,
    'ALTER TABLE cd ADD CONSTRAINT FK_cd_artist FOREIGN KEY (artist_id) REFERENCES artist(id) ON DELETE CASCADE;',
    'add FK SQL (NO ACTION update omitted)');
  is($ops[0]->summary, '  +fk: FK_cd_artist on cd', 'add FK summary');
}

# --- Diff::ForeignKey drop ---
{
  my $t = { cd => { table_name => 'cd' } };
  my @ops = DBIO::MSSQL::Diff::ForeignKey->diff(
    { cd => [ { constraint_name => 'FK_old', from_columns => ['x'], to_table => 'y', to_columns => ['z'] } ] },
    { cd => [] },
    $t, $t,
  );
  is(scalar @ops, 1, 'one drop op');
  is($ops[0]->action, 'drop', 'drop action');
  is($ops[0]->as_sql, 'ALTER TABLE cd DROP CONSTRAINT FK_old;', 'drop FK SQL');
}

# --- Diff::ForeignKey modify (changed target table -> drop + add) ---
{
  my $t = { cd => { table_name => 'cd' } };
  my @ops = DBIO::MSSQL::Diff::ForeignKey->diff(
    { cd => [ { constraint_name => 'FK', from_columns => ['a'], to_table => 'old', to_columns => ['id'] } ] },
    { cd => [ { constraint_name => 'FK', from_columns => ['a'], to_table => 'new', to_columns => ['id'] } ] },
    $t, $t,
  );
  is(scalar @ops, 2, 'two ops (drop + add)');
  is($ops[0]->action, 'drop', 'first is drop');
  is($ops[1]->action, 'add',  'second is add');
  like($ops[1]->as_sql, qr/REFERENCES new\(id\)/, 're-added against new table');
}

# --- Diff::ForeignKey: FK on a brand-new table IS emitted here (karr k71):
#     Diff::Table creates the table without it ---
{
  my @ops = DBIO::MSSQL::Diff::ForeignKey->diff(
    {},
    { fresh => [ { constraint_name => 'FK', from_columns => ['a'], to_table => 't', to_columns => ['id'] } ] },
    {},                                  # source has no tables
    { fresh => { table_name => 'fresh' } },
  );
  is(scalar @ops, 1, 'standalone FK add for a brand-new table');
  is($ops[0]->action, 'add', '... an add');
}

# --- Index column order is significant (drop+create on reorder) ---
{
  my @ops = DBIO::MSSQL::Diff::Index->diff(
    { t => { idx => { is_unique => 0, columns => ['a', 'b'] } } },
    { t => { idx => { is_unique => 0, columns => ['b', 'a'] } } },
  );
  is(scalar @ops, 2, 'reordered composite index -> drop + create');
  is($ops[0]->action, 'drop',   'first is drop');
  is($ops[1]->action, 'create', 'second is create');
}

# --- Full Diff orchestrator emits FK ops on an existing table ---
{
  my $source = {
    tables  => { cd => { table_name => 'cd' }, artist => { table_name => 'artist' } },
    columns => {}, indexes => {},
    foreign_keys => { cd => [] },
  };
  my $target = {
    tables  => { cd => { table_name => 'cd' }, artist => { table_name => 'artist' } },
    columns => {}, indexes => {},
    foreign_keys => { cd => [ { constraint_name => 'FK_cd_artist',
      from_columns => ['artist_id'], to_table => 'artist', to_columns => ['id'] } ] },
  };
  my $diff = DBIO::MSSQL::Diff->new(source => $source, target => $target);
  like($diff->as_sql, qr/ALTER TABLE cd ADD CONSTRAINT FK_cd_artist FOREIGN KEY/,
    'orchestrator emits standalone FK add for existing table');
}

# --- Views are not tables (karr k45). The introspected model keeps views in
#     `tables` with kind => 'view'; the diff used to emit CREATE TABLE for a
#     declared one, DROP TABLE for a live-only one and ALTER TABLE / CREATE
#     INDEX against a view. The model carries no view definition, so a view is
#     left out of the diff and named in the summary.
{
  my @ops = DBIO::MSSQL::Diff::Table->diff(
    { old_v => { table_name => 'old_v', kind => 'view' } },
    { v     => { table_name => 'v',     kind => 'view' } },
    { v     => [ { column_name => 'a', data_type => 'int' } ] },
  );
  is(scalar @ops, 0, 'Diff::Table: no CREATE TABLE / DROP TABLE for a view');

  @ops = DBIO::MSSQL::Diff::Table->diff(
    { t => { table_name => 't', kind => 'table' }, old_v => { table_name => 'old_v', kind => 'view' } },
    { t => { table_name => 't', kind => 'table' }, n => { table_name => 'n', kind => 'table' },
      v => { table_name => 'v', kind => 'view' } },
    { n => [ { column_name => 'id', data_type => 'int' } ] },
  );
  is_deeply([ map { $_->action . ' ' . $_->table_name } @ops ], ['create n'],
    'Diff::Table: a table beside a view is still diffed');

  my %views = (
    s => { v => { table_name => 'v', kind => 'view' }, t => { table_name => 't', kind => 'table' } },
    t => { v => { table_name => 'v', kind => 'view' }, t => { table_name => 't', kind => 'table' } },
  );
  @ops = DBIO::MSSQL::Diff::Column->diff(
    { v => [ { column_name => 'a', data_type => 'int' } ] },
    { v => [ { column_name => 'a', data_type => 'int' }, { column_name => 'b', data_type => 'int' } ] },
    $views{s}, $views{t},
  );
  is(scalar @ops, 0, 'Diff::Column: no ALTER TABLE ... ADD/DROP COLUMN on a view');

  @ops = DBIO::MSSQL::Diff::Index->diff(
    { v => { ix_old => { columns => ['a'] } } },
    { v => { ix_new => { columns => ['b'] } } },
    $views{s}, $views{t},
  );
  is(scalar @ops, 0, 'Diff::Index: no CREATE/DROP INDEX on a view');

  @ops = DBIO::MSSQL::Diff::Column->diff(
    { t => [] }, { t => [ { column_name => 'b', data_type => 'int' } ] },
    $views{s}, $views{t},
  );
  is(scalar @ops, 1, 'Diff::Column: the table beside the view is still diffed');
}

# --- Full orchestrator: views are diffed by Diff::View (karr k82; t/125 has
#     the statements). A view in both models with the same body is no change.
{
  my $mk = sub { my ($name, $def) = @_; +{ tables => { $name => { table_name => $name, kind => 'view', definition => $def } },
    columns => { $name => [ { column_name => 'a', data_type => 'int' } ] }, indexes => {}, foreign_keys => {} } };
  my $diff = DBIO::MSSQL::Diff->new(
    source => $mk->('v', 'CREATE VIEW [dbo].[v] AS SELECT 1 AS a'),
    target => $mk->('v', "CREATE VIEW v AS\nSELECT   1 AS a;"));
  ok(!$diff->has_changes, 'a view with the same body: no operation');
  unlike($diff->as_sql, qr/TABLE|INDEX/, 'views alone: no table SQL');
  ok(!$diff->can('skipped_views'), 'skipped_views is gone: views are diffed');
}

done_testing;
