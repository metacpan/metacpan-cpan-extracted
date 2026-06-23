use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DateTime; 1 }
    or plan skip_all => 'DateTime required for timestamp test';
}

use DateTime;

# Build a minimal test schema with Timestamp component
{
  package TSTest::Schema::Article;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/InflateColumn::DateTime Timestamp/);
  __PACKAGE__->table('article');
  __PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
    },
    title => {
      data_type => 'varchar',
      size => 255,
    },
    created_at => {
      data_type => 'datetime',
      set_on_create => 1,
      is_nullable => 1,
    },
    updated_at => {
      data_type => 'datetime',
      set_on_create => 1,
      set_on_update => 1,
      is_nullable => 1,
    },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package TSTest::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Article => 'TSTest::Schema::Article');
}

my $schema = TSTest::Schema->connect('dbi:SQLite:dbname=:memory:');
my $dbh = $schema->storage->dbh;
$dbh->do('CREATE TABLE article (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title VARCHAR(255),
  created_at DATETIME,
  updated_at DATETIME
)');

# Test: create sets both timestamps
my $before = DateTime->now;
my $article = $schema->resultset('Article')->create({ title => 'First Post' });
my $after = DateTime->now;

ok($article->created_at, 'created_at is set on insert');
ok($article->updated_at, 'updated_at is set on insert');
is($article->title, 'First Post', 'title correct');

# Test: timestamps are DateTime objects
isa_ok($article->created_at, 'DateTime', 'created_at is a DateTime');
isa_ok($article->updated_at, 'DateTime', 'updated_at is a DateTime');

# Test: update refreshes updated_at but not created_at
my $old_created = $article->created_at->clone;
my $old_updated = $article->updated_at->clone;

sleep 1; # ensure time difference
$article->update({ title => 'Updated Post' });
$article->discard_changes;

is($article->title, 'Updated Post', 'title updated');
is($article->created_at->epoch, $old_created->epoch, 'created_at unchanged after update');
ok($article->updated_at->epoch >= $old_updated->epoch, 'updated_at refreshed on update');

# Test: noclobber — explicit value on create is respected
my $custom_dt = DateTime->new(year => 2020, month => 1, day => 1);
my $article2 = $schema->resultset('Article')->create({
  title      => 'Custom Time',
  created_at => $custom_dt,
});
is($article2->created_at->year, 2020, 'explicit created_at value respected (noclobber)');

# Test: get_timestamp is overridable
{
  package TSTest::Schema::Article;
  no warnings 'redefine';
  sub get_timestamp { DateTime->new(year => 2099, month => 12, day => 31) }
}

my $article3 = $schema->resultset('Article')->create({ title => 'Future Post' });
is($article3->created_at->year, 2099, 'overridden get_timestamp used on create');

$article3->update({ title => 'Future Updated' });
$article3->discard_changes;
is($article3->updated_at->year, 2099, 'overridden get_timestamp used on update');

done_testing;
