#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes 1.84 qw(time clock);
use Try::Tiny;
use Test::More;
use List::Util qw(shuffle);

use Test::Needs qw(
    Cache::Ref::FIFO
    Cache::Ref::LRU
    Cache::Ref::CART
    Cache::Ref::CLOCK
);

use ok 'Cache::Profile';
use ok 'Cache::Profile::CorrelateMissTiming';
use ok 'Cache::Profile::Compare';

# this uses a weighted key set
my @keys = shuffle( ( map { 1 .. $_ } 1 .. 25 ), 1 .. 200 );
my %seen;
my $sigma = grep { !$seen{$_}++ } @keys;

my $size = 20;

my $p_fifo = Cache::Profile->new(
    cache => Cache::Ref::FIFO->new( size => $size ),
);

$p_fifo->set( foo => "bar" );
is( $p_fifo->get("foo"), "bar", "simple set/get" );

is( $p_fifo->hit_count, 1, "hit count" );
is( $p_fifo->miss_count, 0, "miss count" );

$p_fifo->reset;

is( $p_fifo->get("bar"), undef, "cache miss" );

is( $p_fifo->hit_count, 0, "hit count" );
is( $p_fifo->miss_count, 1, "miss count" );

$p_fifo->reset;

my $p_lru = Cache::Profile::CorrelateMissTiming->new(
    cache => Cache::Ref::LRU->new( size => $size ),
);

my $p_cart = Cache::Profile->new(
    cache => Cache::Ref::CART->new( size => $size ),
);

my @more = ( Cache::Ref::CLOCK->new( size => $size ) );

try {
    require CHI;
    #push @more, CHI->new( driver => 'Memory', datastore => {}, max_size => $size );
    push @more, CHI->new( driver => 'Memory', datastore => {} ); # max size seems broken
};

try {
    require Cache::FastMmap;
    push @more, Cache::FastMmap->new(cache_size => '1k');
};

try {
    require Cache::Bounded;
    push @more, Cache::Bounded->new({ interval => 5, size => $size });
};

try {
    require Cache::MemoryCache;
    push @more, Cache::MemoryCache->new();
};

my $cmp = Cache::Profile::Compare->new( caches => \@more );

my ( $get, $set ) = ( 0, 0 );

my $start = clock();
my $end = $start + 0.3 * ( 3 + @more );

sub _waste_time {
    my @foo;
    push @foo, [ 1 .. 100 ] for 1 .. 20;
}

my $i;
until ( (clock() > $end) and $i > @keys * 3 ) {
    pass("making progress") if $get % ( @keys / 3 ) == 0; # looks better when the numbers are moving ;-)

    my $key = $keys[rand > 0.7 ? int rand @keys : $i++ % @keys];

    foreach my $cache ( $p_fifo, $p_lru, $cmp ) {
        if ( rand > 0.5 ) {
            unless ( $cache->get($key) ) {
                _waste_time();
                $cache->set( $key => rand > 0.5 ? { foo => "bar", data => [ 1 .. 10 ] } : "blahblah" );
            }
        } else {
            $cache->compute( $key, sub {
                _waste_time();
                return rand > 0.5 ? { foo => "bar", data => [ 1 .. 10 ] } : "blahblah";
            });
        }
    }

    $get++;
    $p_cart->compute( $key, sub {
        $set++;
        _waste_time();
        return rand > 0.5 ? { foo => "bar", data => [ 1 .. 10 ] } : "blahblah";
    });
}

is( $p_cart->call_count_get, $get, "get count" );
is( $p_cart->call_count_set, $set, "set count" );

is( $p_cart->query_count, $p_fifo->call_count_get, "no multi key queries" );

my $report = $p_cart->report;

like( $report, qr/hit rate/i, "report contains 'hit rate'" );
like( $report, qr/${\ $p_cart->hit_count }/, "contains hit count" );
like( $report, qr/${\ $p_cart->query_count }/, "contains query count" );

foreach my $cache ( $p_cart, $p_lru, $cmp->profiles ) {
    my $hit;
    foreach my $key ( @keys ) {
        if ( defined $cache->get($key) ) {
            $hit++;
            last;
        }
    }
    ok($hit, "at least one key in cache (" . $cache->moniker . ")");

    cmp_ok( $p_cart->hit_rate, '>=', ( ( $size / @keys ) / 2), "hit rate bigger than minimum" );

    foreach my $method ( qw(get set miss) ) {
        cmp_ok( $cache->${\"call_count_$method"}, '>=', $sigma, "$method called enough times" );

        foreach my $measure ( qw(real cpu) ) {
            cmp_ok( $cache->${\"total_${measure}_time_${method}"}, '>=', 0.001, "some $measure time accrued for $method" );
        }
    }
}

cmp_ok( $p_cart->hit_rate, '>', $p_lru->hit_rate, "CART beats LRU" );
cmp_ok( $p_lru->hit_rate,  '>', $p_fifo->hit_rate, "LRU beats FIFO" );

$p_lru->set(foo => 42);
$p_lru->clear;
is( $p_lru->get("foo"), undef );

done_testing;

# ex: set sw=4 et:

