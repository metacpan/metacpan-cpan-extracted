use lib 't';
use Test::Etcdkv;
use Test::More tests => 9;
use AnyEvent::KVStore;
use Data::Dumper;

my $guard = Test::Etcdkv->guard;
my $config = Test::Etcdkv->config;
ok(my $store = AnyEvent::KVStore->new(module => 'etcd', config => $config), 'Initiated the store');
ok((not $store->exists('/test/foo')), '/test/foo does not exist yet');
ok($store->write('/test/foo', 'bar'), 'Wrote bar to /test/foo');
ok($store->exists('/test/foo'), 'test/foo now exists');
is($store->read('/test/foo'), 'bar', 'got bar back from /test/foo');
ok($store->write('/test/fo2', 'bar'), 'Wrote bar to /test/fo2');
is_deeply([sort { $a cmp $b } $store->list('/test/fo')], ['/test/fo2', '/test/foo'], 'got keys for prefix /test/fo') || diag(Dumper($store->list('/test/fo'))) ;
is_deeply([$store->list('/test/foo')], ['/test/foo'], 'got keys for prefix /test/foo') || diag(Dumper($store->list('/test/foo'))) ;
is_deeply([$store->list('/test/bar')], [], 'Got empty list for /test/bar keys');
undef $guard;

