use strict;
use warnings;
use Test::More;

# Endurance: 500k random ops, observe RSS. Perl handle lifetimes must
# be correct — no SV leaks in XS callbacks. A growing RSS over time
# indicates a leak.

use Data::Pool::Shared;

my $p = Data::Pool::Shared::I64->new_memfd("endur", 512);

sub get_rss {
    open my $fh, '<', "/proc/$$/status" or return 0;
    while (<$fh>) {
        return $1 if /^VmRSS:\s+(\d+)/;
    }
    return 0;
}

# Warm up + observe baseline
$p->alloc for 1..100;
$p->free($_) for 0..99;

my $rss_start = get_rss();
diag "RSS start: ${rss_start}KB";

my $N = 500_000;
my @alloc;
for my $i (1..$N) {
    if ($i % 2 || !@alloc) {
        my $s = $p->alloc;
        if (defined $s) {
            $p->set($s, $i);
            push @alloc, $s;
        }
    } else {
        my $s = splice @alloc, int(rand(@alloc)), 1;
        $p->free($s);
    }

    # Exercise stats/slot_sv occasionally (XS lifetime paths)
    $p->stats if $i % 1000 == 0;
    if ($i % 5000 == 0 && @alloc) {
        my $sv = $p->slot_sv($alloc[0]);
        my $len = length $sv;
    }
}

# Cleanup
$p->free($_) for @alloc;

my $rss_end = get_rss();
my $growth = $rss_end - $rss_start;
diag "RSS end:   ${rss_end}KB (growth=${growth}KB over $N ops)";

# Growth should be minimal — a few hundred KB is normal for Perl's
# arena growth, but 10MB+ would indicate a leak.
cmp_ok $growth, '<', 10 * 1024, "RSS growth < 10MB over $N ops";

done_testing;
