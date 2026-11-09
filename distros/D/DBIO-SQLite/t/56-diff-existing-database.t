use strict;
use warnings;
use Test::More;
use Test::Exception;

# A database deployed before every identifier was quoted (karr k57) holds its
# names bare: CREATE TABLE item (id INTEGER ...), CREATE INDEX idx ON item
# (name). The target an upgrade compares it with is installed by the DDL of
# today and has every one of those names in double quotes. They are the same
# tables and the same indexes, and an upgrade of an unchanged schema must find
# nothing to do.
#
# Three places read the text of a stored statement, and each has to read a
# name the same however it is quoted: the comparison of two CREATE INDEX
# statements, the rebuild that swaps the table's name in a CREATE TABLE, and
# the reading of a column's declaration out of one.

BEGIN {
  eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite required';
}

use DBI;
use DBIO::SQLite::Deploy;
use DBIO::SQLite::Diff::Index;
use DBIO::SQLite::Diff::Rebuild;
use DBIO::SQLite::Introspect;

# ---------------------------------------------------------------------------
# The database, created by hand. This is the text DBIO::SQLite::DDL wrote for
# the schema below before it quoted names, statement for statement: a plain
# table, one with a UNIQUE and a foreign key, one with a two-column key, and
# four explicit indexes -- plain, unique, partial, and over an expression.
# ---------------------------------------------------------------------------
my @OLD_DDL = (
  <<'SQL',
CREATE TABLE item (
  id INTEGER PRIMARY KEY NOT NULL,
  owner_id INTEGER NOT NULL,
  sku VARCHAR(20) NOT NULL,
  name VARCHAR(40),
  active INTEGER NOT NULL DEFAULT 1,
  UNIQUE (sku),
  FOREIGN KEY (owner_id) REFERENCES owner(id) ON DELETE CASCADE
)
SQL
  'CREATE INDEX idx_item_active ON item (name) WHERE active = 1',
  'CREATE INDEX idx_item_lower ON item (lower(name))',
  'CREATE INDEX idx_item_name ON item (name)',
  'CREATE UNIQUE INDEX idx_item_owner ON item (owner_id, name)',
  <<'SQL',
CREATE TABLE owner (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(40) NOT NULL
)
SQL
  <<'SQL',
CREATE TABLE tag (
  item_id INTEGER NOT NULL,
  label VARCHAR(20) NOT NULL,
  PRIMARY KEY (item_id, label),
  FOREIGN KEY (item_id) REFERENCES item(id)
)
SQL
);

sub old_database {
  my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
  $dbh->do('PRAGMA foreign_keys = ON');
  $dbh->do($_) for @OLD_DDL;
  $dbh->do(q{INSERT INTO owner (id, name) VALUES (1, 'Ada')});
  $dbh->do(q{INSERT INTO item (id, owner_id, sku, name) VALUES (1, 1, 'A-1', 'anvil')});
  $dbh->do(q{INSERT INTO item (id, owner_id, sku, name, active) VALUES (2, 1, 'B-2', 'bell', 0)});
  $dbh->do(q{INSERT INTO tag (item_id, label) VALUES (1, 'heavy')});
  return $dbh;
}

# ---------------------------------------------------------------------------
# The result classes that describe it, and two variants: one whose partial
# index has another WHERE, one that adds a column to "owner" and makes
# "item"."name" NOT NULL.
# ---------------------------------------------------------------------------
for my $variant (
  [ OldDb      => 'active = 1', 1, '' ],
  [ OldDbWhere => 'active = 0', 1, '' ],
  [ OldDbV2    => 'active = 1', 0,
    q{note => { data_type => 'varchar', size => 40, is_nullable => 1, default_value => 'none' },} ],
) {
  my ($ns, $where, $name_nullable, $note) = @$variant;
  my $code = <<'PERL';
    package __NS__;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('SQLite');

    package __NS__::Result::Owner;
    use base 'DBIO::Core';
    __PACKAGE__->table('owner');
    __PACKAGE__->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      name => { data_type => 'varchar', size => 40, is_nullable => 0 },
      __NOTE__
    );
    __PACKAGE__->set_primary_key('id');

    package __NS__::Result::Item;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('SQLite::Result');
    __PACKAGE__->table('item');
    __PACKAGE__->add_columns(
      id       => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      owner_id => { data_type => 'integer', is_nullable => 0 },
      sku      => { data_type => 'varchar', size => 20, is_nullable => 0 },
      name     => { data_type => 'varchar', size => 40, is_nullable => __NAME_NULLABLE__ },
      active   => { data_type => 'integer', is_nullable => 0, default_value => 1 },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->add_unique_constraint(item_sku => ['sku']);
    __PACKAGE__->belongs_to(owner => '__NS__::Result::Owner', 'owner_id',
      { on_delete => 'CASCADE' });
    __PACKAGE__->sqlite_index(idx_item_name   => { columns => ['name'] });
    __PACKAGE__->sqlite_index(idx_item_owner  => { columns => [ 'owner_id', 'name' ], unique => 1 });
    __PACKAGE__->sqlite_index(idx_item_active => { columns => ['name'], where => '__WHERE__' });
    __PACKAGE__->sqlite_index(idx_item_lower  => { expression => 'lower(name)' });

    package __NS__::Result::Tag;
    use base 'DBIO::Core';
    __PACKAGE__->table('tag');
    __PACKAGE__->add_columns(
      item_id => { data_type => 'integer', is_nullable => 0 },
      label   => { data_type => 'varchar', size => 20, is_nullable => 0 },
    );
    __PACKAGE__->set_primary_key('item_id', 'label');
    __PACKAGE__->belongs_to(item => '__NS__::Result::Item', 'item_id');

    __NS__->register_class($_ => "__NS__::Result::$_") for qw(Owner Item Tag);
    1;
PERL
  $code =~ s/__NS__/$ns/g;
  $code =~ s/__WHERE__/$where/g;
  $code =~ s/__NAME_NULLABLE__/$name_nullable/g;
  $code =~ s/__NOTE__/$note/g;
  eval $code or die $@;    ## no critic (ProhibitStringyEval)
}

sub deploy_for {
  my ($class, $dbh) = @_;
  return DBIO::SQLite::Deploy->new(schema => $class->connect(sub { $dbh }));
}

# ---------------------------------------------------------------------------
# The unchanged schema: nothing to do.
# ---------------------------------------------------------------------------
{
  my $dbh  = old_database();
  my $diff = deploy_for(OldDb => $dbh)->diff;

  ok(!$diff->has_changes,
    'a database with bare names does not differ from the schema that describes it')
    or diag($diff->summary);
  is_deeply([ map { ref($_) . ' ' . $_->summary } @{ $diff->operations } ], [],
    'not one op: no index is dropped to be created again under a quoted name');

  # The two sides do spell the statements differently -- that is the premise.
  my $target = deploy_for(OldDb => $dbh)->_build_target_model;
  my $source = DBIO::SQLite::Introspect->new(dbh => $dbh)->model;
  is($source->{indexes}{item}{idx_item_active}{sql},
    'CREATE INDEX idx_item_active ON item (name) WHERE active = 1',
    'the database has the index as it was written then');
  is($target->{indexes}{item}{idx_item_active}{sql},
    'CREATE INDEX "idx_item_active" ON "item" ("name") WHERE active = 1',
    'the target has it as it is written now');
}

# ---------------------------------------------------------------------------
# The control: a changed WHERE is still a change, of that index and no other.
# ---------------------------------------------------------------------------
{
  my $dbh    = old_database();
  my $deploy = deploy_for(OldDbWhere => $dbh);
  my $diff   = $deploy->diff;

  is_deeply(
    [ map { [ ref $_, $_->action, $_->index_name ] } @{ $diff->operations } ],
    [
      [ 'DBIO::SQLite::Diff::Index', 'drop',   'idx_item_active' ],
      [ 'DBIO::SQLite::Diff::Index', 'create', 'idx_item_active' ],
    ],
    'another WHERE in the result class: that index is dropped and created, and only it',
  );

  lives_ok { $deploy->apply($diff) } 'and the change applies';
  is(
    scalar $dbh->selectrow_array(
      q{SELECT sql FROM sqlite_master WHERE name = 'idx_item_active'}),
    'CREATE INDEX "idx_item_active" ON "item" ("name") WHERE active = 0',
    'the database has the new index',
  );
  ok(!$deploy->diff->has_changes, 'after which nothing is left to do');
}

# ---------------------------------------------------------------------------
# An upgrade of such a database. "owner" gains a column by ADD COLUMN, whose
# declaration is read out of the target's CREATE TABLE; "item" is rebuilt, and
# the rebuild takes that statement and swaps the name in it.
# ---------------------------------------------------------------------------
{
  my $dbh    = old_database();
  my $deploy = deploy_for(OldDbV2 => $dbh);
  my $diff   = $deploy->diff;

  is_deeply(
    [ map { [ ref $_, $_->table_name ] } grep { !$_->isa('DBIO::SQLite::Diff::Index') } @{ $diff->operations } ],
    [
      [ 'DBIO::SQLite::Diff::Column',  'owner' ],
      [ 'DBIO::SQLite::Diff::Rebuild', 'item'  ],
    ],
    'v2: one column added to "owner", "item" rebuilt, "tag" untouched',
  );

  my $sql = $diff->as_sql;
  like($sql, qr/^ALTER TABLE "owner" ADD COLUMN "note" VARCHAR\(40\) DEFAULT 'none';$/m,
    'the added column carries its declaration from the quoted target statement');

  lives_ok { $deploy->apply($diff) } 'the upgrade applies to the old database' or diag($sql);

  is_deeply(
    $dbh->selectall_arrayref('SELECT id, owner_id, sku, name, active FROM item ORDER BY id'),
    [ [ 1, 1, 'A-1', 'anvil', 1 ], [ 2, 1, 'B-2', 'bell', 0 ] ],
    'the rows of the rebuilt table survived',
  );
  is_deeply($dbh->selectall_arrayref('SELECT id, name, note FROM owner'),
    [ [ 1, 'Ada', 'none' ] ], 'the other table has its new column');
  is_deeply($dbh->selectall_arrayref('SELECT item_id, label FROM tag'),
    [ [ 1, 'heavy' ] ], 'and the table pointing at the rebuilt one still has its row');

  my $model = DBIO::SQLite::Introspect->new(dbh => $dbh)->model;
  is_deeply(
    [ sort grep { ($model->{indexes}{item}{$_}{origin} // '') eq 'c' } keys %{ $model->{indexes}{item} } ],
    [qw(idx_item_active idx_item_lower idx_item_name idx_item_owner)],
    'the four explicit indexes are on the rebuilt table',
  );

  my $settled = $deploy->diff;
  ok(!$settled->has_changes, 'a second diff is empty') or diag($settled->summary);
}

# ---------------------------------------------------------------------------
# The comparison of two CREATE INDEX statements, case by case. Both models
# have the same index with the same fields; only the statement differs.
# ---------------------------------------------------------------------------
sub index_ops {
  my ($old_sql, $new_sql) = @_;
  my $model = sub {
    return { item => { idx => {
      index_name => 'idx', is_unique => 0, columns => ['name'],
      origin => 'c', sql => $_[0],
    } } };
  };
  return [ map { $_->action }
    DBIO::SQLite::Diff::Index->diff($model->($old_sql), $model->($new_sql)) ];
}

my $QUOTED = 'CREATE INDEX "idx" ON "item" ("name", "sku") WHERE active = 1';

# A name is the same name however it is quoted, at the places where the
# statement has a name: the index, the table, an entry of the column list.
for my $same (
  [ 'bare names'       => 'CREATE INDEX idx ON item (name, sku) WHERE active = 1'       ],
  [ 'backticks'        => 'CREATE INDEX `idx` ON `item` (`name`, `sku`) WHERE active = 1' ],
  [ 'brackets'         => 'CREATE INDEX [idx] ON [item] ([name], [sku]) WHERE active = 1' ],
  [ 'mixed'            => 'CREATE INDEX idx ON "item" ([name], sku) WHERE active = 1'   ],
  [ 'other whitespace' => "CREATE  INDEX idx\n  ON item(name,sku)\n  WHERE active  =  1" ],
  [ 'a comment'        => 'CREATE INDEX idx /* x */ ON item (name, sku) -- y' . "\n" . 'WHERE active = 1' ],
  [ 'itself'           => $QUOTED ],
) {
  my ($what, $sql) = @$same;
  is_deeply(index_ops($sql, $QUOTED), [], "the same index: $what, old to new");
  is_deeply(index_ops($QUOTED, $sql), [], "the same index: $what, new to old");
}

is_deeply(
  index_ops('CREATE UNIQUE INDEX idx ON item (name)', 'CREATE UNIQUE INDEX "idx" ON "item" ("name")'),
  [], 'the same index: a UNIQUE one');
is_deeply(
  index_ops('CREATE INDEX idx ON "a""b" ("c""d")', 'CREATE INDEX "idx" ON [a"b] (`c"d`)'),
  [], 'the same index: a name with a double quote in it, doubled or not as its quoting has it');

# Everything that is not a name at such a place is compared as it stands. That
# is the SQL a schema gives as "where" and "expression", which is written as
# given and so comes back the same from an unchanged schema.
for my $changed (
  [ 'another value in the WHERE'   => 'CREATE INDEX "idx" ON "item" ("name", "sku") WHERE active = 0' ],
  [ 'another column in the WHERE'  => 'CREATE INDEX "idx" ON "item" ("name", "sku") WHERE retired = 1' ],
  [ 'no WHERE'                     => 'CREATE INDEX "idx" ON "item" ("name", "sku")' ],
  [ 'a string for a name in WHERE' => q{CREATE INDEX "idx" ON "item" ("name", "sku") WHERE 'active' = 1} ],
  [ 'a quoted name in the WHERE'   => 'CREATE INDEX "idx" ON "item" ("name", "sku") WHERE "active" = 1' ],
  [ 'another column'               => 'CREATE INDEX "idx" ON "item" ("name", "ean") WHERE active = 1' ],
  [ 'the columns in another order' => 'CREATE INDEX "idx" ON "item" ("sku", "name") WHERE active = 1' ],
  [ 'a descending column'          => 'CREATE INDEX "idx" ON "item" ("name" DESC, "sku") WHERE active = 1' ],
  [ 'a collation'                  => 'CREATE INDEX "idx" ON "item" ("name" COLLATE NOCASE, "sku") WHERE active = 1' ],
  [ 'an expression for a column'   => 'CREATE INDEX "idx" ON "item" (lower("name"), "sku") WHERE active = 1' ],
  [ 'a string for a column'        => q{CREATE INDEX "idx" ON "item" ('name', "sku") WHERE active = 1} ],
  [ 'UNIQUE'                       => 'CREATE UNIQUE INDEX "idx" ON "item" ("name", "sku") WHERE active = 1' ],
  [ 'another table'                => 'CREATE INDEX "idx" ON "items" ("name", "sku") WHERE active = 1' ],
  [ 'a name in another letter case' => 'CREATE INDEX "idx" ON "item" ("Name", "sku") WHERE active = 1' ],
) {
  my ($what, $sql) = @$changed;
  is_deeply(index_ops($QUOTED, $sql), [qw(drop create)], "a changed index: $what");
  is_deeply(index_ops($sql, $QUOTED), [qw(drop create)], "a changed index: $what, the other way");
}

# An expression is SQL, not a name: quoting inside it is a difference, and a
# string is never taken for a name.
is_deeply(
  index_ops('CREATE INDEX idx ON item (lower(name))', 'CREATE INDEX "idx" ON "item" (lower(name))'),
  [], 'an expression index: the same expression under a quoted index and table name');
is_deeply(
  index_ops('CREATE INDEX idx ON item (lower(name))', 'CREATE INDEX idx ON item (lower("name"))'),
  [qw(drop create)], 'an expression index: the expression written differently is a change');
is_deeply(
  index_ops(q{CREATE INDEX idx ON item (name) WHERE kind = 'x'}, q{CREATE INDEX idx ON item (name) WHERE kind = "x"}),
  [qw(drop create)], 'a string in the WHERE is not read as a name');
is_deeply(
  index_ops(q{CREATE INDEX idx ON item (name) WHERE kind = 'a  b'}, q{CREATE INDEX idx ON item (name) WHERE kind = 'a b'}),
  [qw(drop create)], 'and the whitespace inside a string is part of it');

# A statement that is no CREATE INDEX is compared with its whitespace set
# aside and nothing else.
is_deeply(index_ops('  something   else ', 'something else'), [],
  'not a CREATE INDEX: whitespace is no difference');
is_deeply(index_ops('something else', 'something "else"'), [qw(drop create)],
  'not a CREATE INDEX: quoting is');

# ---------------------------------------------------------------------------
# The rebuild finds the table's name in the stored statement in every quoting,
# and only the name: not a longer one that begins with it.
# ---------------------------------------------------------------------------
sub rebuild_create {
  my ($name, $table_sql) = @_;
  my ($create) = grep { /\ACREATE TABLE/ } DBIO::SQLite::Diff::Rebuild->new(
    table_name => $name, table_sql => $table_sql, copy_columns => ['id'],
  )->statements;
  return $create;
}

for my $case (
  [ 'item', 'CREATE TABLE item (id INTEGER)',     'CREATE TABLE "item__dbio_rebuild" (id INTEGER);'  ],
  [ 'item', 'CREATE TABLE item(id INTEGER)',      'CREATE TABLE "item__dbio_rebuild"(id INTEGER);'   ],
  [ 'item', 'CREATE TABLE "item" (id INTEGER)',   'CREATE TABLE "item__dbio_rebuild" (id INTEGER);'  ],
  [ 'item', 'CREATE TABLE `item` (id INTEGER)',   'CREATE TABLE "item__dbio_rebuild" (id INTEGER);'  ],
  [ 'item', 'CREATE TABLE [item] (id INTEGER)',   'CREATE TABLE "item__dbio_rebuild" (id INTEGER);'  ],
  [ 'item', 'CREATE TABLE Item (id INTEGER)',     'CREATE TABLE "item__dbio_rebuild" (id INTEGER);'  ],
  [ 'order', 'CREATE TABLE "order" ("order" INTEGER)',
    'CREATE TABLE "order__dbio_rebuild" ("order" INTEGER);' ],
  [ 'a"b', 'CREATE TABLE "a""b" (id INTEGER)',    'CREATE TABLE "a""b__dbio_rebuild" (id INTEGER);'  ],
  [ 'my table', 'CREATE TABLE "my table" (id INTEGER)',
    'CREATE TABLE "my table__dbio_rebuild" (id INTEGER);' ],
  [ 'item', 'CREATE TABLE IF NOT EXISTS item (id INTEGER)',
    'CREATE TABLE IF NOT EXISTS "item__dbio_rebuild" (id INTEGER);' ],
  # Not this table's statement: left as it is.
  [ 'item', 'CREATE TABLE item2 (id INTEGER)',    'CREATE TABLE item2 (id INTEGER);' ],
) {
  my ($name, $stored, $expected) = @$case;
  is(rebuild_create($name, $stored), $expected, "rebuild of <$name> from: $stored");
}

done_testing;
