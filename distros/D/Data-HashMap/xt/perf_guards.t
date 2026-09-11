use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use Data::HashMap::II;
use Data::HashMap::SA;


{
    my $m = Data::HashMap::II->new(12287);
    hm_ii_put $m, $_, 1 for 1 .. 12287;
    my $t = time;
    hm_ii_put $m, $_, 1 for 12288 .. 32287;
    my $d = time - $t;
    cmp_ok($d, '<', 1.0, sprintf('20k steady-state LRU inserts at max_size 12287: %.3fs', $d));
}

{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, $_, 1 for 1 .. 800_000;
    hm_ii_remove $m, $_ for 2 .. 800_000;
    my $t = time;
    for (900_001 .. 902_000) { hm_ii_put $m, $_, 1; hm_ii_remove $m, $_ }
    my $d = time - $t;
    cmp_ok($d, '<', 0.5, sprintf('2000 put/remove pairs on a sparse table with one resident key: %.3fs', $d));
}

{
    my $m = Data::HashMap::II->new(0, 1);
    hm_ii_put $m, $_, 1 for 1 .. 100_000;
    my $cap = hm_ii_capacity $m;
    sleep 2;
    hm_ii_put $m, $_, 1 for 100_001 .. 200_000;
    is(hm_ii_capacity $m, $cap, 'a second batch inserted after the first expired does not grow the table');
}

{
    my $m = Data::HashMap::II->new(12287, 3600);
    hm_ii_put $m, $_, 1 for 1 .. 12287;
    my $t = time;
    hm_ii_put $m, $_, 1 for 12288 .. 32287;
    my $d = time - $t;
    cmp_ok($d, '<', 1.0, sprintf('20k steady-state inserts into an LRU+TTL map: %.3fs', $d));
}

{
    my $m = Data::HashMap::II->new(0, 3600);
    hm_ii_put $m, $_, 1 for 1 .. 12000;
    my $live = int(hm_ii_capacity($m) * 0.75) - 1;
    hm_ii_clear $m;
    hm_ii_put $m, $_, 1 for 1 .. $live;
    my $n = $live;
    my $t = time;
    for (1 .. 5000) { hm_ii_remove $m, $n - $live + 1; hm_ii_put $m, ++$n, 1 }
    my $d = time - $t;
    cmp_ok($d, '<', 0.1, sprintf('5000 remove+insert at the threshold of a TTL map: %.3fs', $d));
}

SKIP: {
    skip 'RSS check requires /proc (Linux)', 1 unless -r "/proc/$$/status";
    # Shadow memory and redzones move RSS on their own under a sanitizer.
    skip 'RSS is not measurable under a sanitizer', 1
        if ($ENV{LD_PRELOAD} || '') =~ /libu?[at]san/ || $ENV{ASAN_OPTIONS};
    my $rss = sub { open my $f, '<', "/proc/$$/status" or return 0;
                    while (<$f>) { return $1 if /^VmRSS:\s+(\d+)/ } 0 };
    my $m = Data::HashMap::SA->new;
    $m->put("k$_", "v$_") for 1 .. 500_000;
    my $before = $rss->();
    $m->clear;
    my $after = $rss->();
    cmp_ok($after - $before, '<', 1024,
        sprintf('clear() of a 500k SV* map does not grow the process (%+d kB)', $after - $before));
}

done_testing;
