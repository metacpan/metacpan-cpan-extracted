use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);

use Data::Sync::Shared;

# Blocking Semaphore acquire should survive EINTR during FUTEX_WAIT.

my $sem = Data::Sync::Shared::Semaphore->new(undef, 1);
$sem->acquire;  # drain to 0

my $releaser = fork // die;
if ($releaser == 0) {
    select undef, undef, undef, 0.3;
    $sem->release;
    _exit(0);
}

$SIG{USR1} = sub { diag "SIGUSR1 received" };

my $signaller = fork // die;
if ($signaller == 0) {
    select undef, undef, undef, 0.1;
    kill USR1 => getppid();
    _exit(0);
}

my $t0 = time;
my $got = $sem->acquire(2.0);
my $dt = time - $t0;

waitpid $releaser, 0;
waitpid $signaller, 0;

ok $got, 'acquire returned after EINTR + release';
ok $dt < 1.5, sprintf('completed in %.2fs (no lost wakeup)', $dt);

done_testing;
