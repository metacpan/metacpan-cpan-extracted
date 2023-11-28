use lib 't';
use Test::Etcdkv;
use Test::More tests => 10;
use AnyEvent::KVStore;
use Data::Dumper;
use AnyEvent;

my $cb = sub { my ($k, $v) = @_; ok(1, "Got $k: $v"); };
my $cv = AnyEvent->condvar;

my $guard = Test::Etcdkv->guard;
my $config = Test::Etcdkv->config;

ok(my $store = AnyEvent::KVStore->new(module => 'etcd', config => $config), 'Initiated the store');

$store->watch('/test/f', $cb);
$store->watch('/test/end', sub { $cv->send } );


ok($store->write('/test/foo', 'bar'), 'Wrote a key triggering watch'); # 2 tests
ok($store->write('/test/bar', 'baz'), 'Wrote a key not triggering watch'); # 1 test
ok($store->write('/test/fo2', 'foo'), 'Wrote another key triggering a watch'); # 2 tests

ok($store->write('/test/foo', 'bar2'), 'Rewrote a key triggering watch'); # 2 tests

ok($store->write('/test/foo', 'done'), 'terminating tests'); #1 test

undef $guard;
