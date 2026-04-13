use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time usleep);

use Data::Sync::Shared;

# ============================================================
# RWLock starvation diagnostic
#
# Measures writer latency under sustained reader load.
# Not a pass/fail test — outputs diagnostic numbers.
# ============================================================

my $DURATION = $ENV{STARVATION_SECS} || 2;
my $NREADERS = $ENV{STARVATION_READERS} || 4;

my $rw = Data::Sync::Shared::RWLock->new(undef);

# Shared semaphore to signal "stop"
my $stop = Data::Sync::Shared::Semaphore->new(undef, 1);

# ---- Start readers: tight rdlock/rdunlock loop ----
my @reader_pids;
for my $r (1..$NREADERS) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $ops = 0;
        while ($stop->value > 0) {
            $rw->rdlock;
            $rw->rdunlock;
            $ops++;
        }
        _exit(0);
    }
    push @reader_pids, $pid;
}

# ---- Writer: measure latency of each wrlock acquisition ----
my @latencies;
my $t_start = time;

while (time - $t_start < $DURATION) {
    my $t0 = time;
    $rw->wrlock;
    my $lat = time - $t0;
    push @latencies, $lat;
    $rw->wrunlock;
    usleep(100);  # small gap to let readers run
}

# Signal readers to stop
$stop->try_acquire;

# Wait for readers
waitpid($_, 0) for @reader_pids;

# ---- Report ----
if (@latencies) {
    my @sorted = sort { $a <=> $b } @latencies;
    my $n = scalar @sorted;
    my $sum = 0; $sum += $_ for @sorted;
    my $avg = $sum / $n;
    my $p50 = $sorted[int($n * 0.50)];
    my $p95 = $sorted[int($n * 0.95)];
    my $p99 = $sorted[int($n * 0.99)];
    my $max = $sorted[-1];

    diag sprintf "rwlock starvation: %d readers, %d writer acquisitions in %.1fs",
        $NREADERS, $n, $DURATION;
    diag sprintf "  avg: %.3fms  p50: %.3fms  p95: %.3fms  p99: %.3fms  max: %.3fms",
        $avg * 1000, $p50 * 1000, $p95 * 1000, $p99 * 1000, $max * 1000;

    # Soft check: p99 writer latency should be under 100ms
    # This is a diagnostic, not a hard requirement
    ok $p99 < 0.1, sprintf('p99 writer latency %.3fms < 100ms', $p99 * 1000);
    ok $max < 1.0, sprintf('max writer latency %.3fms < 1000ms', $max * 1000);
} else {
    fail 'no writer acquisitions completed';
}

my $s = $rw->stats;
diag sprintf "  acquires: %d  releases: %d  recoveries: %d",
    $s->{acquires}, $s->{releases}, $s->{recoveries};

done_testing;
