use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use DBIO::GraphQL;
use My::Test qw(deploy_schema);
use GraphQL::Execution ();

# WHY: the relationship fields point at each other (author -> books -> author),
# so a document can ask for an unbounded amount of work: a fragment that
# spreads itself through a relationship field, a chain of any depth, or the
# same field under hundreds of aliases (karr k15). The rule under test: the
# document is checked before the first SQL -- fragment cycles are refused,
# the selection depth after unfolding is bounded by max_depth, and the cost
# (every field 1, rows-yielding fields multiplied by their page size,
# variables resolved) by max_cost. The entry point is the execute code
# reference of the to_graphql result; the relationship resolvers additionally
# bound the depth at run time for a caller that executes the schema itself.

{
  package QL::Result::Author;
  use DBIO;
  __PACKAGE__->table('authors');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many(books => 'QL::Result::Book', 'author_id');
}
{
  package QL::Result::Book;
  use DBIO;
  __PACKAGE__->table('books');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    author_id => { data_type => 'integer', is_nullable => 0 },
    title     => { data_type => 'varchar', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(author => 'QL::Result::Author', 'author_id');
}
{
  package QL::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class(Author => 'QL::Result::Author');
  __PACKAGE__->register_class(Book   => 'QL::Result::Book');
}
{
  package QL::Counter;
  use base 'DBIO::Storage::Statistics';
  sub query_start { my $s = shift; push @{ $s->{sql} }, [ @_ ] }
  sub query_end   { }
}

my $counter = QL::Counter->new;
$counter->{sql} = [];

sub fresh {
  my (%opts) = @_;
  my $db = QL::Schema->connect('dbi:SQLite:dbname=:memory:');
  deploy_schema($db);
  $db->resultset('Author')->create({ id => $_, name => "a$_" }) for 1 .. 2;
  $db->resultset('Book')->create({ id => $_, author_id => 1, title => "t$_" })
    for 1 .. 3;
  my $r = DBIO::GraphQL->to_graphql($db, %opts);
  $db->storage->debugobj($counter);
  $db->storage->debug(1);
  return ($db, $r);
}

sub gql {
  my ($r, $q, $vars, $op) = @_;
  $counter->{sql} = [];
  return $r->{execute}->($q, undef, $r->{context}, $vars // {}, $op);
}

sub raw {
  my ($r, $q, $vars) = @_;
  $counter->{sql} = [];
  return GraphQL::Execution::execute($r->{schema}, $q, undef, $r->{context}, $vars // {});
}

sub n_sql { scalar @{ $counter->{sql} } }

sub error_like {
  my ($res, $re, $name) = @_;
  my $msg = join "\n", map { $_->{message} // "$_" } @{ $res->{errors} || [] };
  like($msg, $re, $name);
}

# n levels of author { books { ... } } below a root author
sub chain {
  my ($levels) = @_;
  my $q = 'name';
  $q = ($_ % 2 ? "books { $q }" : "author { $q }") for reverse 1 .. $levels;
  return "{ author(id: 1) { $q } }";
}

# --- the entry point ------------------------------------------------------------

{
  my ($db, $r) = fresh();
  is(ref $r->{execute}, 'CODE', 'to_graphql returns an execute code reference');
}

# --- fragment cycles ---------------------------------------------------------------

{
  my ($db, $r) = fresh();
  my $res = gql($r, 'fragment F on Author { name books { author { ...F } } } { author(id: 1) { ...F } }');
  error_like($res, qr/fragment.*cycle|cycle.*fragment/i, 'a fragment that spreads itself is an error');
  is(n_sql(), 0, '... before the first SQL');

  $res = gql($r, 'fragment F on Author { name books { ...G } } fragment G on Book { author { ...F } } { author(id: 1) { ...F } }');
  error_like($res, qr/cycle/i, 'a cycle through two fragments is an error');
  is(n_sql(), 0, '... before the first SQL');

  $res = gql($r, 'fragment F on Author { name ...F } { author(id: 1) { name } }');
  error_like($res, qr/cycle/i, 'a cycle in a fragment the operation never spreads is an error too');
  is(n_sql(), 0, '... before the first SQL');

  $res = gql($r, 'fragment F on Author { name ... on Author { ...F } } { author(id: 1) { ...F } }');
  error_like($res, qr/cycle/i, 'a cycle through an inline fragment is an error');

  $res = gql($r, 'fragment N on Author { name } { a: author(id: 1) { ...N } b: author(id: 2) { ...N } }');
  ok(!$res->{errors}, 'the same fragment spread twice is no cycle') or diag explain $res->{errors};
  is($res->{data}{b}{name}, 'a2', '... and both spreads resolve');
}

# --- depth -----------------------------------------------------------------------------

{
  my ($db, $r) = fresh(default_rows => 1);    # max_depth 10; one row per list keeps the cost low
  my $res = gql($r, chain(8));    # author + 8 levels + name = 10 fields deep
  ok(!$res->{errors}, 'a selection exactly max_depth deep is accepted') or diag explain $res->{errors};
  is($res->{data}{author}{books}[0]{author}{books}[0]{author}{books}[0]{author}{books}[0]{author}{name}, 'a1',
    '... and resolves');

  $res = gql($r, chain(9));
  error_like($res, qr/max_depth/, 'one level deeper is an error naming max_depth');
  is(n_sql(), 0, '... before the first SQL');
}
{
  my ($db, $r) = fresh(max_depth => 3);
  my $res = gql($r, '{ author(id: 1) { books { title } } }');
  ok(!$res->{errors}, 'max_depth => 3: three levels pass');
  $res = gql($r, '{ author(id: 1) { books { author { name } } } }');
  error_like($res, qr/max_depth/, '... four do not');
  is(n_sql(), 0, '... before the first SQL');

  $res = gql($r, 'fragment A on Author { books { ...B } } fragment B on Book { author { name } } { author(id: 1) { ...A } }');
  error_like($res, qr/max_depth/, 'the depth counts after unfolding fragments');
  is(n_sql(), 0, '... before the first SQL');

  $res = gql($r, '{ author(id: 1) { ... on Author { books { ... on Book { author { name } } } } } }');
  error_like($res, qr/max_depth/, '... and through inline fragments');

  $res = gql($r, 'query A { author(id: 1) { name } } query B { author(id: 1) { books { author { name } } } }', {}, 'A');
  ok(!$res->{errors}, 'only the selected operation is measured') or diag explain $res->{errors};
}

# --- depth at run time, for a caller that executes the schema itself -------------------------

{
  my ($db, $r) = fresh(max_depth => 3);
  my $res = raw($r, '{ author(id: 1) { books { author { books { title } } } } }');
  error_like($res, qr/max_depth/, 'executing the schema directly: the relationship resolver bounds the depth');
  ok(n_sql() < 20, '... the work stays small (' . n_sql() . ' queries)');
}
{
  my ($db, $r) = fresh(max_depth => 10, default_rows => 1);
  my $res = raw($r, 'fragment F on Author { name books { author { ...F } } } { author(id: 1) { ...F } }');
  error_like($res, qr/max_depth/, 'a cyclic fragment executed directly ends at max_depth');
  ok(n_sql() < 100, '... instead of running as long as there is data (' . n_sql() . ' queries)');
}

# --- cost ---------------------------------------------------------------------------------------

{
  my ($db, $r) = fresh(max_cost => 50);
  my $res = gql($r, '{ author(id: 1) { id name } }');
  ok(!$res->{errors}, 'a cheap query is accepted');

  my $aliases = join ' ', map { "q$_: author(id: 1) { id }" } 1 .. 30;
  $res = gql($r, "{ $aliases }");
  error_like($res, qr/max_cost/, 'aliases count one by one: 60 fields over a budget of 50');
  is(n_sql(), 0, '... before the first SQL');

  $aliases = join ' ', map { "q$_: author(id: 1) { id }" } 1 .. 20;
  $res = gql($r, "{ $aliases }");
  ok(!$res->{errors}, '... 40 fields fit');
}
{
  my ($db, $r) = fresh();    # max_cost 10000
  my $q = '{ ' . join(' ', map { "q$_: allBooks { total nodes { id } }" } 1 .. 40) . ' }';
  my $res = gql($r, $q);
  error_like($res, qr/max_cost/, '40 aliases of a plural query (301 each) are over the default budget');
  is(n_sql(), 0, '... before the first SQL');
}
{
  my ($db, $r) = fresh();
  my $spread = join ' ', ('...N') x 11000;
  my $res = gql($r, "fragment N on Author { id } { author(id: 1) { $spread } }");
  error_like($res, qr/max_cost/, 'unfolding a repeated acyclic fragment counts: 11000 spreads');
  is(n_sql(), 0, '... before the first SQL');
}

# --- fan-out: page size multiplies the cost of what is below -------------------------------------

{
  my ($db, $r) = fresh(max_cost => 100);
  # allBooks 1 + take * (total 1 + nodes 1 + id 1)
  my $res = gql($r, '{ allBooks(page: { take: 30 }) { total nodes { id } } }');
  ok(!$res->{errors}, 'take 30 below a budget of 100: 91') or diag explain $res->{errors};
  $res = gql($r, '{ allBooks(page: { take: 40 }) { total nodes { id } } }');
  error_like($res, qr/max_cost/, 'take 40: 121, over the budget');
  is(n_sql(), 0, '... before the first SQL');

  $res = gql($r, '{ allBooks(cursor: { first: 40 }) { total nodes { id } } }');
  error_like($res, qr/max_cost/, 'cursor first multiplies as well');

  $res = gql($r, '{ allBooks(page: { take: 1 }) { total nodes { id } } }');
  ok(!$res->{errors}, 'take 1 is cheap');

  # no page, no cursor: default_rows (100) applies
  $res = gql($r, '{ allBooks { nodes { id } } }');
  error_like($res, qr/max_cost/, 'without page or cursor the multiplier is default_rows');
}
{
  my ($db, $r) = fresh(max_cost => 100, default_rows => 10);
  my $res = gql($r, '{ allBooks { total nodes { id } } }');
  ok(!$res->{errors}, 'default_rows 10: 31, accepted') or diag explain $res->{errors};
  $res = gql($r, '{ allBooks(page: { skip: 0 }) { nodes { id } } }');
  ok(!$res->{errors}, 'a page without take counts the 10 the resolver uses: 21') or diag explain $res->{errors};
  $res = gql($r, '{ allBooks(page: { take: 100 }) { nodes { id } } }');
  error_like($res, qr/max_cost/, 'an explicit take beats default_rows');
}

# --- variables in the page size -----------------------------------------------------------------------

{
  my ($db, $r) = fresh(max_cost => 100);
  my $q = 'query($n: Int) { allBooks(page: { take: $n }) { total nodes { id } } }';
  my $res = gql($r, $q, { n => 5 });
  ok(!$res->{errors}, 'a variable take of 5 is cheap') or diag explain $res->{errors};
  $res = gql($r, $q, { n => 500 });
  error_like($res, qr/max_cost/, 'a variable take of 500 is resolved and counted');
  is(n_sql(), 0, '... before the first SQL');

  $res = gql($r, 'query($n: Int = 500) { allBooks(page: { take: $n }) { total nodes { id } } }');
  error_like($res, qr/max_cost/, 'the default of a variable is used when none is given');
  $res = gql($r, 'query($n: Int = 500) { allBooks(page: { take: $n }) { total nodes { id } } }', { n => 2 });
  ok(!$res->{errors}, '... and a given value wins over it');

  $res = gql($r, 'query($c: CursorInput) { allBooks(cursor: $c) { total nodes { id } } }', { c => { first => 500 } });
  error_like($res, qr/max_cost/, 'a whole cursor argument in a variable is resolved');
  $res = gql($r, 'query($f: Int) { allBooks(cursor: { first: $f }) { total nodes { id } } }', { f => 3 });
  ok(!$res->{errors}, 'cursor first from a variable');
}

# --- has_many multiplies by default_rows -----------------------------------------------------------------

{
  my ($db, $r) = fresh(max_cost => 100, default_rows => 10);
  # author 1 + books (1 + 10 * (title 1 + id 1))
  my $res = gql($r, '{ author(id: 1) { books { title id } } }');
  ok(!$res->{errors}, 'a has_many field below a budget: 22') or diag explain $res->{errors};
  $res = gql($r, '{ author(id: 1) { books { title id author { name } } } }');
  ok(!$res->{errors}, 'belongs_to does not multiply: 1 + 1 + 10 * (3 + 1)') or diag explain $res->{errors};
  $res = gql($r, '{ author(id: 1) { books { title id author { books { id } } } } }');
  error_like($res, qr/max_cost/, 'has_many below has_many multiplies twice');
  is(n_sql(), 0, '... before the first SQL');
}

# --- normal queries: unchanged ----------------------------------------------------------------------------------

{
  my ($db, $r) = fresh();
  for my $q (
    '{ author(id: 1) { name books { title } } }',
    '{ allBooks(page: { take: 2 }) { total hasNextPage nodes { id title author { name } } } }',
    '{ allAuthors(page: { take: 5 }) { nodes { name books { title } } } }',
    'query($n: Int) { book(id: 1) { title author { books { id } } } }',
  ) {
    my $got  = gql($r, $q, { n => 1 });
    my $sql  = n_sql();
    my $want = raw($r, $q, { n => 1 });
    is(n_sql(), $sql, "same SQL count as the bare engine ($sql): $q");
    ok(!$got->{errors}, '... no error') or diag explain $got->{errors};
    is_deeply($got, $want, '... same result');
  }
}

# --- introspection switch through execute ----------------------------------------------------------------------------

{
  my ($db, $r) = fresh(introspection => 0);
  my $res = gql($r, '{ __schema { types { name } } }');
  error_like($res, qr/introspection/, 'introspection => 0 holds through execute');
  is(n_sql(), 0, '... without SQL');
  $res = gql($r, '{ author(id: 1) { name } }');
  ok(!$res->{errors}, '... and ordinary queries run');
}
{
  my ($db, $r) = fresh();
  my $res = gql($r, '{ __schema { queryType { name } } }');
  ok(!$res->{errors}, 'introspection stays on by default') or diag explain $res->{errors};
}

# --- a document the parser rejects is the engine's to report -------------------------------------------------------------

{
  my ($db, $r) = fresh();
  my $res = gql($r, '{ author(id: 1 ');
  ok($res->{errors} && @{ $res->{errors} }, 'a syntax error is reported as an error');
  is(n_sql(), 0, '... without SQL');
}

# --- the options themselves ------------------------------------------------------------------------------------------------------

for my $opt (qw(max_depth max_cost)) {
  for my $bad (0, -1, 'x', 1.5) {
    my $db = QL::Schema->connect('dbi:SQLite:dbname=:memory:');
    eval { DBIO::GraphQL->to_graphql($db, $opt => $bad) };
    like($@, qr/\Q$opt\E/, "$opt => $bad dies naming the option");
  }
}

done_testing;
