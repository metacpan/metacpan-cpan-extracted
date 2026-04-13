use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::Pool::Shared;

# --- Cross-process sharing ---

my $path = tmpnam() . '.shm';
END { unlink $path if $path && -f $path }

my $pool = Data::Pool::Shared::I64->new($path, 100);

# Parent allocs, child reads
my $idx = $pool->alloc;
$pool->set($idx, 42);

my $pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    my $child = Data::Pool::Shared::I64->new($path, 100);
    my $val = $child->get($idx);
    _exit($val == 42 ? 0 : 1);
}
waitpid($pid, 0);
is $? >> 8, 0, 'child read parent-written value';
$pool->free($idx);

# Concurrent allocation — N children each alloc a slot and write their PID
my $N = 20;
for my $n (1..$N) {
    my $p = fork;
    die "fork: $!" unless defined $p;
    if ($p == 0) {
        my $c = Data::Pool::Shared::I64->new($path, 100);
        my $s = $c->alloc;
        $c->set($s, $$);
        _exit(defined $s ? 0 : 1);
    }
}
for (1..$N) { wait }
is $pool->used, $N, "$N children each allocated a slot";

# Verify all slots have valid PIDs
my @pids;
$pool->each_allocated(sub {
    push @pids, $pool->get($_[0]);
});
is scalar @pids, $N, 'found N allocated slots';

$pool->reset;

# --- Stale recovery ---

my $idx2 = $pool->alloc;
$pool->set($idx2, 999);

$pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    my $c = Data::Pool::Shared::I64->new($path, 100);
    # Alloc a slot and die without freeing
    my $s = $c->alloc;
    $c->set($s, 12345);
    _exit(0);
}
waitpid($pid, 0);
is $pool->used, 2, '2 slots allocated (parent + dead child)';

my $recovered = $pool->recover_stale;
is $recovered, 1, 'recovered 1 stale slot';
is $pool->used, 1, '1 slot remains (parent)';
is $pool->get($idx2), 999, 'parent slot untouched';
$pool->free($idx2);

# --- Blocking alloc with futex wakeup ---

# Fill pool to capacity, fork child that frees after delay
$pool->reset;
my @fill;
for (1..100) {
    push @fill, $pool->alloc;
}
is $pool->used, 100, 'pool filled to 100';

$pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    my $c = Data::Pool::Shared::I64->new($path, 100);
    select(undef, undef, undef, 0.1);  # sleep 100ms
    $c->free($fill[0]);  # free one slot
    _exit(0);
}

# Parent blocks on alloc, should wake when child frees
my $blocked = $pool->alloc(2.0);
ok defined $blocked, 'blocking alloc succeeded after child freed';
waitpid($pid, 0);

$pool->reset;

# --- Timeout ---

for (1..100) { $pool->alloc }
my $t0 = time;
my $to = $pool->alloc(0.2);
ok !defined $to, 'alloc timed out';
ok time - $t0 < 2, 'timeout was reasonably fast';
$pool->reset;

# --- Anonymous pool across fork ---

my $anon = Data::Pool::Shared::I64->new(undef, 10);
my $ai = $anon->alloc;
$anon->set($ai, 77);

$pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    # Child inherits mmap from fork
    _exit($anon->get($ai) == 77 ? 0 : 1);
}
waitpid($pid, 0);
is $? >> 8, 0, 'anonymous pool shared across fork';
$anon->free($ai);

# --- Atomic operations across processes ---

$pool->reset;
my $counter = $pool->alloc;
$pool->set($counter, 0);

my $WORKERS = 10;
my $ITERS = 1000;
for (1..$WORKERS) {
    my $p = fork;
    die "fork: $!" unless defined $p;
    if ($p == 0) {
        my $c = Data::Pool::Shared::I64->new($path, 100);
        for (1..$ITERS) {
            $c->add($counter, 1);
        }
        _exit(0);
    }
}
for (1..$WORKERS) { wait }
is $pool->get($counter), $WORKERS * $ITERS, 'atomic add correct across processes';
$pool->free($counter);

done_testing;
