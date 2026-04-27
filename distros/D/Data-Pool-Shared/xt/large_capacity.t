use strict;
use warnings;
use Test::More;

# Large-capacity sizing: boundary values for layout math. Catches
# accidental int32 casts in uint64 offset computation.

use Data::Pool::Shared;

# Skip on low-memory CI
my $free_kb = 0;
if (open my $mi, '<', '/proc/meminfo') {
    while (<$mi>) { $free_kb = $1 if /^MemAvailable:\s+(\d+)/ }
}
plan skip_all => "need >= 512MB available (have ${free_kb}KB)"
    if $free_kb && $free_kb < 512 * 1024;

# 2^24 = 16M slots × 8 bytes = 128MB — large but feasible
my $caps = [
    1 << 16,   # 64K — baseline
    1 << 20,   # 1M
    1 << 24,   # 16M
];

for my $cap (@$caps) {
    my $p = eval { Data::Pool::Shared::I64->new_memfd("lc", $cap) };
    ok $p, "capacity=$cap: allocation succeeded";
    is $p->capacity, $cap, "capacity preserved ($cap)";

    # Sanity: alloc+free on boundary slots
    my @slots = map $p->alloc, 1..10;
    for my $i (0..$#slots) {
        $p->set($slots[$i], $i * 1000);
    }
    for my $i (0..$#slots) {
        is $p->get($slots[$i]), $i * 1000, "get/set slot $slots[$i] works";
    }

    # Free all
    $p->free($_) for @slots;
    is $p->used, 0, "all slots freed";
}

# UINT32_MAX boundary: MUST fail cleanly (overflow in bitmap_words math)
my $huge = (1 << 32) * 64;   # POOL_MAX_CAPACITY upper bound
my $p = eval { Data::Pool::Shared::I64->new_memfd("huge", $huge + 1) };
ok !$p, "capacity > POOL_MAX_CAPACITY rejected";

done_testing;
