#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Benchmark qw(:all);

use Cache::Memcached::Fast;
use Cache::Redis;
use File::Spec;
use File::Temp qw/tempdir/;
use Test::Memcached;
use Test::RedisServer;

my $tempdir = tempdir(CLEANUP => 1);
my $mem_sock = File::Spec->catfile($tempdir, 'mem.sock');
my $memd  = Test::Memcached->new(
    options => {
        unix_socket => $mem_sock,
    },
);
$memd->start;
my $memd_client = Cache::Memcached::Fast->new({
    servers => [$mem_sock],
});
my $redis = Test::RedisServer->new;
my $redis_client = Cache::Redis->new(
    $redis->connect_info,
    nowait => 1,
);
my $redis_client_fast = Cache::Redis->new(
    $redis->connect_info,
    redis_class => 'Redis::Fast',
    nowait => 1,
);

my $results = timethese(0, {
    'memd'  => sub {
        $memd_client->set('hoge', 'fuga');
        $memd_client->get('hoge');
        $memd_client->remove('hoge');
    },
    'redis' => sub {
        $redis_client->set('hoge', 'fuga');
        $redis_client->get('hoge');
        $redis_client->remove('hoge');
    },
    'redis_fast' => sub {
        $redis_client_fast->set('hoge', 'fuga');
        $redis_client_fast->get('hoge');
        $redis_client_fast->remove('hoge');
    },
});
cmpthese( $results ) ;
