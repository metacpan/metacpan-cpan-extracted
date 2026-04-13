#!/usr/bin/env perl
# Guard objects: auto-free on scope exit, including on exception

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
$| = 1;
use Data::Pool::Shared;

my $pool = Data::Pool::Shared::I64->new(undef, 4);

# normal scope — guard auto-frees
{
    my ($idx, $guard) = $pool->alloc_guard;
    $pool->set($idx, 42);
    printf "inside scope: slot %d = %d, used = %d\n",
        $idx, $pool->get($idx), $pool->used;
}
printf "after scope: used = %d\n\n", $pool->used;

# exception safety — guard frees even if code dies
eval {
    my ($idx, $guard) = $pool->alloc_guard;
    $pool->set($idx, 99);
    printf "before die: slot %d = %d, used = %d\n",
        $idx, $pool->get($idx), $pool->used;
    die "simulated error";
};
warn "caught: $@" if $@;
printf "after die: used = %d\n\n", $pool->used;

# scalar context — only get the guard (index accessible via internals)
{
    my $guard = $pool->alloc_guard;
    printf "scalar guard: used = %d\n", $pool->used;
}
printf "after scalar guard: used = %d\n\n", $pool->used;

# try_alloc_guard — fill pool, guards keep slots alive
my @guards;
for (1..4) {
    my ($idx, $guard) = $pool->try_alloc_guard;
    printf "try_alloc_guard: %s (used=%d)\n",
        defined $idx ? "slot $idx" : "full", $pool->used;
    push @guards, $guard if $guard;
}
# 5th should fail — pool is full
my ($idx, $guard) = $pool->try_alloc_guard;
printf "try_alloc_guard when full: %s\n", defined $idx ? "slot $idx" : "undef (pool full)";
