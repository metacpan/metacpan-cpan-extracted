use Test::More tests => 12;
use AnyEvent::KVStore;
use strict;
use warnings;

ok(my $store = AnyEvent::KVStore->new(module => 'hash', config => {}), 'New store object');


$store->watch('f', sub { my ($k, $v) = @_; ok(1, "Got watch for $k: $v") });

# tests start here
ok( (not $store->exists('foo')), "Foo does not exist yet");
ok($store->write('foo', 'bar'), 'Wrote bar to foo'); # 2 tests
ok($store->exists('foo'), 'Foo now exists');
is($store->read('foo'), 'bar', 'Got bar back');

ok($store->write('bar', 'baz'), "Wrote bar to baz"); #1 test
is($store->read('bar'), 'baz', 'Got baz back');

ok($store->write('far', 'away'), 'Wrote away to far'); # 2 tests
is($store->read('far'), 'away', 'Got away back');

is_deeply([sort { $a cmp $b } $store->list('')], ['bar', 'far', 'foo'], 'Got correct list');

