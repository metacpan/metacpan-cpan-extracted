#!/usr/bin/env perl
# Stale recovery: child allocates slots and dies, parent recovers them

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::Pool::Shared;
$| = 1;

my $pool = Data::Pool::Shared::I64->new(undef, 10);

# parent allocates 2 slots
my $p1 = $pool->alloc;
my $p2 = $pool->alloc;
$pool->set($p1, 111);
$pool->set($p2, 222);
printf "parent allocated slots %d, %d — used = %d\n", $p1, $p2, $pool->used;

# child allocates 3 slots and dies without freeing
my $pid = fork // die "fork: $!";
if ($pid == 0) {
    for (1..3) {
        my $s = $pool->alloc;
        $pool->set($s, $$ * 1000 + $_);
    }
    printf "child (pid=%d) allocated 3 slots — used = %d\n", $$, $pool->used;
    _exit(0);  # die without freeing
}
waitpid($pid, 0);
printf "after child exit: used = %d\n", $pool->used;

# recover stale slots
my $recovered = $pool->recover_stale;
printf "recovered %d stale slots — used = %d\n", $recovered, $pool->used;

# parent's slots are intact
printf "parent slot %d = %d (intact)\n", $p1, $pool->get($p1);
printf "parent slot %d = %d (intact)\n", $p2, $pool->get($p2);

my $s = $pool->stats;
printf "stats: allocs=%d frees=%d recoveries=%d\n",
    $s->{allocs}, $s->{frees}, $s->{recoveries};

$pool->free($p1);
$pool->free($p2);
