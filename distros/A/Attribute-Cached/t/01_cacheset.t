#!/usr/bin/perl
use strict; use warnings;
use Data::Dumper;

use Test::More tests => 10;

use Attribute::Cached;
use constant CACHETIME => 20;

use constant VALUE => 'I CAN HAZ CACHE?';

package Cache::MockCache;

sub new {
    my ($class, $config) = @_;
    return bless $config, $class;
}
sub namespace { return $_[0]->{namespace} }
sub get {
    my ($self, $key) = @_;
    if (my $value = $self->{data}{$key}) {
        $self->{gets}{hits}{$key}++;
        return $value;
    } else {
        $self->{gets}{misses}{$key}++;
    }
}
sub set {
    my ($self, $key, $value, $time) = @_;
    $self->{sets}{count}{$key}++;
    $self->{data}{$key} = $value;
    $self->{time}{$key} = $time;
}

package main;

my %caches;

sub getCache {
    my $method = $_[1];
    if (!$method) {
        my $method_name = (caller(2))[3];
        $method_name=~/\((.*?)\)/;
        $method = $1;
    }
    return $caches{$method} ||= do {
         diag "Getting cache $method";
         Cache::MockCache->new({namespace=>$method});
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

sub expensive_operation {
    # select (undef, undef, undef, 0.00001);
    return VALUE;
}

sub cached :Cached(key=>\&customCacheKey,time=>CACHETIME) {
    return expensive_operation();
}
sub basic {
    return expensive_operation();
}
{
no warnings 'once';
*cached2 = Attribute::Cached::encache(
    __PACKAGE__, 'basic', \&basic,
    key=>\&customCacheKey, 
    time=>CACHETIME);
}

my $cached_cache = getCache(undef, 'cached');
my $x;
$x = cached();
is ($x, VALUE);
is_deeply( $cached_cache, {
 'sets' => {
             'count' => { 'main:cached' => 1 }
           },
 'namespace' => 'cached',
 'data' => { 'main:cached' => VALUE, },
 'time' => { 'main:cached' => 20, },
 'gets' => {
             'misses' => { 'main:cached' => 1 }
           }
}, 'cache ok');

$x = cached();
is ($x, VALUE);

$x = cached();
is ($x, VALUE);

is_deeply( $cached_cache, {
 'sets' => {
             'count' => { 'main:cached' => 1 }
           },
 'namespace' => 'cached',
 'data' => { 'main:cached' => VALUE, },
 'time' => { 'main:cached' => 20, },
 'gets' => {
             'misses' => { 'main:cached' => 1 },
             'hits'   => { 'main:cached' => 2 },
           }
}, 'cache ok');

$x = cached('foo');
is_deeply( $cached_cache, {
 'sets' => {
             'count' => { 'main:cached'     => 1,
                          'main:cached:foo' => 1 }
           },
 'namespace' => 'cached',
 'data' => { 'main:cached'     => VALUE,
             'main:cached:foo' => VALUE, },
 'time' => { 'main:cached' => 20,
             'main:cached:foo' => 20, },
 'gets' => {
             'misses' => { 'main:cached' => 1,
                           'main:cached:foo' => 1 },
             'hits'   => { 'main:cached' => 2 },
           }
}, 'cache ok')
    or diag Dumper( $cached_cache );;

my $cached_cache2 = getCache(undef, 'basic');

my $y = cached2();
is ($y, VALUE);

is_deeply($cached_cache2, {
 'sets' => {
             'count' => { 'main:basic' => 1 }
           },
 'namespace' => 'basic',
 'data' => { 'main:basic' => VALUE, },
 'time' => { 'main:basic' => 20, },
 'gets' => {
             'misses' => { 'main:basic' => 1 }
           }
}, 'cache2 ok');

$y = cached2('bar');
is ($y, VALUE);

is_deeply($cached_cache2, {
 'sets' => {
             'count' => { 'main:basic' => 1,
                          'main:basic:bar' => 1 }
           },
 'namespace' => 'basic',
 'data' => { 'main:basic'     => VALUE,
             'main:basic:bar' => VALUE, },
 'time' => { 'main:basic'     => 20,
              'main:basic:bar' => 20, },
 'gets' => {
             'misses' => { 'main:basic' => 1,
                           'main:basic:bar' => 1 }
           }
}, 'cache2 ok');
