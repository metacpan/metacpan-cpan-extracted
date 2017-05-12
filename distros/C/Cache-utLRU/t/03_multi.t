use strict;
use warnings;
use utf8;

use Test::More;

use Cache::utLRU;

exit main();

sub main {
    my $num_caches = 20;
    my $cache_size = 100;
    my $num_elems = 120;

    my @caches;

    for (my $idx_cache = 0; $idx_cache < $num_caches; ++$idx_cache) {
        my $cache = $caches[$idx_cache] = Cache::utLRU->new($cache_size);
        for (my $idx_elem = 0; $idx_elem < $num_elems; ++$idx_elem) {
            my $key = make_value('key', $idx_cache, $idx_elem);
            my $val = make_value('val', $idx_cache, $idx_elem);
            $cache->add($key, $val);
        }
    }

    for (my $idx_cache = 0; $idx_cache < $num_caches; ++$idx_cache) {
        my $cache = $caches[$idx_cache];
        my $delta = $num_elems - $cache_size;
        for (my $idx_elem = 0; $idx_elem < $delta; ++$idx_elem) {
            my $key = make_value('key', $idx_cache, $idx_elem);
            my $got = $cache->find($key);
            is($got, undef, "'$key' => 'undef'");
        }
        for (my $idx_elem = $delta; $idx_elem < $num_elems; ++$idx_elem) {
            my $key = make_value('key', $idx_cache, $idx_elem);
            my $val = make_value('val', $idx_cache, $idx_elem);
            my $got = $cache->find($key);
            is($got, $val, "'$key' => '$val'");
        }
    }

    done_testing;
    return 0;
}

sub make_value {
    my ($str, $c, $e) = @_;
    return sprintf("%s:%05d:%08d", $str, $c, $e);
}
