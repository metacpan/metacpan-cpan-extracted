use Test::More tests => 4;
use Cache::Memcached::Mock;

my $c = Cache::Memcached::Mock->new();
ok($c, 'Got an object');

is($c->get('something'), undef, 'get() before key exists');
ok($c->set('something','xyz'), 'set() stores the key');
is($c->get('something'), 'xyz', 'get() once the key exists');

