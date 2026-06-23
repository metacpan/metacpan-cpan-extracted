use strict;
use warnings;
use Test::More;

# Offline/mock coverage for the Sybase Diff triad. No live server: we feed
# introspected-model hashrefs (the shape DBIO::Sybase::Introspect produces)
# straight into the diff classes and assert on as_sql + summary.

use_ok 'DBIO::Sybase::Diff::Table';
use_ok 'DBIO::Sybase::Diff::Column';
use_ok 'DBIO::Sybase::Diff::Index';
use_ok 'DBIO::Sybase::Diff::ForeignKey';
use_ok 'DBIO::Sybase::Diff';

# Model helpers — keys match DBIO::Sybase::Introspect::{Tables,Columns,Indexes}.
sub tbl  { +{ table_name => $_[0], kind => 'table' } }
sub col  {
  my ($name, %o) = @_;
  +{ column_name => $name, data_type => $o{type} // 'integer',
     not_null => $o{not_null} // 0, default_value => $o{default},
     is_pk => $o{is_pk} // 0 };
}
sub idx  {
  my ($name, %o) = @_;
  +{ index_name => $name, is_unique => $o{unique} // 0,
     columns => $o{columns} // [] };
}
# FK entry — keys match DBIO::Sybase::Introspect's _group_fks_by_constraint
# output (per-constraint). This bare form omits constraint_name, as a desired/
# target model does; use fkn() for a source entry that carries the live name.
sub fk   {
  my %o = @_;
  +{ from_columns => $o{from} // [], to_table => $o{to_table},
     to_columns => $o{to} // [],
     on_update => $o{on_update}, on_delete => $o{on_delete} };
}
# FK entry carrying a live, server-assigned constraint_name (as produced for a
# source/introspected model). The desired/target model never carries one.
sub fkn  {
  my ($name, %o) = @_;
  +{ %{ fk(%o) }, constraint_name => $name };
}

# --- Diff::Table create (with columns wired in from target_columns) ---
{
  my @ops = DBIO::Sybase::Diff::Table->diff(
    {},
    { author => tbl('author') },
    { author => [ col('id', type => 'integer', not_null => 1, is_pk => 1),
                  col('name', type => 'varchar', not_null => 1) ] },
    {},
  );
  is(scalar @ops, 1, 'one create op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::Table::Create');
  my $sql = $ops[0]->as_sql;
  like($sql, qr/CREATE TABLE "?author"?/,  'create table emitted');
  like($sql, qr/"?id"? INT NOT NULL/,      'id column wired in');
  like($sql, qr/"?name"? VARCHAR\(255\) NOT NULL/, 'name column wired in');
  is($ops[0]->summary, 'CREATE TABLE author', 'create summary');
}

# --- Diff::Table create with identity column (is_identity round-trips) ---
{
  my @ops = DBIO::Sybase::Diff::Table->diff(
    {},
    { account => tbl('account') },
    { account => [ { %{ col('id', type => 'integer', not_null => 1, is_pk => 1) },
                    is_auto_increment => 1 } ] },
    {},
  );
  like($ops[0]->as_sql, qr/"?id"? INT NOT NULL IDENTITY/, 'identity column emits IDENTITY');
}

# --- Diff::Table drop ---
{
  my @ops = DBIO::Sybase::Diff::Table->diff(
    { gone => tbl('gone') },
    {},
    {},
    {},
  );
  is(scalar @ops, 1, 'one drop op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::Table::Drop');
  is($ops[0]->as_sql,  'DROP TABLE gone', 'drop SQL');
  is($ops[0]->summary, 'DROP TABLE gone', 'drop summary');
}

# --- Diff::Table: same kind on both sides → no table-level op (GAP2) ---
{
  my @ops = DBIO::Sybase::Diff::Table->diff(
    { author => tbl('author') },
    { author => tbl('author') },
    { author => [ col('id') ] },
    {},
  );
  is(scalar @ops, 0, 'unchanged table yields no table-level op');
}

# --- Diff::Column add ---
{
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('id') ] },
    { t => [ col('id'), col('extra', type => 'varchar') ] },
    {}, {},
  );
  is(scalar @ops, 1, 'one add op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::Column::Add');
  is($ops[0]->as_sql,  'ALTER TABLE t ADD extra varchar', 'add SQL');
  is($ops[0]->summary, 'ALTER TABLE t ADD extra',         'add summary');
}

# --- Diff::Column alter (type change) ---
{
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('id', type => 'integer') ] },
    { t => [ col('id', type => 'bigint', not_null => 1) ] },
    {}, {},
  );
  is(scalar @ops, 1, 'one alter op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::Column::Alter');
  like($ops[0]->as_sql, qr/ALTER TABLE t ALTER COLUMN id bigint NOT NULL/, 'alter SQL');
  is($ops[0]->summary, 'ALTER TABLE t ALTER id', 'alter summary');
}

# --- Diff::Column drop ---
{
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('id'), col('old', type => 'varchar') ] },
    { t => [ col('id') ] },
    {}, {},
  );
  is(scalar @ops, 1, 'one drop op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::Column::Drop');
  is($ops[0]->as_sql,  'ALTER TABLE t DROP COLUMN old', 'drop column SQL');
  is($ops[0]->summary, 'ALTER TABLE t DROP old',        'drop column summary');
}

# --- Diff::Index create ---
{
  my @ops = DBIO::Sybase::Diff::Index->diff(
    { t => {} },
    { t => { idx_name => idx('idx_name', columns => ['name']) } },
  );
  is(scalar @ops, 1, 'one index create op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::Index::Create');
  is($ops[0]->as_sql, 'CREATE INDEX idx_name ON t (name)', 'create index SQL');
}

# --- Diff::Index create unique ---
{
  my @ops = DBIO::Sybase::Diff::Index->diff(
    { t => {} },
    { t => { uq => idx('uq', unique => 1, columns => ['a', 'b']) } },
  );
  is($ops[0]->as_sql, 'CREATE UNIQUE INDEX uq ON t (a, b)', 'create unique index SQL');
}

# --- Diff::Index drop ---
{
  my @ops = DBIO::Sybase::Diff::Index->diff(
    { t => { stale => idx('stale', columns => ['x']) } },
    { t => {} },
  );
  is(scalar @ops, 1, 'one index drop op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::Index::Drop');
  is($ops[0]->as_sql, 'DROP INDEX t.stale', 'drop index SQL');
}

# --- Diff::ForeignKey add (constraint new on a retained table) ---
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [] },
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id']) ] },
  );
  is(scalar @ops, 1, 'one fk add op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::ForeignKey::Create');
  like($ops[0]->as_sql,
    qr/ALTER TABLE "?book"? ADD CONSTRAINT "?fk_book_author_id"? FOREIGN KEY \("?author_id"?\) REFERENCES "?author"? \("?id"?\)/,
    'fk add SQL');
  is($ops[0]->summary, 'ADD FK fk_book_author_id ON book', 'fk add summary');
}

# --- Diff::ForeignKey add with ON DELETE/UPDATE actions ---
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [] },
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id'],
                   on_delete => 'CASCADE', on_update => 'SET NULL') ] },
  );
  like($ops[0]->as_sql, qr/ON UPDATE SET NULL/, 'on update emitted');
  like($ops[0]->as_sql, qr/ON DELETE CASCADE/,  'on delete emitted');
}

# --- Diff::ForeignKey: NO ACTION is the default → not emitted ---
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [] },
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id'],
                   on_delete => 'NO ACTION', on_update => 'NO ACTION') ] },
  );
  unlike($ops[0]->as_sql, qr/ON (UPDATE|DELETE)/, 'NO ACTION not emitted');
}

# --- Diff::ForeignKey drop (constraint gone from a retained table) ---
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id']) ] },
    { book => [] },
  );
  is(scalar @ops, 1, 'one fk drop op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::ForeignKey::Drop');
  is($ops[0]->as_sql,
    'ALTER TABLE book DROP CONSTRAINT fk_book_author_id', 'fk drop SQL');
  is($ops[0]->summary, 'DROP FK fk_book_author_id ON book', 'fk drop summary');
}

# --- Diff::ForeignKey alter (ON DELETE change) → drop+create ---
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id'],
                   on_delete => 'NO ACTION') ] },
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id'],
                   on_delete => 'CASCADE') ] },
  );
  is(scalar @ops, 2, 'alter yields drop+create pair');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::ForeignKey::Drop',   'first is drop');
  isa_ok($ops[1], 'DBIO::Sybase::Diff::ForeignKey::Create', 'second is create');
  like($ops[0]->as_sql, qr/DROP CONSTRAINT "?fk_book_author_id"?/, 'alter drops old');
  like($ops[1]->as_sql, qr/ON DELETE CASCADE/, 'alter recreates with new action');
}

# --- Diff::ForeignKey: identical FK on both sides → no op ---
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id']) ] },
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id']) ] },
  );
  is(scalar @ops, 0, 'unchanged FK yields no op');
}

# --- Diff::ForeignKey drop uses the live constraint_name when source carries it ---
# The source (introspected) model carries the real server-assigned name; the
# DROP must target that name, not the generated fk_<table>_<cols> form.
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [ fkn('fk_oddname_xyz',
                    from => ['author_id'], to_table => 'author', to => ['id']) ] },
    { book => [] },
  );
  is(scalar @ops, 1, 'one fk drop op (named source)');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::ForeignKey::Drop');
  is($ops[0]->as_sql,
    'ALTER TABLE book DROP CONSTRAINT fk_oddname_xyz',
    'fk drop uses real source constraint name');
  is($ops[0]->summary, 'DROP FK fk_oddname_xyz ON book',
    'fk drop summary uses real source constraint name');
}

# --- Diff::ForeignKey drop falls back to generated name when source unnamed ---
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id']) ] },
    { book => [] },
  );
  is($ops[0]->as_sql,
    'ALTER TABLE book DROP CONSTRAINT fk_book_author_id',
    'fk drop falls back to generated name when source has no constraint_name');
}

# --- Diff::ForeignKey alter: drop-half uses real source name, create-half generates ---
# Asymmetry: the live source entry carries a real name; the desired/target
# entry (built from a schema definition) does not. The drop must target the
# real name; the recreate uses the deterministic generated name.
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [ fkn('fk_oddname_xyz',
                    from => ['author_id'], to_table => 'author', to => ['id'],
                    on_delete => 'NO ACTION') ] },
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id'],
                   on_delete => 'CASCADE') ] },
  );
  is(scalar @ops, 2, 'named alter yields drop+create pair');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::ForeignKey::Drop',   'first is drop');
  isa_ok($ops[1], 'DBIO::Sybase::Diff::ForeignKey::Create', 'second is create');
  like($ops[0]->as_sql, qr/DROP CONSTRAINT "?fk_oddname_xyz"?/,
    'alter drops the real source constraint name');
  like($ops[1]->as_sql, qr/ADD CONSTRAINT "?fk_book_author_id"?/,
    'alter recreates under the generated name');
  like($ops[1]->as_sql, qr/ON DELETE CASCADE/, 'alter recreates with new action');
}

# --- Diff::ForeignKey: FK on a table absent from source → skipped here ---
# (a brand-new table carries its own FKs; this op only reconciles retained tables)
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    {},
    { fresh => [ fk(from => ['x'], to_table => 'other', to => ['id']) ] },
  );
  is(scalar @ops, 0, 'FK on new table not emitted by ForeignKey diff');
}

# --- Full Diff orchestrator end-to-end ---
{
  my $source = {
    tables       => { keep => tbl('keep'), drop_me => tbl('drop_me') },
    columns      => { keep => [ col('id'), col('gone', type => 'varchar') ],
                      drop_me => [ col('id') ] },
    indexes      => { keep => {} },
    # keep has a stale FK that must be dropped; drop_me's FK vanishes with it.
    foreign_keys => { keep => [ fk(from => ['gone'], to_table => 'other', to => ['id']) ] },
  };
  my $target = {
    tables       => { keep => tbl('keep'), fresh => tbl('fresh') },
    columns      => { keep => [ col('id'), col('added', type => 'varchar') ],
                      fresh => [ col('id', not_null => 1, is_pk => 1) ] },
    indexes      => { keep => { ix => idx('ix', columns => ['added']) } },
    # keep gains a new FK that must be added after the column it references.
    foreign_keys => { keep => [ fk(from => ['added'], to_table => 'other', to => ['id']) ] },
  };
  my $diff = DBIO::Sybase::Diff->new(source => $source, target => $target);
  ok($diff->has_changes, 'orchestrator sees changes');

  my $sql     = $diff->as_sql;
  my $summary = $diff->summary;

  like($sql, qr/CREATE TABLE "?fresh"?/,    'creates new table');
  like($sql, qr/DROP TABLE drop_me/,        'drops removed table');
  like($sql, qr/ALTER TABLE keep ADD added/, 'adds new column');
  like($sql, qr/ALTER TABLE keep DROP COLUMN gone/, 'drops removed column');
  like($sql, qr/CREATE INDEX ix ON keep/,   'creates new index');
  like($sql, qr/DROP CONSTRAINT "?fk_keep_gone"?/, 'drops stale FK');
  like($sql, qr/ADD CONSTRAINT "?fk_keep_added"?/, 'adds new FK');

  # Dependency ordering: FK drop precedes the table/column drops it could block,
  # and the FK add lands after the tables/columns it references.
  ok(index($sql, 'DROP CONSTRAINT') < index($sql, 'DROP COLUMN gone'),
    'FK drop precedes column drop');
  ok(index($sql, 'DROP CONSTRAINT') < index($sql, 'DROP TABLE drop_me'),
    'FK drop precedes table drop');
  ok(index($sql, 'ADD CONSTRAINT') > index($sql, 'ALTER TABLE keep ADD added'),
    'FK add follows column add');
  ok(index($sql, 'ADD CONSTRAINT') > index($sql, 'CREATE TABLE'),
    'FK add follows table create');

  # Regression guards against the historical bugs in this triad:
  unlike($sql, qr/TODO/,        'no TODO placeholder leaks into migration');
  unlike($sql, qr/\{UNIQUE|\{\}INDEX|\$unique/, 'no literal-brace index bug');
  unlike($sql, qr/\bHASH\(0x/,  'no stringified hashref leaks (constructor bug)');
  like($summary, qr/CREATE TABLE fresh/,    'summary mentions new table');
}

done_testing;
