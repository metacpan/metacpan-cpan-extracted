use strict;
use lib 't/lib';
use libmemcached_test;
use Test::More;

eval "use Cache::Memcached";
if ($@) {
    plan( skip_all => "Cache::Memcached not available" );
}

my $libmemcached = libmemcached_test_create({
    compress_threshold => 1_000
} );

plan (tests => 2);
my $memcached = Cache::Memcached->new({
    servers => [ libmemcached_test_servers() ],
    compress_threshold => 1_000
});

{
    my $data = "1" x 10_000;

    eval {
        $memcached->set("foo", $data);
        is( $libmemcached->get("foo"), $data, "set via Cache::Memcached, retrieve via Cache::Memcached::libmemcached");
    };

    eval {
        $libmemcached->set("foo", $data);
        is( $memcached->get("foo"), $data, "set via Cache::Memcached::libmemcached, retrieve via Cache::Memcached");
    };
}

