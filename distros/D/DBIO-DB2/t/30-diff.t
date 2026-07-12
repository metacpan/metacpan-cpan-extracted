use strict;
use warnings;
use Test::More;

# Offline Diff coverage -- no real DB2. Exercises the diff op classes
# directly with mock introspection models (DBIO core convention).
# Models mirror DBIO::DB2::Introspect's shape:
#   { tables, columns, indexes, foreign_keys }

use_ok 'DBIO::DB2::Diff::Table';
use_ok 'DBIO::DB2::Diff::Column';
use_ok 'DBIO::DB2::Diff::Index';
use_ok 'DBIO::DB2::Diff::ForeignKey';
use_ok 'DBIO::DB2::Diff';
use_ok 'DBIO::DB2::DDL';

# --- Diff::Table create (PK + type mapping) ---
{
  my @ops = DBIO::DB2::Diff::Table->diff(
    {},
    { author => { table_name => 'author' } },
    {
      author => [
        { column_name => 'id',   data_type => 'integer', is_pk => 1, not_null => 0 },
        { column_name => 'name', data_type => 'varchar',  size => 255, not_null => 1 },
      ],
    },
    { author => [] },
  );
  is(scalar @ops, 1, 'one create op');
  is($ops[0]->action, 'create', 'action create');
  is($ops[0]->table_name, 'author', 'table_name');
  my $sql = $ops[0]->as_sql;
  like($sql, qr/CREATE TABLE author/,       'create table');
  like($sql, qr/id INTEGER/,                'id mapped to INTEGER');
  like($sql, qr/name VARCHAR\(255\) NOT NULL/, 'name VARCHAR(255) NOT NULL');
  like($sql, qr/PRIMARY KEY \(id\)/,        'inline PK constraint');
}

# --- Diff::Table create with FK ---
# The FK in the target model is introspected from the install_ddl-built compare
# schema, so it already carries the deterministic constraint_name and the
# referential rules. The create path must render them as a NAMED inline
# constraint with the rule -- NOT regenerate the name, NOT drop the rule. WHY:
#   1. a server-assigned name would phantom-drop+add on the next compare
#      (name-based FK identity mismatch vs the install_ddl-built target);
#   2. dropping ON DELETE would silently fail to enforce the declared rule.
# These two like()/unlike() assertions fail if the create path reverts to the
# old unnamed/ruleless `FOREIGN KEY (...) REFERENCES ...` shape (ADR 0005).
{
  my @ops = DBIO::DB2::Diff::Table->diff(
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
        {
          constraint_name => 'fk_book_author_id',
          from_columns => ['author_id'], to_table => 'author',
          to_columns => ['id'], on_delete => 'CASCADE', on_update => 'NO ACTION',
        },
      ],
    },
  );
  my $sql = $ops[0]->as_sql;
  like($sql,
    qr/CONSTRAINT fk_book_author_id FOREIGN KEY \(author_id\) REFERENCES author\(id\) ON DELETE CASCADE/,
    'inline FK is NAMED with deterministic name and renders ON DELETE CASCADE');
  unlike($sql, qr/ON UPDATE/, 'NO ACTION on_update suppressed on inline FK');
  unlike($sql, qr/[^_]FOREIGN KEY \(author_id\) REFERENCES author\(id\)[,\s)]*$/m,
    'no unnamed/ruleless FOREIGN KEY clause remains');
}

# --- Diff::Table create-path FK matches install_ddl byte-for-byte ---
# Locks the two inline FK renderers (DDL.pm + Diff::Table) to a single shape:
# the create-op CREATE TABLE must contain the exact same FK clause line that
# install_ddl emits for the same FK. Fails if either renderer drifts.
{
  my $fk = {
    constraint_name => 'fk_book_author_id',
    from_columns => ['author_id'], to_table => 'author',
    to_columns => ['id'], on_delete => 'CASCADE', on_update => 'NO ACTION',
  };
  my @ops = DBIO::DB2::Diff::Table->diff(
    {},
    { book => { table_name => 'book' } },
    { book => [ { column_name => 'author_id', data_type => 'integer' } ] },
    { book => [ $fk ] },
  );
  my $clause = DBIO::DB2::DDL::_fk_constraint_clause($fk);
  like($ops[0]->as_sql, qr/\Q  $clause\E/,
    'create-path FK clause is the shared DDL clause (single source of truth)');
}

# --- Diff::Table multi-column PK ---
{
  my @ops = DBIO::DB2::Diff::Table->diff(
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
  my @ops = DBIO::DB2::Diff::Table->diff(
    { gone => { table_name => 'gone' } },
    {},
  );
  is($ops[0]->action, 'drop',             'drop op');
  is($ops[0]->as_sql, 'DROP TABLE gone;', 'drop SQL');
  is($ops[0]->summary, '- table: gone',   'drop summary');
}

# --- Diff::Column add ---
{
  my @ops = DBIO::DB2::Diff::Column->diff(
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
  is($ops[0]->as_sql, 'ALTER TABLE t ADD COLUMN extra VARCHAR;', 'add SQL');
}

# --- Diff::Column add NOT NULL with default ---
{
  my @ops = DBIO::DB2::Diff::Column->diff(
    { t => [ { column_name => 'id', data_type => 'integer' } ] },
    {
      t => [
        { column_name => 'id',   data_type => 'integer' },
        { column_name => 'flag', data_type => 'integer', not_null => 1, default_value => '0' },
      ],
    },
    { t => {} }, { t => {} },
  );
  like($ops[0]->as_sql, qr/NOT NULL DEFAULT 0/, 'NOT NULL DEFAULT in add');
}

# --- Diff::Column drop ---
{
  my @ops = DBIO::DB2::Diff::Column->diff(
    {
      t => [
        { column_name => 'id',  data_type => 'integer' },
        { column_name => 'old', data_type => 'varchar' },
      ],
    },
    { t => [ { column_name => 'id', data_type => 'integer' } ] },
    { t => {} }, { t => {} },
  );
  is($ops[0]->action, 'drop', 'drop op');
  is($ops[0]->as_sql, 'ALTER TABLE t DROP COLUMN old;', 'drop column SQL');
}

# --- Diff::Column alter type + NOT NULL (DB2 supports ALTER COLUMN) ---
{
  my @ops = DBIO::DB2::Diff::Column->diff(
    { t => [ { column_name => 'a', data_type => 'integer', not_null => 0 } ] },
    { t => [ { column_name => 'a', data_type => 'varchar', size => 50, not_null => 1 } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1,        'one alter op');
  is($ops[0]->action, 'alter', 'action alter');
  my $sql = $ops[0]->as_sql;
  like($sql, qr/ALTER TABLE t ALTER COLUMN a SET DATA TYPE VARCHAR\(50\);/, 'SET DATA TYPE');
  like($sql, qr/ALTER TABLE t ALTER COLUMN a SET NOT NULL;/,               'SET NOT NULL');
}

# --- Diff::Column alter default change + drop NOT NULL ---
{
  my @ops = DBIO::DB2::Diff::Column->diff(
    { t => [ { column_name => 'a', data_type => 'integer', not_null => 1, default_value => '1' } ] },
    { t => [ { column_name => 'a', data_type => 'integer', not_null => 0, default_value => '2' } ] },
    { t => {} }, { t => {} },
  );
  my $sql = $ops[0]->as_sql;
  like($sql, qr/ALTER COLUMN a DROP NOT NULL;/,    'DROP NOT NULL');
  like($sql, qr/ALTER COLUMN a SET DEFAULT 2;/,    'SET DEFAULT');
}

# --- Diff::Column drop DEFAULT ---
# Under DBIO::Diff::Compare desired-state semantics, a target column that simply
# omits default_value is "don't care" -- diff() emits no alter. The as_sql
# DROP DEFAULT rendering is exercised directly on an explicit alter op.
{
  my @ops = DBIO::DB2::Diff::Column->diff(
    { t => [ { column_name => 'a', data_type => 'integer', default_value => '5' } ] },
    { t => [ { column_name => 'a', data_type => 'integer' } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 0, 'omitted target default is not a change (desired-state)');

  my $op = DBIO::DB2::Diff::Column->new(
    action => 'alter', table_name => 't', column_name => 'a',
    old_info => { data_type => 'integer', default_value => '5' },
    new_info => { data_type => 'integer', default_value => undef },
  );
  like($op->as_sql, qr/ALTER COLUMN a DROP DEFAULT;/, 'as_sql renders DROP DEFAULT');
}

# --- Diff::Column skips brand-new tables ---
{
  my @ops = DBIO::DB2::Diff::Column->diff(
    {},
    { newtab => [ { column_name => 'id', data_type => 'integer' } ] },
    {},          # source_tables: newtab absent -> table being created
    { newtab => {} },
  );
  is(scalar @ops, 0, 'no col ops for tables also being created');
}

# --- Diff::Index create ---
{
  my @ops = DBIO::DB2::Diff::Index->diff(
    {},
    {
      t => {
        idx_t_name => {
          index_name => 'idx_t_name',
          is_unique  => 1,
          columns    => ['name'],
        },
      },
    },
  );
  is(scalar @ops, 1, 'one index create');
  is($ops[0]->action, 'create', 'action create');
  is($ops[0]->as_sql, 'CREATE UNIQUE INDEX idx_t_name ON t (name);', 'unique index SQL');
}

# --- Diff::Index create non-unique multi-column ---
{
  my @ops = DBIO::DB2::Diff::Index->diff(
    {},
    {
      t => {
        idx_ab => { index_name => 'idx_ab', is_unique => 0, columns => ['a', 'b'] },
      },
    },
  );
  is($ops[0]->as_sql, 'CREATE INDEX idx_ab ON t (a, b);', 'non-unique multi-col index');
}

# --- Diff::Index drop ---
{
  my @ops = DBIO::DB2::Diff::Index->diff(
    { t => { gone_idx => { index_name => 'gone_idx', columns => ['x'] } } },
    {},
  );
  is($ops[0]->action, 'drop',                 'drop op');
  is($ops[0]->as_sql, 'DROP INDEX gone_idx;', 'drop index SQL');
}

# --- Diff::Index alter (drop+create pair) ---
{
  my @ops = DBIO::DB2::Diff::Index->diff(
    { t => { idx => { index_name => 'idx', columns => ['a'],      is_unique => 0 } } },
    { t => { idx => { index_name => 'idx', columns => ['a', 'b'], is_unique => 0 } } },
  );
  is(scalar @ops, 2,          'changed index produces drop+create');
  is($ops[0]->action, 'drop',   'drop first');
  is($ops[1]->action, 'create', 'create second');
}

# --- Diff::Index: suppress DROP INDEX when the owning table is dropped (karr #19) ---
# When the owning table is itself being dropped in the same pass (present in
# source tables, absent from target tables), DB2's DROP TABLE already removes the
# table's indexes, so no standalone DROP INDEX must be emitted for them.
{
  my @ops = DBIO::DB2::Diff::Index->diff(
    { leftover => { idx_leftover => { index_name => 'idx_leftover', columns => ['id'] } } },
    {},
    { leftover => { table_name => 'leftover' } }, # source tables: leftover exists live
    {},                                           # target tables: it is gone -> being dropped
  );
  is(scalar @ops, 0, 'no standalone DROP INDEX when owning table is dropped (DROP TABLE covers it)');
}

# --- Diff::Index: over-suppression guard -- surviving table still drops its index (karr #19) ---
# If the table stays but one of its indexes is removed, the standalone DROP INDEX
# is still required.
{
  my @ops = DBIO::DB2::Diff::Index->diff(
    { users => { idx_users_email => { index_name => 'idx_users_email', columns => ['email'] } } },
    {},
    { users => { table_name => 'users' } }, # source tables: users exists
    { users => { table_name => 'users' } }, # target tables: users still exists -> only index dropped
  );
  is(scalar @ops, 1,           'index drop still emitted when the table itself survives');
  is($ops[0]->action, 'drop',  'surviving-table index drop is a drop op');
  is($ops[0]->as_sql, 'DROP INDEX idx_users_email;', 'surviving-table index still dropped standalone');
}

# --- Top-level Diff orchestrator: create from empty ---
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
      author => [ { column_name => 'id', data_type => 'integer', is_pk => 1 } ],
    },
    indexes      => {},
    foreign_keys => {},
  };
  my $diff = DBIO::DB2::Diff->new(source => $source, target => $target);
  ok($diff->has_changes, 'has_changes');
  like($diff->as_sql,  qr/CREATE TABLE author/, 'as_sql contains create');
  like($diff->summary, qr/\+ table: author/,    'summary contains create line');
}

# --- Top-level Diff orchestrator: dependency ordering ---
{
  # Existing table gets a new column; a new table is created; an old index dropped.
  my $source = {
    tables       => { keep => { table_name => 'keep' } },
    columns      => { keep => [ { column_name => 'id', data_type => 'integer' } ] },
    indexes      => { keep => { old_idx => { index_name => 'old_idx', columns => ['id'] } } },
    foreign_keys => {},
  };
  my $target = {
    tables  => {
      keep => { table_name => 'keep' },
      fresh => { table_name => 'fresh' },
    },
    columns => {
      keep  => [
        { column_name => 'id',  data_type => 'integer' },
        { column_name => 'note', data_type => 'varchar' },
      ],
      fresh => [ { column_name => 'id', data_type => 'integer', is_pk => 1 } ],
    },
    indexes      => {},
    foreign_keys => {},
  };
  my $diff = DBIO::DB2::Diff->new(source => $source, target => $target);
  my @ops = @{ $diff->operations };
  # tables first, then columns, then indexes
  isa_ok($ops[0],  'DBIO::DB2::Diff::Table',  'first op is a table op');
  isa_ok($ops[-1], 'DBIO::DB2::Diff::Index',  'last op is an index op');
  like($diff->as_sql, qr/CREATE TABLE fresh/,            'new table created');
  like($diff->as_sql, qr/ADD COLUMN note/,               'column added to existing table');
  like($diff->as_sql, qr/DROP INDEX old_idx/,            'stale index dropped');
}

# --- Diff::ForeignKey: ADD on a retained table ---
{
  # book exists in both; target gains an FK to author. Both tables present in
  # both -> scope 'both' considers the FK pass.
  my $src_tables = { author => {}, book => {} };
  my $tgt_tables = { author => {}, book => {} };
  my @ops = DBIO::DB2::Diff::ForeignKey->diff(
    { book => [] },
    {
      book => [
        {
          constraint_name => 'fk_book_author_id',
          from_columns => ['author_id'], to_table => 'author',
          to_columns => ['id'], on_delete => 'NO ACTION', on_update => 'NO ACTION',
        },
      ],
    },
    $src_tables, $tgt_tables,
  );
  is(scalar @ops, 1, 'one FK add op');
  is($ops[0]->action, 'add', 'action add');
  is($ops[0]->as_sql,
    'ALTER TABLE book ADD CONSTRAINT fk_book_author_id FOREIGN KEY (author_id) REFERENCES author(id);',
    'add FK SQL, NO ACTION rules suppressed');
}

# --- Diff::ForeignKey: DROP uses the real server name ---
{
  my $src_tables = { author => {}, book => {} };
  my $tgt_tables = { author => {}, book => {} };
  my @ops = DBIO::DB2::Diff::ForeignKey->diff(
    {
      book => [
        {
          constraint_name => 'SQL230101_REALNAME',
          from_columns => ['author_id'], to_table => 'author',
          to_columns => ['id'], on_delete => 'NO ACTION', on_update => 'NO ACTION',
        },
      ],
    },
    { book => [] },
    $src_tables, $tgt_tables,
  );
  is(scalar @ops, 1, 'one FK drop op');
  is($ops[0]->action, 'drop', 'action drop');
  is($ops[0]->as_sql, 'ALTER TABLE book DROP FOREIGN KEY SQL230101_REALNAME;',
    'drop uses the real server-carried name');
}

# --- Diff::ForeignKey: MODIFY -> drop-then-add, drop first ---
{
  my $src_tables = { author => {}, editor => {}, book => {} };
  my $tgt_tables = { author => {}, editor => {}, book => {} };
  # same constraint_name, but to_columns/on_delete changed -> changed_fk_fields true
  my @ops = DBIO::DB2::Diff::ForeignKey->diff(
    {
      book => [
        {
          constraint_name => 'fk_book_ref_id',
          from_columns => ['ref_id'], to_table => 'author',
          to_columns => ['id'], on_delete => 'NO ACTION', on_update => 'NO ACTION',
        },
      ],
    },
    {
      book => [
        {
          constraint_name => 'fk_book_ref_id',
          from_columns => ['ref_id'], to_table => 'editor',
          to_columns => ['id'], on_delete => 'CASCADE', on_update => 'NO ACTION',
        },
      ],
    },
    $src_tables, $tgt_tables,
  );
  is(scalar @ops, 2, 'changed FK produces drop+add');
  is($ops[0]->action, 'drop', 'drop first');
  is($ops[1]->action, 'add',  'add second');
  like($ops[0]->as_sql, qr/^ALTER TABLE book DROP FOREIGN KEY fk_book_ref_id;$/,
    'drop targets old constraint');
  is($ops[1]->as_sql,
    'ALTER TABLE book ADD CONSTRAINT fk_book_ref_id FOREIGN KEY (ref_id) REFERENCES editor(id) ON DELETE CASCADE;',
    'add renders new definition with ON DELETE CASCADE');
}

# --- Diff::ForeignKey: ON DELETE CASCADE rendered, NO ACTION suppressed ---
{
  my $tables = { author => {}, book => {} };
  my @ops = DBIO::DB2::Diff::ForeignKey->diff(
    { book => [] },
    {
      book => [
        {
          constraint_name => 'fk_book_author_id',
          from_columns => ['author_id'], to_table => 'author',
          to_columns => ['id'], on_delete => 'CASCADE', on_update => 'NO ACTION',
        },
      ],
    },
    $tables, $tables,
  );
  my $sql = $ops[0]->as_sql;
  like($sql, qr/ON DELETE CASCADE/, 'ON DELETE CASCADE rendered');
  unlike($sql, qr/ON UPDATE/,       'NO ACTION on_update suppressed');
}

# --- Diff::ForeignKey: brand-new table emits NO FK op (inline via Diff::Table) ---
{
  # book is only in target_tables (being created) -> scope 'both' skips it.
  my @ops = DBIO::DB2::Diff::ForeignKey->diff(
    {},
    {
      book => [
        {
          constraint_name => 'fk_book_author_id',
          from_columns => ['author_id'], to_table => 'author', to_columns => ['id'],
        },
      ],
    },
    { author => {} },             # source_tables: book absent
    { author => {}, book => {} }, # target_tables: book being created
  );
  is(scalar @ops, 0, 'no FK op for a brand-new table (handled inline by Diff::Table)');
}

# --- Diff::ForeignKey: idempotency -- identical source/target -> zero ops ---
# Encodes WHY install_ddl must emit FKs: if the target lost its FKs, every
# upgrade would phantom-DROP. This fails if step 1 regresses.
{
  my $tables = { author => {}, book => {} };
  my $fks = {
    book => [
      {
        constraint_name => 'fk_book_author_id',
        from_columns => ['author_id'], to_table => 'author',
        to_columns => ['id'], on_delete => 'CASCADE', on_update => 'NO ACTION',
      },
    ],
  };
  my @ops = DBIO::DB2::Diff::ForeignKey->diff($fks, $fks, $tables, $tables);
  is(scalar @ops, 0, 'identical FKs produce zero ops (round-trip idempotent)');
}

# --- Top-level Diff orchestrator: FK ops come after table/column/index ops ---
{
  my $source = {
    tables       => { author => { table_name => 'author' }, book => { table_name => 'book' } },
    columns      => {
      author => [ { column_name => 'id', data_type => 'integer', is_pk => 1 } ],
      book   => [ { column_name => 'id', data_type => 'integer', is_pk => 1 },
                  { column_name => 'author_id', data_type => 'integer' } ],
    },
    indexes      => { book => { idx_old => { index_name => 'idx_old', columns => ['author_id'] } } },
    foreign_keys => {},
  };
  my $target = {
    tables       => { author => { table_name => 'author' }, book => { table_name => 'book' } },
    columns      => {
      author => [ { column_name => 'id', data_type => 'integer', is_pk => 1 } ],
      book   => [ { column_name => 'id', data_type => 'integer', is_pk => 1 },
                  { column_name => 'author_id', data_type => 'integer' },
                  { column_name => 'note', data_type => 'varchar' } ],
    },
    indexes      => {},
    foreign_keys => {
      book => [
        {
          constraint_name => 'fk_book_author_id',
          from_columns => ['author_id'], to_table => 'author',
          to_columns => ['id'], on_delete => 'NO ACTION', on_update => 'NO ACTION',
        },
      ],
    },
  };
  my $diff = DBIO::DB2::Diff->new(source => $source, target => $target);
  my @ops = @{ $diff->operations };
  isa_ok($ops[-1], 'DBIO::DB2::Diff::ForeignKey', 'last op is a foreign-key op');
  # no table/column/index op appears after the first FK op
  my $first_fk = 0;
  $first_fk++ until $ops[$first_fk]->isa('DBIO::DB2::Diff::ForeignKey');
  my $tail_all_fk = 1;
  for my $op (@ops[$first_fk .. $#ops]) {
    $tail_all_fk = 0 unless $op->isa('DBIO::DB2::Diff::ForeignKey');
  }
  ok($tail_all_fk, 'FK ops are emitted last, after table/column/index ops');
  like($diff->as_sql, qr/ADD COLUMN note/,                      'column add present');
  like($diff->as_sql, qr/DROP INDEX idx_old/,                   'stale index dropped');
  like($diff->as_sql, qr/ADD CONSTRAINT fk_book_author_id FOREIGN KEY/, 'FK add present');
}

# --- No changes ---
{
  my $model = {
    tables       => { t => { table_name => 't' } },
    columns      => { t => [ { column_name => 'id', data_type => 'integer' } ] },
    indexes      => {},
    foreign_keys => {},
  };
  my $diff = DBIO::DB2::Diff->new(source => $model, target => $model);
  ok(!$diff->has_changes, 'identical models have no changes');
  is($diff->as_sql,  '', 'empty SQL when no changes');
  is($diff->summary, '', 'empty summary when no changes');
}

done_testing;
