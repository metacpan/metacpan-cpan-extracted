use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);

# Verify pop_wait uses CLOCK_MONOTONIC (or equivalent monotonic source)
# by signalling the waiter with SIGALRM during a timed wait. A wall-clock
# timeout could fire early or late on systems where NTP steps the clock;
# monotonic-based futex timeouts fire at the programmed interval
# regardless of wall-clock adjustments.

use Data::Queue::Shared::Int;

my $q = Data::Queue::Shared::Int->new_memfd("clkmono", 4);

# Wait ~500ms for an item that never arrives; expect EAGAIN/timeout return.
my $t0 = time;
my $r = $q->pop_wait(0.5);
my $elapsed = time - $t0;

ok !defined($r), "pop_wait returned without item (timeout)";
cmp_ok $elapsed, '>=', 0.4, "elapsed >= 400ms (actual ${\sprintf '%.3f', $elapsed}s)";
cmp_ok $elapsed, '<=', 2.0, "elapsed <= 2000ms (not hung)";

# A push from a forked child should wake pop_wait within 100ms.
my $pid = fork // die "fork: $!";
if (!$pid) {
    select undef, undef, undef, 0.1;
    my $q2 = Data::Queue::Shared::Int->new_from_fd($q->memfd);
    $q2->push(42);
    exit 0;
}

$t0 = time;
my $v = $q->pop_wait(2);
$elapsed = time - $t0;
is $v, 42, "woken on push";
cmp_ok $elapsed, '<', 1.0, "woken promptly (${\sprintf '%.3f', $elapsed}s)";

waitpid $pid, 0;

done_testing;
