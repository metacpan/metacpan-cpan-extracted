use Test::More tests => 3;
use_ok('Cache::Memcached::Mock');
ok(1, 'Loaded');

our $version = Cache::Memcached::Mock->VERSION();
ok(defined $version && $version, "We have a version and it's v$version");
