use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);

use Data::Queue::Shared;

# Verify blocking pop_wait recovers cleanly from EINTR (signal delivered
# during FUTEX_WAIT). The futex wait should return, module re-checks state
# and either completes or re-parks — no lost wakeups, no spurious timeout.

my $q = Data::Queue::Shared::Int->new(undef, 16);

my $pid = fork // die;
if ($pid == 0) {
    # Producer: wait a bit, push
    select undef, undef, undef, 0.3;
    $q->push(42);
    _exit(0);
}

# Install a SIGUSR1 handler that fires during the pop_wait
$SIG{USR1} = sub { diag "SIGUSR1 received" };

# Schedule a SIGUSR1 to ourself while blocked
my $signaller_pid = fork // die;
if ($signaller_pid == 0) {
    select undef, undef, undef, 0.1;
    kill USR1 => getppid();
    _exit(0);
}

my $t0 = time;
my $v = $q->pop_wait(2.0);
my $dt = time - $t0;

waitpid $pid, 0;
waitpid $signaller_pid, 0;

is $v, 42, 'pop_wait returned producer value after EINTR';
ok $dt < 1.5, sprintf('completed in %.2fs (no lost wakeup)', $dt);

done_testing;
