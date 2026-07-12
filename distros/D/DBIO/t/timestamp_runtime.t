use strict;
use warnings;

use Test::More;
use DateTime;

use DBIO::Test::Storage;

# Backs the DBIO::Timestamp SYNOPSIS at runtime: set_on_create / set_on_update
# columns are auto-populated on insert and update. The existing coverage
# (t/test/10_timestamp_helpers.t) only asserts the column *metadata* the
# helpers install; this asserts the values actually get set on the row (and
# reach the emitted INSERT/UPDATE).
#
# Mock-only. get_timestamp() is overridden to a controllable fixed value so the
# assertions are deterministic and can fail on regression (a broken auto-set
# leaves the column undef / unchanged).

{
  package TestDBIO::TS::Schema;
  use base 'DBIO::Schema';
}
{
  package TestDBIO::TS::Schema::Result::Article;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/Timestamp/);
  __PACKAGE__->table('article');
  __PACKAGE__->add_columns(
    id         => { data_type => 'integer',  is_auto_increment => 1 },
    title      => { data_type => 'varchar',  size => 255 },
    created_at => { data_type => 'datetime', set_on_create => 1 },
    updated_at => { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  our $NOW;
  sub get_timestamp { $NOW }
}

TestDBIO::TS::Schema->register_class(Article => 'TestDBIO::TS::Schema::Result::Article');

my $schema  = TestDBIO::TS::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));
my $storage = $schema->storage;

my $created = DateTime->new(year => 2020, month => 1, day => 1);
my $updated = DateTime->new(year => 2021, month => 6, day => 15);

subtest 'insert auto-populates both create timestamps' => sub {
  local $TestDBIO::TS::Schema::Result::Article::NOW = $created;
  $storage->reset_captured;

  my $article = $schema->resultset('Article')->create({ title => 'Hello' });

  isa_ok $article->created_at, 'DateTime', 'created_at was set to a DateTime';
  isa_ok $article->updated_at, 'DateTime', 'updated_at was set to a DateTime';
  is $article->created_at->year, 2020, 'created_at holds the create-time value';
  is $article->updated_at->year, 2020, 'updated_at seeded at create time too';

  my ($insert) = grep { $_->{op} eq 'insert' } $storage->captured_queries;
  ok $insert, 'insert captured';
  like $insert->{sql}, qr/created_at/, 'created_at reached the INSERT column list';
  like $insert->{sql}, qr/updated_at/, 'updated_at reached the INSERT column list';

  # The timestamp column values were bound (not left null).
  my %bound = map { ($_->[0]{dbic_colname} // '') => $_->[1] } @{ $insert->{bind} };
  isa_ok $bound{created_at}, 'DateTime', 'the created_at bind value';
  isa_ok $bound{updated_at}, 'DateTime', 'the updated_at bind value';
};

subtest 'update bumps updated_at only, leaving created_at intact' => sub {
  my $article;
  {
    local $TestDBIO::TS::Schema::Result::Article::NOW = $created;
    $article = $schema->resultset('Article')->create({ title => 'First' });
  }
  is $article->updated_at->year, 2020, 'precondition: updated_at at create time';

  local $TestDBIO::TS::Schema::Result::Article::NOW = $updated;
  $storage->reset_captured;

  $article->update({ title => 'Second' });

  is $article->updated_at->year, 2021, 'updated_at was bumped to the update-time value';
  is $article->created_at->year, 2020, 'created_at was NOT touched on update';

  my ($upd) = grep { $_->{op} eq 'update' } $storage->captured_queries;
  ok $upd, 'update captured';
  like $upd->{sql}, qr/updated_at/, 'updated_at is in the UPDATE SET list';
  unlike $upd->{sql}, qr/created_at/, 'created_at is not re-written on update';
};

done_testing;
