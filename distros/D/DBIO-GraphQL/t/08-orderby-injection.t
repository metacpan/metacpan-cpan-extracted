use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use My::Schema;
use My::Test qw(deploy_schema);
use DBIO::GraphQL;
use GraphQL::Execution qw(execute);

# Regression test for CWE-89 (CPANSec disclosure, ticket #2):
# orderBy.field is a free client-supplied string. Under default DBIO storage,
# identifiers are emitted unquoted into ORDER BY, so an unvalidated field is a
# SQL injection point. WHY this matters: only real columns of the source may
# ever reach the ORDER BY clause. Anything else MUST be rejected before any
# SQL runs - the query must error out and leak zero rows.

my $db = My::Schema->connect('dbi:SQLite:dbname=:memory:');
deploy_schema($db);

$db->resultset('Author')->create({ id => 1, name => 'Author One', email => 'one@example.com' });

for my $i (1..5) {
  $db->resultset('Book')->create({
    id        => $i,
    title     => "Book $i",
    author_id => 1,
    price     => $i * 1.5,
  });
}

my $r = DBIO::GraphQL->to_graphql($db);
my ($schema, $ctx) = @{$r}{qw(schema context)};

sub gql {
  my ($q, $v) = @_;
  return execute($schema, $q, undef, $ctx, $v // {});
}

# 1. A valid orderBy.field (a real column) still works - guards against
#    over-blocking legitimate ordering.
{
  my $res = gql('{ allBooks(orderBy: { field: "title", direction: ASC }) {
    nodes { id title }
  } }');

  ok(!$res->{errors}, 'valid order column "title": no errors')
    or diag explain $res->{errors};
  my @titles = map { $_->{title} } @{ $res->{data}{allBooks}{nodes} };
  is(scalar @titles, 5, 'all 5 rows returned for valid order');
  is_deeply(\@titles, [ sort @titles ], 'rows are ordered by title ASC');
}

# 2. Injection / non-column payloads in orderBy.field are REJECTED: the query
#    errors and no rows leak (data is null), so the malicious SQL never runs.
my @payloads = (
  'id) FROM books; --',                       # classic break-out injection
  '(SELECT password FROM users LIMIT 1)',     # subquery exfiltration attempt
  'no_such_col',                              # plain unknown column
);

for my $field (@payloads) {
  my $res = gql(
    'query($f: String!) { allBooks(orderBy: { field: $f, direction: ASC }) {
      total nodes { id }
    } }',
    { f => $field }
  );

  ok($res->{errors} && @{ $res->{errors} },
    "orderBy injection rejected: errors present for '$field'")
    or diag explain $res;
  ok(!defined $res->{data}{allBooks},
    "orderBy injection leaks no rows: allBooks is null for '$field'");
}

done_testing;
