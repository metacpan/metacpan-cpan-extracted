#!perl

use strict;
use warnings;

use Test::More;

unless ( $ENV{D_P_M_SERVER} )
{
    plan(skip_all => "Environment variable D_P_M_SERVER not set");
}
else
{
    plan(tests => 3);
}

my $cache;
eval
{
    require Cache::Memcached::Fast;
    $cache = Cache::Memcached::Fast->new({
        servers => [ $ENV{D_P_M_SERVER} ]
    });
};

if($@)
{
    require Cache::Memcached;
    $cache = Cache::Memcached->new({
        servers => [ $ENV{D_P_M_SERVER} ]
    });
}

use_ok 'Dancer::Plugin::Memcached';

my $time = time;
my $cache_set = $cache->set('Dancer-Plugin-Memcached:time', $time);
ok $cache_set, 'Stored data into cache';

my $cache_get = $cache->get('Dancer-Plugin-Memcached:time');
is $cache_get, $time, 'Stored value matches';

