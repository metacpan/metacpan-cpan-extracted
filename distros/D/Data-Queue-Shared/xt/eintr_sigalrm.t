use strict;
use warnings;
use Test::More;
use POSIX ();
use Time::HiRes qw(time);

# SIGALRM during futex-based pop_wait: the syscall may return EINTR; the
# wrapper must either retry transparently or surface a clean error, and
# must not leave waiters deadlocked.

use Data::Queue::Shared::Int;

my $q = Data::Queue::Shared::Int->new_memfd("eintr", 4);

# Arrange SIGALRM to fire ~100ms into a 500ms wait.
my $got_alrm = 0;
local $SIG{ALRM} = sub { $got_alrm++ };

POSIX::setitimer(POSIX::ITIMER_REAL(), 0.1, 0) if POSIX->can('setitimer');
# fallback for older Perl:
alarm(1) if !$got_alrm && !POSIX->can('setitimer');

my $t0 = time;
my $r = $q->pop_wait(0.5);
my $elapsed = time - $t0;

ok !defined($r), "pop_wait returned (timeout or EINTR)";
cmp_ok $elapsed, '<=', 2.0, "no deadlock (${\sprintf '%.3f', $elapsed}s)";

# After the signal, the queue is still operable.
$q->push(7);
is $q->pop, 7, "queue still functional after SIGALRM";

done_testing;
