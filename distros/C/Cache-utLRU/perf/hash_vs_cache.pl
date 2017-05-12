use strict;
use warnings;

use Time::HiRes qw/time/;
use Cache::utLRU;

my $size = 100_000;
my $elems = 1_000_000;

exit main();

sub main {
    my $time_hash = do_hash();
    my $time_cache = do_cache();
    printf("hash: %d ms -- cache: %d ms\n", $time_hash, $time_cache);
    return 0;
}

sub do_hash {
    my %hash;
    my $t0 = time();
    $hash{"key_$_"} = "val_$_" for 1..$elems;
    my $t1 = time();
    return int(1000 * ($t1 - $t0));
}

sub do_cache {
    my $cache = Cache::utLRU->new($size);
    my $t0 = time();
    $cache->add("key_$_", "val_$_") for 1..$elems;
    my $t1 = time();
    return int(1000 * ($t1 - $t0));
}
