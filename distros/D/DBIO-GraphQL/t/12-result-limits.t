use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use DBIO::GraphQL;
use My::Test qw(deploy_schema);

# WHY: a client chooses how much a query asks for. A plural query without
# page or cursor, a huge take/first/skip, an unbounded in-list and a COUNT
# nobody selected each cost the database and the process in proportion to
# the table, not to what the client needs (karr k16). The rule under test:
# every result set has an upper bound the caller of to_graphql sets --
# default_rows when the client gives no page or cursor (plural queries and
# has_many fields), max_rows for take/first/skip, max_in for in-lists --
# an excess is an error before any SQL, never a silent cut, and COUNT runs
# only when total is selected.

{
  package RL::Result::Author;
  use DBIO;
  __PACKAGE__->table('authors');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many(books => 'RL::Result::Book', 'author_id');
}
{
  package RL::Result::Book;
  use DBIO;
  __PACKAGE__->table('books');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    author_id => { data_type => 'integer', is_nullable => 0 },
    title     => { data_type => 'varchar', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(author => 'RL::Result::Author', 'author_id');
}
{
  package RL::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class(Author => 'RL::Result::Author');
  __PACKAGE__->register_class(Book   => 'RL::Result::Book');
}
{
  package RL::Counter;
  use base 'DBIO::Storage::Statistics';
  sub query_start { my $s = shift; push @{ $s->{sql} }, [ @_ ] }
  sub query_end   { }
}

my $counter = RL::Counter->new;
$counter->{sql} = [];

sub fresh {
  my ($rows, %opts) = @_;
  my $db = RL::Schema->connect('dbi:SQLite:dbname=:memory:');
  deploy_schema($db);
  $db->resultset('Author')->create({ id => 1, name => 'a' });
  $db->resultset('Book')->create({ id => $_, author_id => 1, title => "t$_" })
    for 1 .. $rows;
  my $r = DBIO::GraphQL->to_graphql($db, %opts);
  $db->storage->debugobj($counter);
  $db->storage->debug(1);
  return ($db, $r);
}

sub gql {
  my ($r, $q) = @_;
  $counter->{sql} = [];
  return $r->{execute}->($q, undef, $r->{context}, {});
}

sub sqls    { map { $_->[0] } @{ $counter->{sql} } }
sub n_count { scalar grep { /COUNT\(/i } sqls() }
sub n_sql   { scalar @{ $counter->{sql} } }

sub error_like {
  my ($res, $re, $name) = @_;
  my $msg = join "\n", map { $_->{message} // "$_" } @{ $res->{errors} || [] };
  like($msg, $re, $name);
}

# --- default_rows: no page, no cursor ---------------------------------------

{
  my ($db, $r) = fresh(105);
  my $res = gql($r, '{ allBooks { hasNextPage nodes { id } } }');
  ok(!$res->{errors}, 'plural query without page or cursor runs');
  is(scalar @{ $res->{data}{allBooks}{nodes} }, 100,
    'the default is 100 rows, not the whole table');
  ok($res->{data}{allBooks}{hasNextPage}, '... and hasNextPage says rows remain');
  ok((grep { /LIMIT/ } sqls()), '... because the SELECT carries a LIMIT');
}
{
  my ($db, $r) = fresh(5, default_rows => 3);
  my $res = gql($r, '{ allBooks { hasNextPage nodes { id } } }');
  is_deeply([ map { $_->{id} } @{ $res->{data}{allBooks}{nodes} } ], [1, 2, 3],
    'default_rows sets the row count, in primary-key order');
  ok($res->{data}{allBooks}{hasNextPage}, '... hasNextPage true');

  $res = gql($r, '{ allBooks(page: { take: 4 }) { nodes { id } } }');
  is(scalar @{ $res->{data}{allBooks}{nodes} }, 4,
    'an explicit page is not bound by default_rows');
}
{
  my ($db, $r) = fresh(3, default_rows => 3);
  my $res = gql($r, '{ allBooks { hasNextPage nodes { id } } }');
  ok(!$res->{data}{allBooks}{hasNextPage}, 'exactly default_rows rows: no next page');
}

# --- default_rows: has_many fields -------------------------------------------

{
  my ($db, $r) = fresh(5, default_rows => 2);
  my $res = gql($r, '{ author(id: 1) { books { id } } }');
  is(scalar @{ $res->{data}{author}{books} }, 2,
    'a has_many field returns at most default_rows related rows');
  ok((grep { /LIMIT/ } sqls()), '... the related SELECT carries a LIMIT');
}

# --- max_rows ---------------------------------------------------------------

{
  my ($db, $r) = fresh(5, max_rows => 10, default_rows => 10);
  for my $case (
    [ 'take above max_rows', '{ allBooks(page: { take: 11 }) { nodes { id } } }' ],
    [ 'first above max_rows', '{ allBooks(cursor: { first: 11 }) { nodes { id } } }' ],
    [ 'skip above max_rows', '{ allBooks(page: { skip: 11, take: 1 }) { nodes { id } } }' ],
    [ 'take 2147483647', '{ allBooks(page: { take: 2147483647 }) { nodes { id } } }' ],
  ) {
    my $res = gql($r, $case->[1]);
    error_like($res, qr/max_rows/, "$case->[0] is an error naming max_rows");
    is(n_sql(), 0, "... and runs no SQL");
  }
  my $res = gql($r, '{ allBooks(page: { take: 10, skip: 10 }) { nodes { id } } }');
  ok(!$res->{errors}, 'take and skip equal to max_rows are accepted');
  $res = gql($r, '{ allBooks(cursor: { first: 10 }) { nodes { id } } }');
  ok(!$res->{errors}, 'first equal to max_rows is accepted');
}
{
  my ($db, $r) = fresh(2);
  my $res = gql($r, '{ allBooks(page: { take: 1001 }) { nodes { id } } }');
  error_like($res, qr/max_rows/, 'max_rows defaults to 1000');
  $res = gql($r, '{ allBooks(page: { take: 1000 }) { nodes { id } } }');
  ok(!$res->{errors}, '... and 1000 is accepted');
}

# --- max_in ------------------------------------------------------------------

{
  my ($db, $r) = fresh(5, max_in => 3);
  my $res = gql($r, '{ allBooks(filter: { id: { in: [1,2,3,4] } }) { nodes { id } } }');
  error_like($res, qr/max_in/, 'an in-list above max_in is an error naming max_in');
  is(n_sql(), 0, '... and runs no SQL');

  $res = gql($r, '{ allBooks(filter: { AND: [ { OR: [ { title: { in: ["a","b","c","d"] } } ] } ] }) { nodes { id } } }');
  error_like($res, qr/max_in/, '... also nested in AND/OR');
  is(n_sql(), 0, '... no SQL either');

  $res = gql($r, '{ allBooks(filter: { id: { in: [1,2,3] } }) { nodes { id } } }');
  ok(!$res->{errors}, 'an in-list of exactly max_in is accepted');
  is(scalar @{ $res->{data}{allBooks}{nodes} }, 3, '... and filters');
}
{
  my ($db, $r) = fresh(1);
  my $list = join ',', 1 .. 501;
  my $res = gql($r, "{ allBooks(filter: { id: { in: [$list] } }) { nodes { id } } }");
  error_like($res, qr/max_in/, 'max_in defaults to 500');
}

# --- COUNT only when total is selected -----------------------------------------

{
  my ($db, $r) = fresh(3);
  gql($r, '{ allBooks { nodes { id } } }');
  is(n_count(), 0, 'total not selected: no COUNT query');

  my $res = gql($r, '{ allBooks { total nodes { id } } }');
  is(n_count(), 1, 'total selected: one COUNT query');
  is($res->{data}{allBooks}{total}, 3, '... and the right total');

  $res = gql($r, '{ allBooks { n: total } }');
  is(n_count(), 1, 'total selected under an alias: COUNT');
  is($res->{data}{allBooks}{n}, 3, '... and the right total');

  $res = gql($r, 'query { allBooks { ...C } } fragment C on BookConnection { total }');
  is(n_count(), 1, 'total selected in a fragment: COUNT');
  is($res->{data}{allBooks}{total}, 3, '... and the right total');

  $res = gql($r, 'query { allBooks { ... on BookConnection { total } } }');
  is(n_count(), 1, 'total selected in an inline fragment: COUNT');

  gql($r, '{ allBooks { hasNextPage nextCursor } }');
  is(n_count(), 0, 'hasNextPage and nextCursor alone need no COUNT');
}

# --- authorize and the count --------------------------------------------------

{
  my @calls;
  my ($db, $r) = fresh(3, authorize => sub { push @calls, $_[0]; { id => { '>' => 1 } } });
  my $res = gql($r, '{ allBooks { total nodes { id } } }');
  is($res->{data}{allBooks}{total}, 2, 'the restriction still narrows the total');
  is_deeply(\@calls, ['list'], '... with the one list authorization');
  @calls = ();
  gql($r, '{ allBooks { nodes { id } } }');
  is_deeply(\@calls, ['list'], 'without total the list authorization still runs once');
}
{
  my ($db, $r) = fresh(3, authorize => sub { 0 });
  my $res = gql($r, '{ allBooks { nodes { id } } }');
  error_like($res, qr/not authorized/, 'a refusal stays a refusal');
  is(n_sql(), 0, '... without SQL');
}

# --- the options themselves -----------------------------------------------------

for my $opt (qw(default_rows max_rows max_in)) {
  for my $bad (0, -1, 'x', 1.5) {
    my $db = RL::Schema->connect('dbi:SQLite:dbname=:memory:');
    eval { DBIO::GraphQL->to_graphql($db, $opt => $bad) };
    like($@, qr/\Q$opt\E/, "$opt => $bad dies naming the option");
  }
}

{
  my $db = RL::Schema->connect('dbi:SQLite:dbname=:memory:');
  eval { DBIO::GraphQL->to_graphql($db, default_rows => 20, max_rows => 10) };
  like($@, qr/default_rows.*20.*max_rows.*10/s,
    'default_rows above max_rows dies naming both values');
  eval { DBIO::GraphQL->to_graphql($db, default_rows => 2000) };
  like($@, qr/default_rows.*2000.*max_rows.*1000/s,
    '... also against the default max_rows');
  my $ok = eval { DBIO::GraphQL->to_graphql($db, default_rows => 10, max_rows => 10) };
  ok($ok, 'default_rows equal to max_rows is accepted') or diag $@;
}

done_testing;
