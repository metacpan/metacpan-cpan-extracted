use strict;
use warnings;
use Test::More;

# Offline tripwire for karr k28: DB2 folds unquoted identifiers to UPPERCASE,
# while the driver's SQLMaker quotes every identifier it emits
# (sql_quote_char '"', pinned in t/50-results-exist.t). The DDL/diff/deploy
# half therefore MUST quote every identifier it emits -- in lock-step with
# the SQLMaker -- or the installed schema has ARTIST (uppercased by DB2 from
# `CREATE TABLE artist`) while the ResultSet queries "artist": SQL0204N.
#
# Shared DBIO::SQL::Util::_quote_ident deliberately does NOT quote simple
# names (it is the PostgreSQL-correct helper: unquoted folds to lowercase
# there). DB2 has the opposite fold, so this driver carries its own
# always-quote helper. Every emit site -- DDL.pm, Diff::Table/Column/Index/
# ForeignKey, the FK clause builder -- must go through it, never the shared
# one.

use_ok 'DBIO::DB2::DDL';
use_ok 'DBIO::DB2::Diff::Table';
use_ok 'DBIO::DB2::Diff::Column';
use_ok 'DBIO::DB2::Diff::Index';
use_ok 'DBIO::DB2::Diff::ForeignKey';

# ---------------------------------------------------------------------------
# Shared helper: DB2-specific identifier quoter, always-quotes and escapes
# embedded `"` as `""`. Must escape (don't naively return the input) so an
# identifier containing a double-quote can't break out of its quoting.
# ---------------------------------------------------------------------------
is(DBIO::DB2::DDL::_db2_quote_ident('artist'), '"artist"',
  '_db2_quote_ident quotes a simple lowercase name');
is(DBIO::DB2::DDL::_db2_quote_ident('AUTOINCREMENT'), '"AUTOINCREMENT"',
  '_db2_quote_ident quotes a simple uppercase name');
is(DBIO::DB2::DDL::_db2_quote_ident(q{a"b}), '"a""b"',
  '_db2_quote_ident escapes an embedded double-quote as ""');

# ---------------------------------------------------------------------------
# install_ddl must emit quoted identifiers end-to-end
# (table name, columns, PK columns, FK clause body, index name + target +
# columns).
# ---------------------------------------------------------------------------
{
  package My::QI::Schema::Author;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('author');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 255 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many('books', 'My::QI::Schema::Book', 'author_id');
}

{
  package My::QI::Schema::Book;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('book');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    author_id => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to('author', 'My::QI::Schema::Author', 'author_id',
    { is_foreign_key_constraint => 1 });
  # Standalone index on the FK column -- exercises the CREATE INDEX path.
  sub db2_indexes { { idx_book_author_id => { unique => 0, columns => ['author_id'] } } }
}

# (No standalone BookIdx subclass -- the index lives on the registered Book
# class so install_ddl actually emits the CREATE INDEX it asserts on below.)

{
  package My::QI::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Author => 'My::QI::Schema::Author');
  __PACKAGE__->register_class(Book   => 'My::QI::Schema::Book');
}

# An inline standalone index, to exercise the CREATE INDEX path too.
{
  package My::QI::Schema::BookIdx;
  use strict; use warnings;
  use base 'My::QI::Schema::Book';
  sub db2_indexes { { idx_book_author_id => { unique => 0, columns => ['author_id'] } } }
}

# An inline standalone index, to exercise the CREATE INDEX path too.
# (The index lives on the registered Book class so install_ddl actually emits
# the CREATE INDEX it asserts on below.)

my $ddl = DBIO::DB2::DDL->install_ddl('My::QI::Schema');
ok(length $ddl, 'install_ddl returned non-empty DDL');

# Table names are quoted (otherwise DB2 would upper-fold to AUTHOR/BOOK and
# the quoted query path would fail with SQL0204N).
like($ddl, qr/CREATE TABLE "author"\s*\(/, 'install_ddl quotes table name "author"');
like($ddl, qr/CREATE TABLE "book"\s*\(/,   'install_ddl quotes table name "book"');

# Column names are quoted.
like($ddl, qr/"id"\s+INTEGER/,                'install_ddl quotes column "id"');
like($ddl, qr/"name"\s+VARCHAR\(255\)/,       'install_ddl quotes column "name"');
like($ddl, qr/"author_id"\s+INTEGER/,         'install_ddl quotes column "author_id"');

# PK columns are quoted (PK is column-list syntax; if the PK list were bare,
# it would still upper-fold and DB2 would compare against the wrong names).
like($ddl, qr/PRIMARY KEY \("id"\)/,          'install_ddl quotes PK columns');

# FK clause body is quoted: constraint name, from columns, to table, to cols.
like($ddl, qr/CONSTRAINT "fk_book_author_id" FOREIGN KEY \("author_id"\) REFERENCES "author"\("id"\)/,
  'install_ddl quotes the whole FK clause body');

# Index emit: name, target table, columns are all quoted.
like($ddl, qr/CREATE INDEX "idx_book_author_id" ON "book" \("author_id"\)/,
  'install_ddl quotes index name + target + columns');

# Regression tripwire: the DDL must NOT contain an unquoted identifier that
# would upper-fold away from the SQLMaker's quoted-lowercase references.
# A bare `REFERENCES author(` or `REFERENCES author (` would mean a
# child table's FK resolves against AUTHOR (the uppercased table) instead
# of "author" (the lowercase quoted one).
unlike($ddl, qr/REFERENCES\s+author\s*\(/,
  'no unquoted REFERENCES target (DB2 would upper-fold and break the FK)');
unlike($ddl, qr/CREATE TABLE author\s*\(/,
  'no unquoted CREATE TABLE target (DB2 would upper-fold and break the table)');

# ---------------------------------------------------------------------------
# Diff::Table CREATE path must emit quoted identifiers in lock-step with
# install_ddl -- they must share a single shape so the diff's target model
# (built by install_ddl into a temp schema) matches a brand-new-table
# emitted by the diff apply/upgrade path (karr k28, ADR 0005 cross-ref).
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::DB2::Diff::Table->diff(
    {},
    { author => { table_name => 'author' } },
    {
      author => [
        { column_name => 'id',   catalog_type => 'integer', is_pk => 1 },
        { column_name => 'name', catalog_type => 'varchar',  catalog_size => 255, not_null => 1 },
      ],
    },
    { author => [] },
  );
  my $sql = $ops[0]->as_sql;
  like($sql, qr/CREATE TABLE "author"\s*\(/, 'Diff::Table quotes the new table');
  like($sql, qr/"id"\s+INTEGER/,             'Diff::Table quotes column "id"');
  like($sql, qr/"name"\s+VARCHAR\(255\)/,    'Diff::Table quotes column "name"');
  like($sql, qr/PRIMARY KEY \("id"\)/,       'Diff::Table quotes the PK list');
  unlike($sql, qr/CREATE TABLE author\s*\(/,
    'Diff::Table create does not emit an unquoted CREATE TABLE');
}

{
  my $fk = {
    constraint_name => 'fk_book_author_id',
    from_columns    => ['author_id'],
    to_table        => 'author',
    to_columns      => ['id'],
    on_delete       => 'CASCADE',
    on_update       => 'NO ACTION',
  };
  my @ops = DBIO::DB2::Diff::Table->diff(
    {},
    { book => { table_name => 'book' } },
    { book => [ { column_name => 'author_id', catalog_type => 'integer' } ] },
    { book => [ $fk ] },
  );
  my $sql = $ops[0]->as_sql;
  like($sql,
    qr/CONSTRAINT "fk_book_author_id" FOREIGN KEY \("author_id"\) REFERENCES "author"\("id"\) ON DELETE CASCADE/,
    'Diff::Table quotes the inline FK clause body');
}

# ---------------------------------------------------------------------------
# Diff::Column ALTER path must also be quoted -- an unquoted ALTER TABLE
# target would still find the table (upper-folds to its real name), but
# ADD/DROP/ALTER COLUMN names are the half that actually has to match the
# case-sensitive column the live DB stores, and they're the half t/10-db2.t
# creates via raw quoted DDL.
# ---------------------------------------------------------------------------
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
  my $sql = $ops[0]->as_sql;
  like($sql, qr/ALTER TABLE "t" ADD COLUMN "extra" VARCHAR/,
    'Diff::Column quotes table + column in ADD COLUMN');
}

{
  my @ops = DBIO::DB2::Diff::Column->diff(
    { t => [ { column_name => 'a', catalog_type => 'integer', not_null => 0 } ] },
    { t => [ { column_name => 'a', catalog_type => 'varchar', catalog_size => 50, not_null => 1 } ] },
    { t => {} }, { t => {} },
  );
  my $sql = $ops[0]->as_sql;
  like($sql, qr/ALTER TABLE "t" ALTER COLUMN "a" SET DATA TYPE VARCHAR\(50\);/,
    'Diff::Column quotes the SET DATA TYPE form');
  like($sql, qr/ALTER TABLE "t" ALTER COLUMN "a" SET NOT NULL;/,
    'Diff::Column quotes the SET NOT NULL form');
}

# ---------------------------------------------------------------------------
# Diff::Index must quote the index name, the target table, and each column.
# ---------------------------------------------------------------------------
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
  my $sql = $ops[0]->as_sql;
  like($sql, qr/CREATE UNIQUE INDEX "idx_t_name" ON "t" \("name"\)/,
    'Diff::Index quotes name + table + columns');
  unlike($sql, qr/CREATE INDEX idx_t_name/,
    'Diff::Index does not emit an unquoted CREATE INDEX name');
}

# ---------------------------------------------------------------------------
# Diff::ForeignKey ADD/DROP must quote the table, the constraint name, and
# the whole FK clause body (via the shared DDL::_fk_constraint_clause).
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::DB2::Diff::ForeignKey->diff(
    { book => [] },
    {
      book => [
        {
          constraint_name => 'fk_book_author_id',
          from_columns    => ['author_id'],
          to_table        => 'author',
          to_columns      => ['id'],
          on_delete       => 'NO ACTION',
          on_update       => 'NO ACTION',
        },
      ],
    },
    { author => {}, book => {} },
    { author => {}, book => {} },
  );
  like($ops[0]->as_sql,
    qr/ALTER TABLE "book" ADD CONSTRAINT "fk_book_author_id" FOREIGN KEY \("author_id"\) REFERENCES "author"\("id"\)/,
    'Diff::ForeignKey ADD quotes the whole clause body');
}

{
  my @ops = DBIO::DB2::Diff::ForeignKey->diff(
    {
      book => [
        {
          constraint_name => 'SQL230101_REALNAME',
          from_columns    => ['author_id'],
          to_table        => 'author',
          to_columns      => ['id'],
          on_delete       => 'NO ACTION',
          on_update       => 'NO ACTION',
        },
      ],
    },
    { book => [] },
    { author => {}, book => {} },
    { author => {}, book => {} },
  );
  like($ops[0]->as_sql,
    qr/ALTER TABLE "book" DROP FOREIGN KEY "SQL230101_REALNAME"/,
    'Diff::ForeignKey DROP quotes the server-carried constraint name');
}

done_testing;