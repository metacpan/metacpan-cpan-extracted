use Test::More tests => 5;
use AnyEvent::KVStore::Etcd;

is(AnyEvent::KVStore::Etcd::_add_one('a'), 'b', 'incremented a to b');
is(AnyEvent::KVStore::Etcd::_add_one('aa'), 'ab', 'incremented aa to ab');
is(AnyEvent::KVStore::Etcd::_add_one("a\xff"), 'b', 'incremented a\xff to b');
is(AnyEvent::KVStore::Etcd::_add_one(''), "\x00", 'returned a null on empty input');
is(AnyEvent::KVStore::Etcd::_add_one("\xff\xff\xff"), "\x00", 'returned null on \xff input');
