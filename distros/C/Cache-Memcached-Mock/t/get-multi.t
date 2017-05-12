use Test::More tests => 6;
use Cache::Memcached::Mock;

my $c = Cache::Memcached::Mock->new();
ok($c, 'Got an object');

ok($c->set('key1', 'value1'),    'Preparing some keys for get_multi()');
ok($c->set('key2', 'value2', 2), 'Preparing some keys for get_multi()');
ok($c->set('key3', 'value3'),    'Preparing some keys for get_multi()');

my $items = $c->get_multi(qw(key1 key2 key3 key4));

is_deeply(
    $items,
    {key1 => 'value1', key2 => 'value2', key3 => 'value3'},
    'get_multi() works'
);

# Allow key2 to expire
sleep 3;

$items = $c->get_multi(qw(key1 key2 key3 key4));

is_deeply(
    $items,
    {key1 => 'value1', key3 => 'value3'},
    'get_multi() work and respects expired keys'
);

