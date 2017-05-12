use Test::More tests => 6;
use Cache::Memcached::Mock;

my $c = Cache::Memcached::Mock->new();

ok(
    $c->set('key1', 'original_value'),
    'Prepare an already existing key1'
);

ok(
    $c->replace('key1', 'another_value'),
    'Replace should succeed only if a key already exists'
);

is(
    $c->get('key1') => 'another_value',
    'Value we get should be the replaced one',
);

ok($c->delete('key1'));

ok(
    ! $c->replace('key1', 'a_new_value'),
    q(Replace fails if the key doesn't exist),
);

is(
    $c->get('key1') => undef,
    'Value is undef, since we deleted it, and replace() should have failed',
);

