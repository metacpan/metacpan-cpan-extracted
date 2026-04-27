use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Data::Queue::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# 64 concurrent workers. Catches scaling issues that 8-worker stress
# tests miss (priority inversion, lost FUTEX_WAKE at edge, kernel
# contention). Expected to complete in <15 seconds on modern hardware.

my $N_WORKERS = 64;
my $PER       = 500;
my $cap       = 256;

my $q = Data::Queue::Shared::Int->new(undef, $cap);

my @pids;
my $t0 = time;
for my $w (1..$N_WORKERS) {
    my $pid = fork // die;
    if ($pid == 0) {
        # Half producers, half consumers
        if ($w <= $N_WORKERS / 2) {
            for (1..$PER) { while (!$q->push($w * 10_000 + $_)) { } }
        } else {
            my $got = 0;
            while ($got < $PER) { defined $q->pop and $got++ }
        }
        _exit(0);
    }
    push @pids, $pid;
}

# Wait for all children (with generous timeout)
my $deadline = time + 60;
for my $pid (@pids) {
    my $ok = 0;
    while (time < $deadline) {
        my $w = waitpid($pid, POSIX::WNOHANG());
        if ($w == $pid) { $ok = 1; last }
        select(undef, undef, undef, 0.05);
    }
    if (!$ok) {
        kill 'KILL', $pid;
        waitpid($pid, 0);
        fail "worker $pid stuck — killed";
        done_testing;
        exit 1;
    }
}
my $elapsed = time - $t0;

is scalar(keys %{{map { $_ => 1 } @pids}}), $N_WORKERS,
    "$N_WORKERS workers completed";
cmp_ok $elapsed, '<', 60, "completed within 60s (took $elapsed s)";

# Producers pushed (N/2 * PER); consumers popped the same. Final size = 0.
is $q->size, 0, 'queue drained';

my $stats = $q->stats;
is $stats->{push_ok}, ($N_WORKERS / 2) * $PER, 'stats push_ok matches';
is $stats->{pop_ok}, ($N_WORKERS / 2) * $PER, 'stats pop_ok matches';

done_testing;
