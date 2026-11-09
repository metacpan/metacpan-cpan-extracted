use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use DBIO::GraphQL;
use My::Test qw(deploy_schema);
use MIME::Base64 qw(encode_base64);

# Edge cases of cursor / offset pagination (karr k12): empty-string and
# "0" keys, keyless sources, bad first/take/skip and malformed cursors.

{
  package CUR::Result::Code;
  use DBIO;
  __PACKAGE__->table('codes');
  __PACKAGE__->add_columns(
    code => { data_type => 'varchar', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('code');
}
{
  package CUR::Result::Pair;
  use DBIO;
  __PACKAGE__->table('pairs');
  __PACKAGE__->add_columns(
    a => { data_type => 'integer', is_nullable => 0 },
    b => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('a', 'b');
}
{
  package CUR::Result::Log;
  use DBIO;
  __PACKAGE__->table('logs');
  __PACKAGE__->add_columns(
    msg => { data_type => 'varchar', is_nullable => 0 },
  );
}
{
  package CUR::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class( Code => 'CUR::Result::Code' );
  __PACKAGE__->register_class( Pair => 'CUR::Result::Pair' );
  __PACKAGE__->register_class( Log  => 'CUR::Result::Log'  );
}

my $db = CUR::Schema->connect('dbi:SQLite:dbname=:memory:');
deploy_schema($db);

$db->resultset('Code')->create({ code => $_ }) for '', '0', 'a', 'b', 'c';
for my $a (1, 2) { for my $b (1, 2) {
  $db->resultset('Pair')->create({ a => $a, b => $b });
} }
$db->storage->dbh->do("INSERT INTO logs (msg) VALUES ('one'), ('two')");

my $r = DBIO::GraphQL->to_graphql($db);
my ($exec, $ctx) = @{$r}{qw(execute context)};

sub gql {
  my ($query, $vars) = @_;
  return $exec->($query, undef, $ctx, $vars // {});
}

sub errors_like {
  my ($res, $re, $name) = @_;
  my $msg = join ' | ', map { $_->{message} } @{ $res->{errors} // [] };
  like($msg, $re, $name);
}

# Walk a whole source with cursor pagination; bounded so a cursor that
# fails to advance fails the test instead of hanging it.
sub walk {
  my ($field, $cols, $first) = @_;
  my (@seen, $after, @errors);
  for (1 .. 12) {
    my $res = gql(
      "query(\$c: String) { $field(cursor: { after: \$c, first: $first }) {
         nextCursor hasNextPage nodes { $cols } } }",
      { c => $after },
    );
    if ($res->{errors}) { push @errors, @{ $res->{errors} }; last }
    my $conn = $res->{data}{$field};
    push @seen, map { join ',', map { $_ // '' } @{$_}{ split ' ', $cols } }
                @{ $conn->{nodes} };
    last unless $conn->{hasNextPage};
    $after = $conn->{nextCursor};
  }
  return (\@seen, \@errors);
}

# 1. A key whose encoded form is the empty string must still advance.
{
  my ($seen, $errs) = walk('allCodes', 'code', 1);
  is_deeply($errs, [], 'walk over empty-string and "0" keys: no errors');
  is_deeply($seen, ['', '0', 'a', 'b', 'c'],
    'cursor walk yields every row exactly once, including key "" and "0"');
}

# 2. after is tested for definedness, not truthiness.
{
  my $res = gql('{ allCodes(cursor: { after: "", first: 10 }) {
    total nodes { code } } }');
  ok(!$res->{errors}, 'after: "" (cursor of the empty key) is accepted')
    or diag explain $res->{errors};
  is_deeply([ map { $_->{code} } @{ $res->{data}{allCodes}{nodes} } ],
    ['0', 'a', 'b', 'c'], 'after: "" seeks past the empty key');

  $res = gql('{ allCodes(cursor: { after: "0", first: 10 }) {
    total nodes { code } } }');
  errors_like($res, qr/invalid cursor/i,
    'after: "0" is rejected as an invalid cursor, not silently ignored');
}

# 3. A source without a primary key cannot be cursor-paginated.
{
  my $res = gql('{ allLogs(cursor: { first: 1 }) { total nextCursor nodes { msg } } }');
  errors_like($res, qr/primary key/i,
    'cursor pagination on a keyless source fails with a clear message');

  $res = gql('{ allLogs { total nodes { msg } } }');
  ok(!$res->{errors}, 'plain query on a keyless source still works');
  is($res->{data}{allLogs}{total}, 2, '... and counts its rows');

  $res = gql('{ allLogs(page: { skip: 0, take: 1 }) { total nodes { msg } } }');
  is(scalar @{ $res->{data}{allLogs}{nodes} }, 1,
    'offset pagination on a keyless source still works');
}

# 4. first / take / skip bounds.
for my $bad (0, -1) {
  my $res = gql("{ allCodes(cursor: { first: $bad }) { total nodes { code } } }");
  errors_like($res, qr/first.*>= 1/i, "cursor first: $bad is rejected");
}
for my $bad (0, -1) {
  my $res = gql("{ allCodes(page: { take: $bad }) { total nodes { code } } }");
  errors_like($res, qr/take.*>= 1/i, "page take: $bad is rejected");
}
{
  my $res = gql('{ allCodes(page: { skip: -1, take: 2 }) { total nodes { code } } }');
  errors_like($res, qr/skip.*>= 0/i, 'page skip: -1 is rejected');

  $res = gql('{ allCodes(page: { skip: 0, take: 2 }) { total nodes { code } } }');
  is(scalar @{ $res->{data}{allCodes}{nodes} }, 2, 'valid page still works');
}

# 5. Malformed cursors are rejected, not decoded leniently.
for my $case (
  [ 'not base64 at all'              => 'not base64!!'       ],
  [ 'valid alphabet, wrong length'   => 'abc'                ],
  [ 'trailing garbage after padding' => 'YQ==x'              ],
  [ 'non-canonical padding'          => 'YQ='                ],
) {
  my ($name, $cursor) = @$case;
  my $res = gql('query($c: String) { allCodes(cursor: { after: $c }) {
    total nodes { code } } }', { c => $cursor });
  errors_like($res, qr/invalid cursor/i, "malformed cursor ($name) is rejected");
}
{
  # Well-formed base64, but for a different key shape (one component for
  # a two-column key, and the reverse).
  my $one = encode_base64('1', '');
  my $res = gql('query($c: String) { allPairs(cursor: { after: $c }) {
    total nodes { a } } }', { c => $one });
  errors_like($res, qr/cursor does not match the primary key/i,
    'cursor with too few components for a composite key is rejected');

  my $two = encode_base64('1:2', '');
  $res = gql('query($c: String) { allCodes(cursor: { after: $c }) {
    total nodes { code } } }', { c => $two });
  errors_like($res, qr/cursor does not match the primary key/i,
    'cursor with too many components for a single-column key is rejected');
}

# 6. _decode_cursor keeps an empty trailing component.
{
  is_deeply([ DBIO::GraphQL::_decode_cursor(DBIO::GraphQL::_encode_cursor('x', '')) ],
    ['x', ''], 'composite cursor round-trips a trailing empty component');
  is_deeply([ DBIO::GraphQL::_decode_cursor(DBIO::GraphQL::_encode_cursor('a:b', '%')) ],
    ['a:b', '%'], 'colons and percent signs still round-trip');
}

done_testing;
