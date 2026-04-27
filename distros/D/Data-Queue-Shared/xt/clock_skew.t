use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use POSIX qw(_exit);

# Clock skew between processes: CLOCK_MONOTONIC is per-system, not
# per-process, so different processes observe the same monotonic
# clock. Verify that cross-process timed waits agree on elapsed time
# within reasonable jitter.

use Data::Queue::Shared::Int;

my $q = Data::Queue::Shared::Int->new_memfd("skew", 16);

my $pid = fork // die;
if (!$pid) {
    my $q2 = Data::Queue::Shared::Int->new_from_fd($q->memfd);
    # Measure child's monotonic-time pop_wait
    my $t0 = time;
    my $v = $q2->pop_wait(0.3);
    my $el = time - $t0;
    # Encode elapsed milliseconds × 1000 into exit code (capped 250)
    my $code = int($el * 1000);
    $code = 250 if $code > 250;
    _exit($code);
}

my $t0 = time;
# Nothing to pop in parent either - both time out roughly together
my $v = $q->pop_wait(0.3);
my $parent_el = time - $t0;

waitpid $pid, 0;
my $child_el = ($? >> 8) / 1000;

diag sprintf "  parent elapsed: %.3fs", $parent_el;
diag sprintf "  child elapsed:  %.3fs (encoded: %dms)", $child_el, ($? >> 8);

ok !defined $v, "parent pop_wait timed out";

# Both should have waited close to 300ms, regardless of any clock skew.
# Allow ±50ms jitter.
cmp_ok abs($parent_el - 0.3), '<', 0.1, "parent elapsed near 300ms";
cmp_ok abs($child_el - 0.3),  '<', 0.1, "child elapsed near 300ms";
cmp_ok abs($parent_el - $child_el), '<', 0.15,
    "cross-process elapsed times agree within 150ms";

done_testing;
