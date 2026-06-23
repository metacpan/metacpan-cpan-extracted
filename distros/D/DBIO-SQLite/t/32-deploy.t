use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBI;

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

use_ok 'DBIO::SQLite::Deploy';
use_ok 'DBIO::SQLite::DDL';

# v1 schema
{
  package DeployTest::SchemaV1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package DeployTest::SchemaV1::Result::Widget;
  use base 'DBIO::Core';

  __PACKAGE__->table('widget');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', size => 100, is_nullable => 0 },
    qty  => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
DeployTest::SchemaV1->register_class(Widget => 'DeployTest::SchemaV1::Result::Widget');

# v2 schema = v1 + extra column
{
  package DeployTest::SchemaV2;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package DeployTest::SchemaV2::Result::Widget;
  use base 'DBIO::Core';

  __PACKAGE__->table('widget');
  __PACKAGE__->add_columns(
    id          => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name        => { data_type => 'varchar', size => 100, is_nullable => 0 },
    qty         => { data_type => 'integer', is_nullable => 1 },
    description => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
DeployTest::SchemaV2->register_class(Widget => 'DeployTest::SchemaV2::Result::Widget');

# --- DDL generation ---
my $ddl_v1 = DBIO::SQLite::DDL->install_ddl('DeployTest::SchemaV1');
like($ddl_v1, qr/CREATE TABLE widget/, 'DDL has CREATE TABLE');
like($ddl_v1, qr/INTEGER PRIMARY KEY/, 'INTEGER PRIMARY KEY inline (no AUTOINCREMENT)');
like($ddl_v1, qr/name VARCHAR/, 'varchar column');
like($ddl_v1, qr/NOT NULL/,     'NOT NULL constraint');

# --- Install on fresh in-memory DB ---
my $schema_v1 = DeployTest::SchemaV1->connect('dbi:SQLite::memory:', '', '', { AutoCommit => 1 });
my $deploy_v1 = DBIO::SQLite::Deploy->new(schema => $schema_v1);

isa_ok($deploy_v1, 'DBIO::SQLite::Deploy');
is($deploy_v1->schema, $schema_v1, 'schema attr');

lives_ok { $deploy_v1->install } 'install on empty DB lives';

my $widget_exists = $schema_v1->storage->dbh->selectrow_array(
  q{SELECT 1 FROM sqlite_master WHERE type='table' AND name='widget'}
);
ok($widget_exists, 'widget table exists after install');

# CRUD round-trip
my $w = $schema_v1->resultset('Widget')->create({ name => 'Sprocket', qty => 7 });
ok($w->id,            'auto-increment populated');
is($w->name, 'Sprocket', 'name stored');
is($w->qty,  7,          'qty stored');

# --- Diff with no changes ---
{
  my $diff = $deploy_v1->diff;
  ok(!$diff->has_changes, 'no changes when schema matches DB');
}

# --- Diff after schema change ---
my $schema_v2_view = DeployTest::SchemaV2->connect(sub { $schema_v1->storage->dbh });
my $deploy_v2 = DBIO::SQLite::Deploy->new(schema => $schema_v2_view);

{
  my $diff = $deploy_v2->diff;
  ok($diff->has_changes, 'diff sees the new column');
  like($diff->as_sql, qr/ALTER TABLE widget ADD COLUMN description/,
    'diff emits ADD COLUMN');
  like($diff->summary, qr/\+column: widget\.description/,
    'summary mentions new column');
}

# --- Apply ---
{
  my $diff = $deploy_v2->diff;
  lives_ok { $deploy_v2->apply($diff) } 'apply lives';

  my $col_exists = $schema_v1->storage->dbh->selectrow_array(
    q{SELECT 1 FROM pragma_table_info('widget') WHERE name='description'}
  );
  ok($col_exists, 'description column exists after apply');

  # New column round-trips
  my $w2 = $schema_v2_view->resultset('Widget')->create({
    name => 'Gear', qty => 3, description => 'A round gear',
  });
  is($w2->description, 'A round gear', 'new column round-trips');
}

# --- Diff is empty after apply ---
{
  my $diff = $deploy_v2->diff;
  ok(!$diff->has_changes, 'no further changes after apply');
}

# --- Apply on empty diff is a no-op ---
{
  my $diff = $deploy_v2->diff;
  is($deploy_v2->apply($diff), undef, 'apply returns undef on empty diff');
}

# --- Upgrade as no-op ---
is($deploy_v2->upgrade, undef, 'upgrade returns undef when up to date');

# --- Upgrade applies pending changes ---
{
  my $schema_a = DeployTest::SchemaV1->connect('dbi:SQLite::memory:');
  my $da = DBIO::SQLite::Deploy->new(schema => $schema_a);
  $da->install;

  my $sb = DeployTest::SchemaV2->connect(sub { $schema_a->storage->dbh });
  my $db = DBIO::SQLite::Deploy->new(schema => $sb);

  my $diff = $db->upgrade;
  ok($diff,             'upgrade returns diff when applied');
  ok($diff->has_changes, 'returned diff has_changes');

  my $col_exists = $schema_a->storage->dbh->selectrow_array(
    q{SELECT 1 FROM pragma_table_info('widget') WHERE name='description'}
  );
  ok($col_exists, 'description column added by upgrade');
}

# --- Schema with FK + index ---
{
  package FkTest::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package FkTest::Schema::Result::Author;
  use base 'DBIO::Core';
  __PACKAGE__->table('author');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text',    is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package FkTest::Schema::Result::Book;
  use base 'DBIO::Core';
  __PACKAGE__->table('book');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    author_id => { data_type => 'integer', is_nullable => 0 },
    title     => { data_type => 'text',    is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to('author' => 'FkTest::Schema::Result::Author', 'author_id');
}
FkTest::Schema->register_class(Author => 'FkTest::Schema::Result::Author');
FkTest::Schema->register_class(Book   => 'FkTest::Schema::Result::Book');

my $fk_schema = FkTest::Schema->connect('dbi:SQLite::memory:');
$fk_schema->storage->dbh->do('PRAGMA foreign_keys = ON');

my $fk_deploy = DBIO::SQLite::Deploy->new(schema => $fk_schema);
lives_ok { $fk_deploy->install } 'install with FK lives';

# Verify FK is in place
my $fk_info = $fk_schema->storage->dbh->selectall_arrayref(
  q{PRAGMA foreign_key_list('book')}, { Slice => {} }
);
is(scalar @$fk_info, 1, 'one FK on book');
is($fk_info->[0]{table}, 'author', 'FK targets author');
is($fk_info->[0]{from},  'author_id', 'FK from author_id');
is($fk_info->[0]{to},    'id',        'FK to author.id');

# Insert via belongs_to
my $a = $fk_schema->resultset('Author')->create({ name => 'Adams' });
my $b = $fk_schema->resultset('Book')->create({
  author_id => $a->id, title => 'Hitchhikers',
});
is($b->author->name, 'Adams', 'belongs_to works after deploy');

done_testing;
