use Test::More tests => 6;
use Cache::Memcached::Mock;

my $c = Cache::Memcached::Mock->new();

ok(
    $c->set('key1', 'original_value'),
    'Prepare an already existing key1'
);

ok(
    ! $c->add('key1', 'another_value'),
    'Add should fail if a key already exists'
);

is(
    $c->get('key1') => 'original_value',
    'Value we get should be the original one we set at start time',
);

ok($c->delete('key1'));

ok(
    $c->add('key1', 'a_new_value'),
    'This time add should go through',
);

is(
    $c->get('key1') => 'a_new_value',
    'Value we get should be the new one since add() succeeded',
);

