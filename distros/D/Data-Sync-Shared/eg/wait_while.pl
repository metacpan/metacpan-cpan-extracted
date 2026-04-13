#!/usr/bin/env perl
# Condvar wait_while: idiomatic condition variable usage
#
# The standard condvar pattern: lock, check predicate, wait in loop.
# wait_while wraps this into a single call.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time usleep);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

# Shared state: a semaphore used as an atomic counter
my $counter = Data::Sync::Shared::Semaphore->new(undef, 1000, 0);
my $cv = Data::Sync::Shared::Condvar->new(undef);

my $target = 10;

# ---- Producer: increment counter, signal on each update ----
my $pid = fork // die "fork: $!";
if ($pid == 0) {
    for my $i (1..$target) {
        usleep(20_000);  # 20ms between increments
        $counter->release;
        $cv->lock;
        $cv->signal;
        $cv->unlock;
        printf "  producer: counter=%d\n", $counter->value;
    }
    _exit(0);
}

# ---- Consumer: wait until counter reaches target ----
my $t0 = time;

$cv->lock;
my $ok = $cv->wait_while(sub { $counter->value < $target }, 5.0);
$cv->unlock;

my $elapsed = time - $t0;
waitpid($pid, 0);

if ($ok) {
    printf "consumer: counter reached %d in %.3fs\n", $counter->value, $elapsed;
} else {
    printf "consumer: timed out, counter=%d\n", $counter->value;
}

# ---- Timeout example ----
print "\n--- timeout demo ---\n";
$cv->lock;
$t0 = time;
$ok = $cv->wait_while(sub { 1 }, 0.1);  # always true, will timeout
printf "wait_while(always_true, 0.1): returned %d in %.3fs\n",
    $ok, time - $t0;
$cv->unlock;
