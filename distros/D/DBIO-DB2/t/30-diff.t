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

# --- Diff::Table create (PK, identity, types) ---
# The columns are in the shape DBIO::DB2::Introspect::Columns returns, because
# that is what a create op is built from in a real diff: the compare schema's
# catalog. catalog_type is TYPENAME, catalog_size is LENGTH (the storage length for a type
# declared without one; for TIMESTAMP the precision), an identity column
# carries is_auto_increment. This block used to feed
#   { column_name => 'id', data_type => 'integer', is_pk => 1 }
# -- a result class column, which no diff sees -- and so never noticed that the
# real one came out as "id" INTEGER(4) NOT NULL: refused by the server
# (SQL0104N), and without the identity clause (karr k41).
{
  package T::K41::Result::Author;
  use base 'DBIO::Core';
  __PACKAGE__->table('author');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 255 },
  );
  __PACKAGE__->set_primary_key('id');

  package T::K41::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Author => 'T::K41::Result::Author');
}

{
  my @ops = DBIO::DB2::Diff::Table->diff(
    {},
    { author => { table_name => 'author', kind => 'table' } },
    {
      author => [
        { column_name => 'id',   catalog_type => 'INTEGER',   catalog_size => 4,   not_null => 1,
          is_pk => 1, pk_position => 1, is_auto_increment => 1 },
        { column_name => 'name', catalog_type => 'VARCHAR',   catalog_size => 255, not_null => 1 },
        { column_name => 'born', catalog_type => 'DATE',      catalog_size => 4,   not_null => 0 },
        { column_name => 'seen', catalog_type => 'TIMESTAMP', catalog_size => 6,   not_null => 0 },
      ],
    },
    { author => [] },
  );
  is(scalar @ops, 1, 'one create op');
  is($ops[0]->action, 'create', 'action create');
  is($ops[0]->table_name, 'author', 'table_name');
  my $sql = $ops[0]->as_sql;
  like($sql, qr/CREATE TABLE "author"/,       'create table (quoted, karr k28)');
  like($sql, qr/^  "name" VARCHAR\(255\) NOT NULL,$/m, 'name VARCHAR(255) NOT NULL (quoted column)');
  like($sql, qr/^  "born" DATE,$/m,           'a DATE gets no length, whatever LENGTH the catalog holds');
  like($sql, qr/^  "seen" TIMESTAMP\(6\),$/m, 'a TIMESTAMP gets its precision');
  like($sql, qr/PRIMARY KEY \("id"\)/,        'inline PK constraint (quoted cols)');

  # The identity column, as install_ddl writes it for the same table: a table
  # created by an upgrade and one created by install must not differ in it.
  my ($installed) = DBIO::DB2::DDL->install_ddl('T::K41::Schema') =~ /^(  "id" .*),$/m;
  my ($created)   = $sql =~ /^(  "id" .*),$/m;
  is($installed, '  "id" INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1)',
    'install_ddl writes the identity column');
  is($created, $installed,
    'Diff::Table create writes it the same: no length on INTEGER, and the identity clause');
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
        { column_name => 'id',        catalog_type => 'integer', is_pk => 1 },
        { column_name => 'author_id', catalog_type => 'integer', not_null => 1 },
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
    qr/CONSTRAINT "fk_book_author_id" FOREIGN KEY \("author_id"\) REFERENCES "author"\("id"\) ON DELETE CASCADE/,
    'inline FK is NAMED with deterministic name and renders ON DELETE CASCADE');
  unlike($sql, qr/ON UPDATE/, 'NO ACTION on_update suppressed on inline FK');
  unlike($sql, qr/[^_]FOREIGN KEY \("author_id"\) REFERENCES "author"\("id"\)[,\s)]*$/m,
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
    { book => [ { column_name => 'author_id', catalog_type => 'integer' } ] },
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
        { column_name => 'a', catalog_type => 'integer', is_pk => 1 },
        { column_name => 'b', catalog_type => 'integer', is_pk => 1 },
      ],
    },
    {},
  );
  like($ops[0]->as_sql, qr/PRIMARY KEY \("a", "b"\)/, 'multi-col PK as constraint (quoted cols)');
}

# --- Diff::Table drop ---
{
  my @ops = DBIO::DB2::Diff::Table->diff(
    { gone => { table_name => 'gone' } },
    {},
  );
  is($ops[0]->action, 'drop',                'drop op');
  is($ops[0]->as_sql, 'DROP TABLE "gone";', 'drop SQL (quoted, karr k28)');
  is($ops[0]->summary, '- table: gone',       'drop summary');
}

# --- Diff::Column add ---
{
  my @ops = DBIO::DB2::Diff::Column->diff(
    { t => [ { column_name => 'id', catalog_type => 'integer' } ] },
    {
      t => [
        { column_name => 'id',    catalog_type => 'integer' },
        { column_name => 'extra', catalog_type => 'varchar', catalog_size => 50, not_null => 0 },
      ],
    },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'one add op');
  is($ops[0]->action, 'add', 'action add');
  is($ops[0]->as_sql, 'ALTER TABLE "t" ADD COLUMN "extra" VARCHAR(50);', 'add SQL (quoted, karr k28)');
}

# --- Diff::Column add NOT NULL with default ---
# Catalog shape (karr k41, see the create block above): catalog_size is the LENGTH 4
# of an INTEGER, catalog_default the catalog's DEFAULT text. The string default
# is the case that matters -- its text has the quotes already, and writing it
# as a literal once more (DEFAULT '''new''') made the quoted text the default.
{
  my @ops = DBIO::DB2::Diff::Column->diff(
    { t => [ { column_name => 'id', catalog_type => 'INTEGER', catalog_size => 4 } ] },
    {
      t => [
        { column_name => 'id',    catalog_type => 'INTEGER', catalog_size => 4 },
        { column_name => 'flag',  catalog_type => 'INTEGER', catalog_size => 4,  not_null => 1, catalog_default => '0' },
        { column_name => 'state', catalog_type => 'VARCHAR', catalog_size => 20, not_null => 1, catalog_default => q{'new'} },
      ],
    },
    { t => {} }, { t => {} },
  );
  is_deeply([ map { $_->as_sql } @ops ], [
    'ALTER TABLE "t" ADD COLUMN "flag" INTEGER NOT NULL DEFAULT 0;',
    q{ALTER TABLE "t" ADD COLUMN "state" VARCHAR(20) NOT NULL DEFAULT 'new';},
  ], 'NOT NULL DEFAULT in add: no length on INTEGER, the default text as it is');
}

# --- Diff::Column drop ---
{
  my @ops = DBIO::DB2::Diff::Column->diff(
    {
      t => [
        { column_name => 'id',  catalog_type => 'integer' },
        { column_name => 'old', catalog_type => 'varchar' },
      ],
    },
    { t => [ { column_name => 'id', catalog_type => 'integer' } ] },
    { t => {} }, { t => {} },
  );
  is($ops[0]->action, 'drop', 'drop op');
  is($ops[0]->as_sql, 'ALTER TABLE "t" DROP COLUMN "old";', 'drop column SQL (quoted, karr k28)');
}

# --- Diff::Column alter type + NOT NULL (DB2 supports ALTER COLUMN) ---
{
  my @ops = DBIO::DB2::Diff::Column->diff(
    { t => [ { column_name => 'a', catalog_type => 'integer', not_null => 0 } ] },
    { t => [ { column_name => 'a', catalog_type => 'varchar', catalog_size => 50, not_null => 1 } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1,        'one alter op');
  is($ops[0]->action, 'alter', 'action alter');
  my $sql = $ops[0]->as_sql;
  like($sql, qr/ALTER TABLE "t" ALTER COLUMN "a" SET DATA TYPE VARCHAR\(50\);/, 'SET DATA TYPE (quoted, karr k28)');
  like($sql, qr/ALTER TABLE "t" ALTER COLUMN "a" SET NOT NULL;/,               'SET NOT NULL (quoted, karr k28)');
}

# --- Diff::Column alter default change + drop NOT NULL ---
{
  my @ops = DBIO::DB2::Diff::Column->diff(
    { t => [ { column_name => 'a', catalog_type => 'integer', not_null => 1, catalog_default => '1' } ] },
    { t => [ { column_name => 'a', catalog_type => 'integer', not_null => 0, catalog_default => '2' } ] },
    { t => {} }, { t => {} },
  );
  my $sql = $ops[0]->as_sql;
  like($sql, qr/ALTER COLUMN "a" DROP NOT NULL;/,    'DROP NOT NULL (quoted, karr k28)');
  like($sql, qr/ALTER COLUMN "a" SET DEFAULT 2;/,    'SET DEFAULT (quoted, karr k28)');
}

# --- Diff::Column alter of a string default, catalog shape (karr k41) ---
# Both sides as SYSCAT has them: the same VARCHAR(20), two default texts. One
# statement, and the text in it is the target's -- 'new', not '''new''', which
# set the default to the quoted text and made the next diff ask again.
{
  my @ops = DBIO::DB2::Diff::Column->diff(
    { t => [ { column_name => 'state', catalog_type => 'VARCHAR', catalog_size => 20, not_null => 1, catalog_default => q{'old'} } ] },
    { t => [ { column_name => 'state', catalog_type => 'VARCHAR', catalog_size => 20, not_null => 1, catalog_default => q{'new'} } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'one alter op for a changed string default');
  is($ops[0]->as_sql, q{ALTER TABLE "t" ALTER COLUMN "state" SET DEFAULT 'new';},
    'SET DEFAULT writes the catalog text as it is, and no SET DATA TYPE beside it');
}

# --- Diff::Column drop DEFAULT ---
# A default the target no longer declares is removed (core karr k367; karr k57,
# conformance case diff-default-removed): the live column carries one, the
# target leaves catalog_default undef -- diff() emits the alter, as_sql the DROP
# DEFAULT. A live DEFAULT NULL is no default, so there is nothing to remove. (This
# test used to pin the opposite, "omitted target default is don't care", which
# core dropped for defaults in k367.)
{
  my @ops = DBIO::DB2::Diff::Column->diff(
    { t => [ { column_name => 'a', catalog_type => 'integer', catalog_default => '5' } ] },
    { t => [ { column_name => 'a', catalog_type => 'integer' } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'a default the target omits is a change');
  like($ops[0]->as_sql, qr/ALTER COLUMN "a" DROP DEFAULT;/, '... written as DROP DEFAULT');

  @ops = DBIO::DB2::Diff::Column->diff(
    { t => [ { column_name => 'a', catalog_type => 'integer', catalog_default => 'NULL' } ] },
    { t => [ { column_name => 'a', catalog_type => 'integer' } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 0, 'a live DEFAULT NULL is no default: nothing to remove');

  my $op = DBIO::DB2::Diff::Column->new(
    action => 'alter', table_name => 't', column_name => 'a',
    old_info => { catalog_type => 'integer', catalog_default => '5' },
    new_info => { catalog_type => 'integer', catalog_default => undef },
  );
  like($op->as_sql, qr/ALTER COLUMN "a" DROP DEFAULT;/, 'as_sql renders DROP DEFAULT (quoted, karr k28)');
}

# --- Diff::Table creates new tables in foreign key order (karr k57) ---
# The FKs of a new table are inline in its CREATE TABLE, so the table they
# reference has to exist first; name order ("child" before "parent") made Db2
# answer SQL0204N (conformance case diff-table-added-complete). Otherwise the
# order is the name order; a self-reference, a reference to a table that exists already and a
# cycle (which no order can create) do not reorder or loop.
{
  my $fk = sub { { constraint_name => "fk_$_[0]", from_columns => ['p'], to_table => $_[1], to_columns => ['id'] } };
  my @tables = qw(child grandchild parent other tree old);
  my %target = map { $_ => { table_name => $_, kind => 'table' } } @tables;
  my @ops = DBIO::DB2::Diff::Table->diff(
    { old => { table_name => 'old', kind => 'table' } }, \%target, {},
    { child      => [ $fk->(child => 'parent') ],
      grandchild => [ $fk->(grandchild => 'child') ],
      tree       => [ $fk->(tree => 'tree'), $fk->(tree2 => 'old') ],
      parent     => [], other => [] },
  );
  is_deeply([ map { $_->table_name } grep { $_->action eq 'create' } @ops ],
    [qw(parent child grandchild other tree)],
    'a referenced table is created before the table referencing it, otherwise by name');

  @ops = DBIO::DB2::Diff::Table->diff({}, { a => { table_name => 'a' }, b => { table_name => 'b' } }, {},
    { a => [ $fk->(a => 'b') ], b => [ $fk->(b => 'a') ] });
  is_deeply([ sort map { $_->table_name } @ops ], [qw(a b)], 'a cycle terminates and loses no table');
}

# --- Diff::Column skips brand-new tables ---
{
  my @ops = DBIO::DB2::Diff::Column->diff(
    {},
    { newtab => [ { column_name => 'id', catalog_type => 'integer' } ] },
    {},          # source_tables: newtab absent -> table being created
    { newtab => {} },
  );
  is(scalar @ops, 0, 'no col ops for tables also being created');
}

# --- k45: views are not tables -- Diff::Table and Diff::Column leave them alone ---
# Until k45 the model held no view body and a view that diverged made the diff
# die (k36, a refusal naming the view). The model carries view_definition now and
# DBIO::DB2::Diff::View has the operations (CREATE VIEW / DROP VIEW, t/68); what
# stays from k36 is that a view never becomes a table operation. Missing kind
# means 'table' (mock models routinely omit it), so only kind => 'view' is left out.

# View only in target: no CREATE TABLE.
{
  my @ops = DBIO::DB2::Diff::Table->diff(
    {},
    { v_new => { table_name => 'v_new', kind => 'view', view_definition => 'AS SELECT 1 FROM t' } },
    { v_new => [ { column_name => 'id', catalog_type => 'integer' } ] },
    {},
  );
  is(scalar @ops, 0, 'a view only in the target is no CREATE TABLE (and does not die)');
}

# View only in source: no DROP TABLE.
{
  my @ops = DBIO::DB2::Diff::Table->diff(
    { v_gone => { table_name => 'v_gone', kind => 'view' } },
    {},
  );
  is(scalar @ops, 0, 'a view only in the source is no DROP TABLE (and does not die)');
}

# A plain TABLE (kind absent == table) must still create/drop normally --
# guards against a fix that skips on name instead of on kind.
{
  my @ops = DBIO::DB2::Diff::Table->diff(
    {},
    { plain => { table_name => 'plain' } },
    { plain => [ { column_name => 'id', catalog_type => 'integer' } ] },
    {},
  );
  is(scalar @ops, 1, 'a plain table (no kind) still creates');
  is($ops[0]->action, 'create', 'plain-table op is a create');
}

# A name that is a table in the source and a view in the target: the table goes
# (the view is created by Diff::View).
{
  my @ops = DBIO::DB2::Diff::Table->diff(
    { x => { table_name => 'x', kind => 'table' } },
    { x => { table_name => 'x', kind => 'view', view_definition => 'AS SELECT 1 FROM t' } },
  );
  is(scalar @ops, 1, 'table turned view: one table operation');
  is($ops[0]->as_sql, 'DROP TABLE "x";', '... the DROP TABLE');
}

# View on BOTH sides, columns differ: no ALTER TABLE, no refusal.
{
  my @ops;
  my $ok = eval {
    @ops = DBIO::DB2::Diff::Column->diff(
      { v => [ { column_name => 'id', catalog_type => 'integer' } ] },
      { v => [ { column_name => 'id',    catalog_type => 'integer' },
               { column_name => 'extra', catalog_type => 'varchar', catalog_size => 50 } ] },
      { v => { table_name => 'v', kind => 'view' } },
      { v => { table_name => 'v', kind => 'view' } },
    );
    1;
  };
  ok($ok, 'column divergence on a view does not die') or diag $@;
  is(scalar @ops, 0, '... and writes no ALTER TABLE: the view follows its definition');
}

# The same for a view marked on one side only (a table turned view).
{
  my @ops = DBIO::DB2::Diff::Column->diff(
    { v => [ { column_name => 'id', catalog_type => 'integer' } ] },
    { v => [ { column_name => 'id', catalog_type => 'integer' }, { column_name => 'x', catalog_type => 'integer' } ] },
    { v => { table_name => 'v', kind => 'table' } },
    { v => { table_name => 'v', kind => 'view' } },
  );
  is(scalar @ops, 0, 'no column op when either side calls it a view');
}

# A table with a column divergence is still altered (the skip is kind-based).
{
  my @ops = DBIO::DB2::Diff::Column->diff(
    { t => [ { column_name => 'id', catalog_type => 'integer' } ] },
    { t => [ { column_name => 'id', catalog_type => 'integer' }, { column_name => 'x', catalog_type => 'integer' } ] },
    { t => { table_name => 't', kind => 'table' } },
    { t => { table_name => 't', kind => 'table' } },
  );
  is(scalar @ops, 1, 'a table gets its ADD COLUMN');
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
  is($ops[0]->as_sql, 'CREATE UNIQUE INDEX "idx_t_name" ON "t" ("name");', 'unique index SQL (quoted, karr k28)');
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
  is($ops[0]->as_sql, 'CREATE INDEX "idx_ab" ON "t" ("a", "b");', 'non-unique multi-col index (quoted, karr k28)');
}

# --- Diff::Index drop ---
{
  my @ops = DBIO::DB2::Diff::Index->diff(
    { t => { gone_idx => { index_name => 'gone_idx', columns => ['x'] } } },
    {},
  );
  is($ops[0]->action, 'drop',                 'drop op');
  is($ops[0]->as_sql, 'DROP INDEX "gone_idx";', 'drop index SQL (quoted, karr k28)');
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

# --- Diff::Index: suppress DROP INDEX when the owning table is dropped (karr k19) ---
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

# --- Diff::Index: over-suppression guard -- surviving table still drops its index (karr k19) ---
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
  is($ops[0]->as_sql, 'DROP INDEX "idx_users_email";', 'surviving-table index still dropped standalone (quoted, karr k28)');
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
      author => [ { column_name => 'id', catalog_type => 'integer', is_pk => 1 } ],
    },
    indexes      => {},
    foreign_keys => {},
  };
  my $diff = DBIO::DB2::Diff->new(source => $source, target => $target);
  ok($diff->has_changes, 'has_changes');
  like($diff->as_sql,  qr/CREATE TABLE "author"/, 'as_sql contains create (quoted, karr k28)');
  like($diff->summary, qr/\+ table: author/,    'summary contains create line');
}

# --- Top-level Diff orchestrator: dependency ordering ---
{
  # Existing table gets a new column; a new table is created; an old index dropped.
  my $source = {
    tables       => { keep => { table_name => 'keep' } },
    columns      => { keep => [ { column_name => 'id', catalog_type => 'integer' } ] },
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
        { column_name => 'id',  catalog_type => 'integer' },
        { column_name => 'note', catalog_type => 'varchar', catalog_size => 50 },
      ],
      fresh => [ { column_name => 'id', catalog_type => 'integer', is_pk => 1 } ],
    },
    indexes      => {},
    foreign_keys => {},
  };
  my $diff = DBIO::DB2::Diff->new(source => $source, target => $target);
  my @ops = @{ $diff->operations };
  # tables first, then columns, then indexes
  isa_ok($ops[0],  'DBIO::DB2::Diff::Table',  'first op is a table op');
  isa_ok($ops[-1], 'DBIO::DB2::Diff::Index',  'last op is an index op');
  like($diff->as_sql, qr/CREATE TABLE "fresh"/,            'new table created (quoted, karr k28)');
  like($diff->as_sql, qr/ADD COLUMN "note"/,               'column added to existing table (quoted, karr k28)');
  like($diff->as_sql, qr/DROP INDEX "old_idx"/,            'stale index dropped (quoted, karr k28)');
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
    'ALTER TABLE "book" ADD CONSTRAINT "fk_book_author_id" FOREIGN KEY ("author_id") REFERENCES "author"("id");',
    'add FK SQL, NO ACTION rules suppressed (quoted, karr k28)');
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
  is($ops[0]->as_sql, 'ALTER TABLE "book" DROP FOREIGN KEY "SQL230101_REALNAME";',
    'drop uses the real server-carried name (quoted, karr k28)');
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
  like($ops[0]->as_sql, qr/^ALTER TABLE "book" DROP FOREIGN KEY "fk_book_ref_id";$/,
    'drop targets old constraint (quoted, karr k28)');
  is($ops[1]->as_sql,
    'ALTER TABLE "book" ADD CONSTRAINT "fk_book_ref_id" FOREIGN KEY ("ref_id") REFERENCES "editor"("id") ON DELETE CASCADE;',
    'add renders new definition with ON DELETE CASCADE (quoted, karr k28)');
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
      author => [ { column_name => 'id', catalog_type => 'integer', is_pk => 1 } ],
      book   => [ { column_name => 'id', catalog_type => 'integer', is_pk => 1 },
                  { column_name => 'author_id', catalog_type => 'integer' } ],
    },
    indexes      => { book => { idx_old => { index_name => 'idx_old', columns => ['author_id'] } } },
    foreign_keys => {},
  };
  my $target = {
    tables       => { author => { table_name => 'author' }, book => { table_name => 'book' } },
    columns      => {
      author => [ { column_name => 'id', catalog_type => 'integer', is_pk => 1 } ],
      book   => [ { column_name => 'id', catalog_type => 'integer', is_pk => 1 },
                  { column_name => 'author_id', catalog_type => 'integer' },
                  { column_name => 'note', catalog_type => 'varchar', catalog_size => 50 } ],
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
  like($diff->as_sql, qr/ADD COLUMN "note"/,                      'column add present (quoted, karr k28)');
  like($diff->as_sql, qr/DROP INDEX "idx_old"/,                   'stale index dropped (quoted, karr k28)');
  like($diff->as_sql, qr/ADD CONSTRAINT "fk_book_author_id" FOREIGN KEY/, 'FK add present (quoted, karr k28)');
}

# --- No changes ---
{
  my $model = {
    tables       => { t => { table_name => 't' } },
    columns      => { t => [ { column_name => 'id', catalog_type => 'integer' } ] },
    indexes      => {},
    foreign_keys => {},
  };
  my $diff = DBIO::DB2::Diff->new(source => $model, target => $model);
  ok(!$diff->has_changes, 'identical models have no changes');
  is($diff->as_sql,  '', 'empty SQL when no changes');
  is($diff->summary, '', 'empty summary when no changes');
}

done_testing;
