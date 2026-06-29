use strict;
use warnings;

use Test::More;
use Data::NestedKey;

# Simulate a DescribeRepositories ECR response
my $ecr = {
  repositories => [
    {
      repositoryName => 'my-app',
      repositoryUri  => '123456789.dkr.ecr.us-east-1.amazonaws.com/my-app',
      imageTagMutability => 'MUTABLE',
    },
    {
      repositoryName => 'other-app',
      repositoryUri  => '123456789.dkr.ecr.us-east-1.amazonaws.com/other-app',
      imageTagMutability => 'IMMUTABLE',
    },
  ],
  nextToken => undef,
};

my $nk = Data::NestedKey->new($ecr);

# --- basic subscript get ---
is(
  $nk->get('repositories[0].repositoryUri'),
  '123456789.dkr.ecr.us-east-1.amazonaws.com/my-app',
  'get: repositories[0].repositoryUri'
);

is(
  $nk->get('repositories[1].repositoryName'),
  'other-app',
  'get: repositories[1].repositoryName'
);

# --- negative index ---
is(
  $nk->get('repositories[-1].repositoryName'),
  'other-app',
  'get: repositories[-1].repositoryName (last element)'
);

is(
  $nk->get('repositories[-1].imageTagMutability'),
  'IMMUTABLE',
  'get: repositories[-1].imageTagMutability'
);

# --- out-of-range returns undef ---
is(
  $nk->get('repositories[99].repositoryUri'),
  undef,
  'get: out-of-range index returns undef'
);

# --- missing key returns undef ---
is(
  $nk->get('repositories[0].noSuchKey'),
  undef,
  'get: missing key under subscript returns undef'
);

# --- exists_key with subscripts ---
ok(  $nk->exists_key('repositories[0].repositoryUri'),  'exists_key: [0] present' );
ok(  $nk->exists_key('repositories[1].repositoryName'), 'exists_key: [1] present' );
ok( !$nk->exists_key('repositories[99].repositoryUri'), 'exists_key: out-of-range is false' );
ok( !$nk->exists_key('repositories[0].noSuchKey'),      'exists_key: missing leaf is false' );

# --- multi-value get in list context ---
my @uris = $nk->get('repositories[0].repositoryUri', 'repositories[1].repositoryUri');
is_deeply(
  \@uris,
  [
    '123456789.dkr.ecr.us-east-1.amazonaws.com/my-app',
    '123456789.dkr.ecr.us-east-1.amazonaws.com/other-app',
  ],
  'get: list context returns multiple subscript values'
);

# --- array-at-leaf (no further key after subscript) ---
my $nk2 = Data::NestedKey->new({ tags => ['alpha', 'beta', 'gamma'] });
is( $nk2->get('tags[0]'),  'alpha', 'get: array-at-leaf [0]' );
is( $nk2->get('tags[2]'),  'gamma', 'get: array-at-leaf [2]' );
is( $nk2->get('tags[-1]'), 'gamma', 'get: array-at-leaf [-1]' );

# --- delete with subscript (splice, not undef) ---
my $nk3 = Data::NestedKey->new({ items => [qw(a b c d)] });
$nk3->delete('items[1]');
is_deeply( $nk3->get('items'), [qw(a c d)], 'delete: splice removes element, array shrinks' );

$nk3->delete('items[-1]');
is_deeply( $nk3->get('items'), [qw(a c)], 'delete: splice with negative index' );

# --- set still rejects subscript paths ---
eval { $nk->set('repositories[0].repositoryUri' => 'new-value') };
like( $@, qr/not supported/, 'set: croaks on subscript path' );

# --- plain paths still work unchanged ---
my $nk4 = Data::NestedKey->new( 'foo.bar.baz' => 42 );
is( $nk4->get('foo.bar.baz'), 42, 'plain path: get still works' );
ok( $nk4->exists_key('foo.bar.baz'), 'plain path: exists_key still works' );
$nk4->delete('foo.bar.baz');
ok( !$nk4->exists_key('foo.bar.baz'), 'plain path: delete still works' );

done_testing();
