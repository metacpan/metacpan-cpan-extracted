use strict;
use warnings;

use Benchmark qw(:all);
use Cache::FastMmap;
use Cache::LRU;
use Cache::Ref::LRU;
use Cache::Ref::Util::LRU::Array;
use Cache::Ref::Util::LRU::List;
use Tie::Cache::LRU;

my $size = 1024;
my $loop = 1000;

sub cache_hit {
    my $cache = shift;
    $cache->set(a => 1);
    my $c = 0;
    $c += $cache->get('a')
        for 1..$loop;
    $c;
}

print "cache_hit:\n";
cmpthese(-1, {
    'Cache::FastMmap' => sub {
        cache_hit(
            Cache::FastMmap->new(
                cache_size => '1m',
            ),
        );
    },
    'Cache::FastMmap (raw)' => sub {
        cache_hit(
            Cache::FastMmap->new(
                cache_size => '1m',
                raw_values => 1,
            ),
        );
    },
    'Cache::LRU' => sub {
        cache_hit(
            Cache::LRU->new(
                size => $size,
            ),
        );
    },
    'Cache::Ref::LRU (Array)' => sub {
        cache_hit(
            Cache::Ref::LRU->new(
                size      => $size,
                lru_class => qw(Cache::Ref::Util::LRU::Array),
            ),
        );
    },
    'Cache::Ref::LRU (List)'  => sub {
        cache_hit(
            Cache::Ref::LRU->new(
                size      => $size,
                lru_class => qw(Cache::Ref::Util::LRU::List),
            ),
        );
    },
    'Tie::Cache::LRU' => sub {
        tie my %cache, 'Tie::Cache::LRU', $size;
        $cache{a} = 1;
        my $c = 0;
        $c += $cache{a}
            for 1..$loop;
        $c;
    },
});

print "\ncache_set:\n";
srand(0);
my @keys = map { int rand(1048576) } 1..65536;

sub cache_set {
    my $cache = shift;
    $cache->set($_ => 1)
        for @keys;
    $cache;
}

cmpthese(-1, {
    # no test for Cache::FastMmap since it does not have the "size" parameter
    'Cache::LRU' => sub {
        cache_set(
            Cache::LRU->new(
                size => $size,
            ),
        );
    },
    # too slow
    #'Cache::Ref::LRU (Array)' => sub {
    #    cache_set(
    #        Cache::Ref::LRU->new(
    #            size      => $size,
    #            lru_class => qw(Cache::Ref::Util::LRU::Array),
    #        ),
    #    );
    #},
    'Cache::Ref::LRU (List)' => sub {
        cache_set(
            Cache::Ref::LRU->new(
                size      => $size,
                lru_class => qw(Cache::Ref::Util::LRU::List),
            ),
        );
    },
    'Tie::Cache::LRU' => sub {
        tie my %cache, 'Tie::Cache::LRU', $size;
        $cache{$_} = 1
            for @keys;
        \%cache;
    },
});
