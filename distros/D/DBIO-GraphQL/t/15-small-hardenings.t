use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use DBIO::GraphQL;
use My::Test qw(deploy_schema);

# A singular lookup names its whole key; a relationship field of a keyless
# source resolves to undef; wide integers and exact decimals travel as String.

{
  package SH::Result::Author;
  use DBIO;
  __PACKAGE__->table('authors');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_nullable => 0 },
    name => { data_type => 'varchar', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package SH::Result::Log;
  use DBIO;
  __PACKAGE__->table('logs');
  __PACKAGE__->add_columns(
    msg     => { data_type => 'varchar', is_nullable => 0 },
    user_id => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->belongs_to(author => 'SH::Result::Author', 'user_id',
    { join_type => 'left' });
}
{
  package SH::Result::BookTag;
  use DBIO;
  __PACKAGE__->table('book_tags');
  __PACKAGE__->add_columns(
    book_id => { data_type => 'integer', is_nullable => 0 },
    tag_id  => { data_type => 'integer', is_nullable => 0 },
    note    => { data_type => 'varchar', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('book_id', 'tag_id');
}
{
  package SH::Result::Item;
  use DBIO;
  __PACKAGE__->table('items');
  __PACKAGE__->add_columns(
    id    => { data_type => 'bigint',  is_nullable => 0 },
    price => { data_type => 'numeric', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package SH::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class($_ => "SH::Result::$_")
    for qw(Author Log BookTag Item);
}
{
  package SH::Counter;
  use base 'DBIO::Storage::Statistics';
  sub query_start { my $s = shift; push @{ $s->{sql} }, [ @_ ] }
  sub query_end   { }
}

my $db = SH::Schema->connect('dbi:SQLite:dbname=:memory:');
deploy_schema($db);
$db->resultset('Author')->create({ id => 1, name => 'ann' });
$db->resultset('BookTag')->create({ book_id => 1, tag_id => 10, note => 'n1' });
$db->resultset('BookTag')->create({ book_id => 1, tag_id => 11, note => 'n2' });
$db->resultset('Log')->create({ msg => 'a', user_id => 1 });
$db->resultset('Log')->create({ msg => 'b', user_id => 1 });
$db->resultset('Item')->create({ id => 3_000_000_000, price => 5 });

my $r = DBIO::GraphQL->to_graphql($db, mutations => 1);
my $counter = SH::Counter->new;
$counter->{sql} = [];
$db->storage->debugobj($counter);
$db->storage->debug(2);   # level 2 traces the binds too

sub gql {
  my ($q) = @_;
  $counter->{sql} = [];
  return $r->{execute}->($q, undef, $r->{context}, {});
}
sub sqls { map { $_->[0] } @{ $counter->{sql} } }

# (1) partial key
{
  my $res = gql('{ bookTag(book_id: 1) { book_id tag_id note } }');
  like($res->{errors}[0]{message} // '', qr/\btag_id\b/,
    'partial key: the error names the missing column');
  unlike($res->{errors}[0]{message} // '', qr/\bbook_id\b/,
    '... and only the missing one');
  is(scalar(sqls()), 0, '... and no SQL ran');
  ok(!defined $res->{data}{bookTag}, '... and no row is answered');

  $res = gql('{ bookTag(book_id: 1, tag_id: 11) { note } }');
  is($res->{data}{bookTag}{note}, 'n2', 'full key still finds the row');
  is(scalar(sqls()), 1, '... with one query');
}

# (2) keyless source
{
  my $res = gql('{ allLogs { nodes { msg author { name } } } }');
  ok(!$res->{errors}, 'keyless source with relationship: no errors')
    or diag explain $res->{errors};
  is_deeply([ map { $_->{author} } @{ $res->{data}{allLogs}{nodes} } ],
    [ undef, undef ], 'relationship field of a keyless source is null');
  is(scalar(grep { /FROM\W+logs/i } sqls()), 1,
    '... and logs is queried once only');
  is(scalar(grep { /FROM\W+authors/i } sqls()), 0, '... authors not at all');
}

# (3) wide integers, exact decimals
{
  my $sf = $r->{schema}->query->fields->{item}{args}{id}{type}->name;
  is($sf, 'String', 'bigint column is a String argument');

  my $res = gql('{ item(id: "3000000000") { id price } }');
  ok(!$res->{errors}, 'lookup by id 3000000000') or diag explain $res->{errors};
  is($res->{data}{item}{id}, '3000000000', '... output keeps the value');

  $res = gql('{ allItems(filter: { id: { eq: "3000000000" } }) { total nodes { id } } }');
  is($res->{data}{allItems}{total}, 1, 'filter on the bigint column');

  $res = gql('mutation { createItem(id: "4000000000", price: "12345678901234.56") { id } }');
  ok(!$res->{errors}, 'create with bigint id and numeric price')
    or diag explain $res->{errors};
  is($res->{data}{createItem}{id}, '4000000000', '... bigint id in the output');
  my ($insert) = grep { $_->[0] =~ /INSERT/ } @{ $counter->{sql} };
  # the trace quotes each bind value
  my @bound = @{$insert}[1 .. $#$insert];
  ok((grep { defined && $_ eq q{'12345678901234.56'} } @bound),
    'the numeric value is bound unchanged');

  $res = gql('mutation { updateItem(id: "4000000000", price: "0.10") { id } }');
  ok(!$res->{errors}, 'update by bigint id') or diag explain $res->{errors};
  $res = gql('mutation { deleteItem(id: "3000000000") }');
  is($res->{data}{deleteItem}, 1, 'delete by bigint id');
}

done_testing;
