use Test::More tests => 4;
use Cache::Memcached::Mock;

my $c = Cache::Memcached::Mock->new();
ok($c, 'Got an object');

ok($c->set('phantom_key', 42, 2), 'set a key with expire time');
is($c->get('phantom_key') => 42, 'get it immediately after, should be there');

diag('Sleeping to allow the key to expire');

sleep 3;

is($c->get('phantom_key'), undef, 'phantom_key should be expired');

