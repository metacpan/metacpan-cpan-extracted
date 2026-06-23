use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use DBIO::GraphQL;
use My::Test qw(deploy_schema);
use GraphQL::Execution qw(execute);

{
  package CPK::Result::Book;
  use DBIO;
  __PACKAGE__->table('books');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    title => { data_type => 'varchar', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many(
    book_tags => 'CPK::Result::BookTag',
    { 'foreign.book_id' => 'self.id' }
  );
}
{
  package CPK::Result::Tag;
  use DBIO;
  __PACKAGE__->table('tags');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package CPK::Result::BookTag;
  use DBIO;
  __PACKAGE__->table('book_tags');
  __PACKAGE__->add_columns(
    book_id => { data_type => 'integer', is_nullable => 0 },
    tag_id  => { data_type => 'integer', is_nullable => 0 },
    note    => { data_type => 'varchar', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('book_id', 'tag_id');
  __PACKAGE__->belongs_to(
    book => 'CPK::Result::Book',
    { 'foreign.id' => 'self.book_id' }
  );
  __PACKAGE__->belongs_to(
    tag => 'CPK::Result::Tag',
    { 'foreign.id' => 'self.tag_id' }
  );
}
{
  package CPK::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class( Book    => 'CPK::Result::Book'    );
  __PACKAGE__->register_class( Tag     => 'CPK::Result::Tag'     );
  __PACKAGE__->register_class( BookTag => 'CPK::Result::BookTag' );
}

my $db = CPK::Schema->connect('dbi:SQLite:dbname=:memory:');
deploy_schema($db);

$db->resultset('Book')->create({ id => 1, title => 'Test Book' });
$db->resultset('Tag')->create({ id => 10, name => 'fiction' });
$db->resultset('Tag')->create({ id => 11, name => 'classic' });
$db->resultset('BookTag')->create({ book_id => 1, tag_id => 10, note => 'primary tag' });

my $result = DBIO::GraphQL->to_graphql($db);
my ($schema, $ctx) = @{$result}{qw(schema context)};

sub gql {
  my ($query, $vars) = @_;
  return execute($schema, $query, undef, $ctx, $vars // {});
}

# Schema shape
my $qf      = $schema->query->fields;
my $bt_args = $qf->{bookTag}{args};
ok(exists $qf->{bookTag},      'singular bookTag query exists');
ok(exists $bt_args->{book_id}, 'bookTag query has book_id arg');
ok(exists $bt_args->{tag_id},  'bookTag query has tag_id arg' );

# Singular composite - PK query
{
  my $res = gql('{ bookTag(book_id: 1, tag_id: 10) { book_id tag_id note } }');
  ok(!$res->{errors}, 'composite PK query: no errors')
    or diag explain $res->{errors};
  is($res->{data}{bookTag}{book_id}, 1,             'book_id correct');
  is($res->{data}{bookTag}{tag_id},  10,            'tag_id correct' );
  is($res->{data}{bookTag}{note},    'primary tag', 'note correct'   );
}

# createBookTag
{
  my $res = gql('mutation {
    createBookTag(book_id: 1, tag_id: 11, note: "secondary") {
      book_id tag_id note
    }
  }');

  ok(!$res->{errors}, 'createBookTag: no errors')
    or diag explain $res->{errors};
  is($res->{data}{createBookTag}{note}, 'secondary', 'note on new BookTag');
  is($db->resultset('BookTag')->count, 2, 'BookTag count is now 2');
}

# updateBookTag
{
  my $res = gql('mutation {
    updateBookTag(book_id: 1, tag_id: 10, note: "updated note") { note }
  }');

  ok(!$res->{errors}, 'updateBookTag: no errors')
    or diag explain $res->{errors};
  is($res->{data}{updateBookTag}{note}, 'updated note', 'note updated');
}

# deleteBookTag
{
  my $res = gql('mutation { deleteBookTag(book_id: 1, tag_id: 11) }');

  ok(!$res->{errors}, 'deleteBookTag: no errors');
  is($res->{data}{deleteBookTag}, 1, 'deleteBookTag returns true');
  is($db->resultset('BookTag')->count, 1, 'BookTag count back to 1');
}

done_testing;
