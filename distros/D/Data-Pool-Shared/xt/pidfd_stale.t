use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);

# Validate today's PID-based stale-slot recovery against a pidfd-based
# oracle (Linux >= 5.3). pidfd_open returns an fd that poll()s readable
# exactly when the target pid exits — immune to PID reuse. This test
# sanity-checks that recover_stale() finds the slots pidfd says are
# freeable.

use Config;
plan skip_all => "needs Linux" unless $^O eq 'linux';

# pidfd_open syscall number: x86_64=434, aarch64=434, arm=434
my %PIDFD_OPEN = (
    'x86_64-linux'     => 434,
    'aarch64-linux'    => 434,
    'arm-linux'        => 434,
    'x86_64-linux-ld'  => 434,
);
my $nr = $PIDFD_OPEN{$Config{archname}}
    or plan skip_all => "pidfd_open syscall not known for $Config{archname}";

use Data::Pool::Shared;

my $p = Data::Pool::Shared::I64->new_memfd("pidfd", 16);

# Fork a child, allocate a slot in the child's name
my $pid = fork // die;
if (!$pid) {
    my $p2 = Data::Pool::Shared::I64->new_from_fd($p->memfd);
    my $s = $p2->alloc;
    $p2->set($s, 42);
    _exit(0);   # die immediately, leaving slot orphaned
}

# Open pidfd before child dies (need pid alive)
my $pidfd = syscall($nr, $pid, 0);
if ($pidfd < 0) {
    waitpid $pid, 0;
    plan skip_all => "pidfd_open failed: $!";
}

waitpid $pid, 0;
is $p->used, 1, "child allocated 1 slot before dying";

# pidfd should now be readable (child exited)
my $rin = '';
vec($rin, $pidfd, 1) = 1;
my $nready = select($rin, undef, undef, 0.1);
cmp_ok $nready, '>=', 1, "pidfd signals child exit (oracle)";
POSIX::close($pidfd);

# Now the module's PID-based recovery should find and reclaim the slot
my $recovered = $p->recover_stale;
is $recovered, 1, "PID-based stale recovery reclaims 1 slot";
is $p->used, 0, "all slots freed after recovery";

done_testing;
