use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBI;

use_ok 'DBIO::SQLite::Diff';
use_ok 'DBIO::SQLite::Diff::Rebuild';

# ---------------------------------------------------------------------------
# Part A: model-level diff. A column nullability change forces a table
# rebuild; the rebuild reuses the target table's captured CREATE statement
# verbatim (faithful PK) and re-emits the table's explicit indexes.
# The source/target SQL strings here contain AUTOINCREMENT because they
# simulate a DB that was originally deployed with AUTOINCREMENT; the rebuild
# faithfully preserves whatever was in the captured CREATE statement.
# ---------------------------------------------------------------------------
{
  my $idx = {
    index_name => 'idx_item_name',
    columns    => ['name'],
    is_unique  => 0,
    origin     => 'c',
    sql        => 'CREATE INDEX idx_item_name ON item(name)',
  };

  my $source = {
    tables => { item => {
      table_name => 'item', kind => 'table',
      sql => 'CREATE TABLE item (id INTEGER PRIMARY KEY AUTOINCREMENT, '
           . 'name TEXT NOT NULL, val INTEGER)',
    } },
    columns => { item => [
      { column_name => 'id',   data_type => 'INTEGER', is_pk => 1, not_null => 0 },
      { column_name => 'name', data_type => 'TEXT',    not_null => 1 },
      { column_name => 'val',  data_type => 'INTEGER', not_null => 0 },
    ] },
    indexes      => { item => { idx_item_name => $idx } },
    foreign_keys => {},
  };

  my $target = {
    tables => { item => {
      table_name => 'item', kind => 'table',
      sql => 'CREATE TABLE item (id INTEGER PRIMARY KEY AUTOINCREMENT, '
           . 'name TEXT NOT NULL, val INTEGER NOT NULL)',
    } },
    columns => { item => [
      { column_name => 'id',   data_type => 'INTEGER', is_pk => 1, not_null => 0 },
      { column_name => 'name', data_type => 'TEXT',    not_null => 1 },
      { column_name => 'val',  data_type => 'INTEGER', not_null => 1 },
    ] },
    indexes      => { item => { idx_item_name => $idx } },
    foreign_keys => {},
  };

  my $diff = DBIO::SQLite::Diff->new(source => $source, target => $target);
  ok($diff->has_changes, 'nullability change is a change');

  my $sql = $diff->as_sql;

  like($sql, qr/PRAGMA foreign_keys=OFF/, 'brackets with FK off');
  like($sql, qr/CREATE TABLE item__dbio_rebuild .*PRIMARY KEY AUTOINCREMENT/s,
    'rebuild reuses target DDL -- PK + AUTOINCREMENT survive');
  like($sql, qr/val INTEGER NOT NULL/, 'new column constraint in rebuilt table');
  like($sql, qr/INSERT INTO item__dbio_rebuild \(id, name, val\)/,
    'copies the surviving columns');
  like($sql, qr/SELECT id, name, val FROM item/, 'selects from the old table');
  like($sql, qr/DROP TABLE item;/,                     'drops the old table');
  like($sql, qr/ALTER TABLE item__dbio_rebuild RENAME TO item;/, 'renames into place');
  like($sql, qr/PRAGMA foreign_keys=ON/,               'restores FK enforcement');
  like($sql, qr/CREATE INDEX idx_item_name/,           're-creates the explicit index');
  unlike($sql, qr/not supported/, 'no ALTER-unsupported comment when rebuilding');

  like($diff->summary, qr/~ table rebuild: item/, 'summary names the rebuild');
}

# ---------------------------------------------------------------------------
# Part A2: no captured CREATE sql (e.g. compiled-model path) -> fall back to
# the per-column alter comment, no rebuild.
# ---------------------------------------------------------------------------
{
  my $source = {
    tables  => { t => { table_name => 't' } },
    columns => { t => [ { column_name => 'a', data_type => 'INTEGER', not_null => 0 } ] },
    indexes => {}, foreign_keys => {},
  };
  my $target = {
    tables  => { t => { table_name => 't' } },          # no sql
    columns => { t => [ { column_name => 'a', data_type => 'TEXT', not_null => 1 } ] },
    indexes => {}, foreign_keys => {},
  };
  my $diff = DBIO::SQLite::Diff->new(source => $source, target => $target);
  like($diff->as_sql, qr/not supported/,
    'without captured DDL the alter comment stands');
  unlike($diff->as_sql, qr/__dbio_rebuild/, 'no rebuild attempted');
}

# ---------------------------------------------------------------------------
# Part B: real deploy round-trip. Change a column to NOT NULL (in-place ALTER
# is impossible in SQLite), upgrade, and confirm data + PK are preserved and
# the new constraint is enforced.
# ---------------------------------------------------------------------------
SKIP: {
  eval { require DBD::SQLite; 1 } or skip 'DBD::SQLite required', 1;

  {
    package RebuildTest::V1;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('SQLite');
  }
  {
    package RebuildTest::V1::Result::Item;
    use base 'DBIO::Core';
    __PACKAGE__->table('item');
    __PACKAGE__->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      name => { data_type => 'text',    is_nullable => 0 },
      val  => { data_type => 'integer', is_nullable => 1 },
    );
    __PACKAGE__->set_primary_key('id');
  }
  RebuildTest::V1->register_class(Item => 'RebuildTest::V1::Result::Item');

  {
    package RebuildTest::V2;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('SQLite');
  }
  {
    package RebuildTest::V2::Result::Item;
    use base 'DBIO::Core';
    __PACKAGE__->table('item');
    __PACKAGE__->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      name => { data_type => 'text',    is_nullable => 0 },
      val  => { data_type => 'integer', is_nullable => 0 },   # now NOT NULL
    );
    __PACKAGE__->set_primary_key('id');
  }
  RebuildTest::V2->register_class(Item => 'RebuildTest::V2::Result::Item');

  require DBIO::SQLite::Deploy;

  my $schema = RebuildTest::V1->connect('dbi:SQLite::memory:', '', '', { AutoCommit => 1 });
  my $deploy = DBIO::SQLite::Deploy->new(schema => $schema);
  $deploy->install;

  $schema->resultset('Item')->create({ name => 'Foo', val => 10 });
  $schema->resultset('Item')->create({ name => 'Bar', val => 20 });

  my $v2     = RebuildTest::V2->connect(sub { $schema->storage->dbh });
  my $deploy2 = DBIO::SQLite::Deploy->new(schema => $v2);

  my $diff = $deploy2->diff;
  ok($diff->has_changes, 'diff sees the nullability change');
  like($diff->as_sql, qr/__dbio_rebuild/, 'upgrade routes through a rebuild');

  lives_ok { $deploy2->apply($diff) } 'rebuild applies cleanly';

  my $dbh = $schema->storage->dbh;

  # Data preserved
  my $rows = $dbh->selectall_arrayref(
    'SELECT id, name, val FROM item ORDER BY id', { Slice => {} });
  is(scalar @$rows, 2, 'both rows survived the rebuild');
  is($rows->[0]{name}, 'Foo', 'first row name preserved');
  is($rows->[1]{val},  20,    'second row value preserved');

  # PK intact (plain INTEGER PRIMARY KEY -- no AUTOINCREMENT needed)
  my ($create) = $dbh->selectrow_array(
    q{SELECT sql FROM sqlite_master WHERE type='table' AND name='item'});
  like($create, qr/INTEGER PRIMARY KEY/i, 'INTEGER PRIMARY KEY intact after rebuild');

  my $new = $schema->resultset('Item')->create({ name => 'Baz', val => 30 });
  ok($new->id, 'auto-increment PK still issues ids after rebuild');

  # New NOT NULL constraint enforced
  dies_ok {
    $dbh->do(q{INSERT INTO item (name) VALUES ('NoVal')});
  } 'val is now NOT NULL -- insert without it fails';

  # Settled: no further changes
  ok(!$deploy2->diff->has_changes, 'no diff remains after the rebuild');
}

# ---------------------------------------------------------------------------
# Part C: rebuilding a table that OTHER tables reference. The rebuild runs
# with foreign_keys off; afterwards apply() runs PRAGMA foreign_key_check and
# must find the cross-table references still intact (no throw).
# ---------------------------------------------------------------------------
SKIP: {
  eval { require DBD::SQLite; 1 } or skip 'DBD::SQLite required', 1;

  {
    package FkRebuild::V1;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('SQLite');
  }
  {
    package FkRebuild::V1::Result::Author;
    use base 'DBIO::Core';
    __PACKAGE__->table('author');
    __PACKAGE__->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      name => { data_type => 'text',    is_nullable => 1 },
    );
    __PACKAGE__->set_primary_key('id');
  }
  {
    package FkRebuild::V1::Result::Book;
    use base 'DBIO::Core';
    __PACKAGE__->table('book');
    __PACKAGE__->add_columns(
      id        => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      author_id => { data_type => 'integer', is_nullable => 0 },
      title     => { data_type => 'text',    is_nullable => 0 },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to('author' => 'FkRebuild::V1::Result::Author', 'author_id');
  }
  FkRebuild::V1->register_class(Author => 'FkRebuild::V1::Result::Author');
  FkRebuild::V1->register_class(Book   => 'FkRebuild::V1::Result::Book');

  {
    package FkRebuild::V2;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('SQLite');
  }
  {
    package FkRebuild::V2::Result::Author;
    use base 'DBIO::Core';
    __PACKAGE__->table('author');
    __PACKAGE__->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      name => { data_type => 'text',    is_nullable => 0 },   # now NOT NULL -> rebuild
    );
    __PACKAGE__->set_primary_key('id');
  }
  {
    package FkRebuild::V2::Result::Book;
    use base 'DBIO::Core';
    __PACKAGE__->table('book');
    __PACKAGE__->add_columns(
      id        => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      author_id => { data_type => 'integer', is_nullable => 0 },
      title     => { data_type => 'text',    is_nullable => 0 },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to('author' => 'FkRebuild::V2::Result::Author', 'author_id');
  }
  FkRebuild::V2->register_class(Author => 'FkRebuild::V2::Result::Author');
  FkRebuild::V2->register_class(Book   => 'FkRebuild::V2::Result::Book');

  require DBIO::SQLite::Deploy;

  my $schema = FkRebuild::V1->connect('dbi:SQLite::memory:', '', '', { AutoCommit => 1 });
  $schema->storage->dbh->do('PRAGMA foreign_keys = ON');
  DBIO::SQLite::Deploy->new(schema => $schema)->install;

  my $a = $schema->resultset('Author')->create({ name => 'Adams' });
  my $b = $schema->resultset('Book')->create({
    author_id => $a->id, title => 'Hitchhikers',
  });

  my $v2      = FkRebuild::V2->connect(sub { $schema->storage->dbh });
  my $deploy2 = DBIO::SQLite::Deploy->new(schema => $v2);

  my $diff = $deploy2->diff;
  like($diff->as_sql, qr/__dbio_rebuild/, 'referenced table is rebuilt');

  lives_ok { $deploy2->apply($diff) }
    'apply lives -- foreign_key_check passes after rebuilding a referenced table';

  is($schema->resultset('Book')->find($b->id)->author->name, 'Adams',
    'cross-table reference still resolves after the rebuild');
}

done_testing;
