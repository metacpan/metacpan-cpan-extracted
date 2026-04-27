use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(usleep);
use Data::Queue::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Stale-PID recovery for the Str-mode mutex: if a process holding the
# mutex is SIGSTOP'd and later SIGKILL'd, waiters must eventually
# recover (via kill(pid, 0) probe) rather than block forever.

my $q = Data::Queue::Shared::Str->new(undef, 8, 64);
$q->push("warm");   # prime the mutex path

my $holder = fork // die;
if ($holder == 0) {
    # Wedge ourselves inside the mutex. push_multi holds the mutex
    # for the entire loop; an infinite push loop will never release.
    my @long = ("x" x 60) x 100;
    while (1) {
        $q->push_multi(@long);
        $q->drain(100);
    }
    _exit(0);
}

# Pause holder, then kill it after a moment to simulate a dead lock holder
usleep(100_000);
kill 'STOP', $holder;
usleep(500_000);       # holder is paused with mutex possibly held
kill 'KILL', $holder;
waitpid($holder, 0);

# Waiter: another push_multi. Must complete (not deadlock) — the
# stale-PID recovery kicks in at the 2-sec timeout.
my $t0 = time;
my $rc = eval {
    local $SIG{ALRM} = sub { die "stuck\n" };
    alarm 10;
    $q->push_multi("after");
    alarm 0;
    1;
};
my $elapsed = time - $t0;

ok $rc, 'push_multi after stale holder returns';
cmp_ok $elapsed, '<', 10, "completed in $elapsed s (< 10s)";
ok defined $q->pop, 'queue still functional';

done_testing;
