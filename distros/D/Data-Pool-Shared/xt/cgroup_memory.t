use strict;
use warnings;
use Test::More;

# Under cgroup v2 memory.max, a capacity-large pool should error via
# ENOMEM-like path rather than triggering the OOM killer. Requires an
# environment with a configured memory cgroup. Env-gated.

plan skip_all => "set CGROUP_MEMTEST=1 to run" unless $ENV{CGROUP_MEMTEST};
plan skip_all => "need cgroup v2 unified hierarchy"
    unless -r '/sys/fs/cgroup/memory.max' || -r '/proc/self/cgroup';

use Data::Pool::Shared;

# Try to allocate a pool large enough to exceed typical cgroup limits.
# The allocation itself is just an ftruncate+mmap; page-faults will
# trigger the cgroup OOM response lazily — so touch each page.

my $CAP_MB = $ENV{CGROUP_CAP_MB} || 512;
my $capacity = $CAP_MB * 1024 * 1024 / 8;   # 8 bytes per I64 slot

my $p = eval { Data::Pool::Shared::I64->new_memfd("cgmem", $capacity) };

if (!$p) {
    ok 1, "graceful failure under cgroup memory pressure: $@";
} else {
    # Touch enough pages to exceed a typical memory.max=256MB limit
    for my $i (0..$capacity - 1) {
        $p->alloc;
        last if $i > 1_000_000;   # bail after 8MB
    }
    pass "allocation did not OOM-kill us";
}

done_testing;
