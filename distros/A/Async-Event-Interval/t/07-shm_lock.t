use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use IPC::Shareable qw(SEM_PROTECTED);
use Test::More;

use Async::Event::Interval;

my $mod = 'Async::Event::Interval';

# _rand_shm_lock() invariants

{
    my $val = Async::Event::Interval::_rand_shm_lock();

    like $val, qr/^\d+$/, "_rand_shm_lock() returns an integer";
    cmp_ok $val, '>',  0,     "_rand_shm_lock() is > 0 (0 means unprotected)";
    cmp_ok $val, '<=', 32767, "_rand_shm_lock() is <= 32767 (SEM_PROTECTED max)";

    is
        $val,
        1 + ($$ % 32767),
        "_rand_shm_lock() is derived from \$\$ as 1 + (\$\$ %% 32767)";
}

# Deterministic within the same process

{
    my $a = Async::Event::Interval::_rand_shm_lock();
    my $b = Async::Event::Interval::_rand_shm_lock();
    my $c = Async::Event::Interval::_rand_shm_lock();

    is $a, $b, "_rand_shm_lock() is stable across calls in the same process (a == b)";
    is $b, $c, "_rand_shm_lock() is stable across calls in the same process (b == c)";
}

# _shm_lock() returns the value captured at module load time and matches
# what _rand_shm_lock() yields for this PID

{
    my $e = $mod->new(0, sub {});

    my $lock_via_obj   = $e->_shm_lock;
    my $lock_via_class = Async::Event::Interval::_shm_lock();
    my $lock_expected  = 1 + ($$ % 32767);

    is $lock_via_obj,   $lock_expected, "_shm_lock() via object matches 1 + (\$\$ %% 32767)";
    is $lock_via_class, $lock_expected, "_shm_lock() via class matches 1 + (\$\$ %% 32767)";
    is $lock_via_obj,   $lock_via_class, "_shm_lock() returns the same value via either call form";

    cmp_ok $lock_via_obj, '>',  0;
    cmp_ok $lock_via_obj, '<=', 32767;
}

# The lock value is persisted in the SEM_PROTECTED semaphore slot of the
# AEI %events segment, and the in-memory `protected` attribute on the
# tied knot agrees with what _shm_lock() returns.

{
    my $e = $mod->new(0, sub {});

    my $expected_lock = $e->_shm_lock;

    my $register = IPC::Shareable::global_register();

    my $found_protected;

    for my $id (keys %$register) {
        my $knot      = $register->{$id};
        my $attr_prot = $knot->attributes('protected');

        next unless $attr_prot && $attr_prot == $expected_lock;

        $found_protected++;

        is
            $attr_prot,
            $expected_lock,
            "tied knot's in-memory 'protected' attribute equals _shm_lock()";

        my $sem_prot = $knot->sem->getval(SEM_PROTECTED);

        is
            $sem_prot,
            $expected_lock,
            "SEM_PROTECTED on the segment equals _shm_lock() (was silently truncated to 0 before the fix)";

        cmp_ok $sem_prot, '<=', 32767,
            "SEM_PROTECTED value is within the system semaphore range";
    }

    ok $found_protected,
        "at least one segment is marked protected with our lock value";
}

# A forked process inherits $shared_memory_protect_lock from the parent
# (it was captured at module load time, before the fork). The child's
# _shm_lock() must therefore equal the parent's, even though the child's
# $$ is different.

{
    my $parent_lock = Async::Event::Interval::_shm_lock();

    pipe my $rh, my $wh or die "pipe: $!";

    my $pid = fork;
    defined $pid or die "fork: $!";

    if ($pid == 0) {
        # child
        close $rh;
        print $wh Async::Event::Interval::_shm_lock(), "\n";
        close $wh;
        # Use _exit-style: avoid running END blocks in the child
        # (TestHelper guards against this, but be defensive).
        require POSIX;
        POSIX::_exit(0);
    }

    close $wh;
    chomp(my $child_lock = <$rh>);
    close $rh;
    waitpid $pid, 0;

    is
        $child_lock,
        $parent_lock,
        "forked child inherits the parent's _shm_lock() (captured at module load)";

    cmp_ok $child_lock, '>',  0;
    cmp_ok $child_lock, '<=', 32767;
}

# A second process started fresh (not via fork) generates its own lock
# value based on its own $$. We can verify the formula by simulating
# what such a process would compute.

{
    my $other_pid       = ($$ + 1) % (1 << 16);  # arbitrary different PID
    my $other_lock      = 1 + ($other_pid % 32767);

    cmp_ok $other_lock, '>',  0,     "fresh-process lock is > 0 for an arbitrary PID";
    cmp_ok $other_lock, '<=', 32767, "fresh-process lock is <= 32767 for an arbitrary PID";
}
