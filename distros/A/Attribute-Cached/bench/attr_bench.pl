#!/usr/bin/perl
use strict; use warnings;
use Data::Dumper;

use Attribute::Cached;
use constant CACHETIME => 20;

use Cache::MemoryCache;
my %caches;

sub getCache {
    my (undef, undef, undef, $method) = caller(2);
    return $caches{$method} ||= do {
         warn "Getting cache $method";
         Cache::MemoryCache->new({namespace=>$method});
        };
}
sub getCacheKey {
    return join ',' => @_;
}
sub customCacheKey {
    return join ':' => @_;
}
sub getCacheTime {
    return int rand(20);
}

sub manualcache {
    my $cache = getCache('main', 'manualcache');
    my $key = join ':', @_;
    my $result;
    if ($result = $cache->get($key)) {
        return $result;
    }
    $result = expensive_operation();

    $cache->set($key, $result, CACHETIME);
}

sub expensive_operation {
    # select (undef, undef, undef, 0.00001);
    return "I CAN HAZ CHEEZBURGER?";
}

sub cached    :Cached(key=>\&customCacheKey,time=>CACHETIME) {
    return expensive_operation();
}
sub notcached {
    return expensive_operation();
}
{
no warnings 'once';
*cached2 = Attribute::Cached::encache(
    __PACKAGE__, 'notcached', \&notcached,
    key=>\&customCacheKey, 
    time=>CACHETIME);
}

use Benchmark;
timethese(1_000_000 => {
    cached    => sub { my $x = cached() },
    notcached => sub { my $x = notcached() },
    cached2   => sub { my $x = cached2() },
    manual    => sub { my $x = manualcache() },
    }
);
