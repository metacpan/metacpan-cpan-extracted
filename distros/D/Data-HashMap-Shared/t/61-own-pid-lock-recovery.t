use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

# A dead writer's pid stays in the lock word.  Recycled to the process now
# attaching, it answers kill(pid, 0), so no recovery fires and the map
# deadlocks.  Our own pid there is a ghost unless a thread of ours holds this
# map, which its hold count says.
#
# The probe runs in a child under a no-handler alarm: a regression is a signal
# death rather than a hung suite, since a Perl alarm cannot interrupt an XSUB.

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/ownpid.shm";
{ my $m = Data::HashMap::Shared::II->new($path, 64); $m->put(1, 42) }

sub in_child {
    my ($code) = @_;
    my $pid = fork // die "fork: $!";
    if (!$pid) { $SIG{ALRM} = 'DEFAULT'; alarm 8; eval { $code->() }; POSIX::_exit($@ ? 2 : 0) }
    waitpid $pid, 0;
    return ($? & 127) == 14 ? 'hung' : ($? >> 8) == 2 ? 'died' : 'ok';
}

# wlock holds 0x80000000|pid when write-locked; the child stamps its own pid
# there, exactly as a recycled pid would appear to it.
is in_child(sub {
    open my $fh, '+<:raw', $path or die $!;
    seek $fh, 128, 0 or die $!;
    print $fh pack 'L', 0x80000000 | $$;
    close $fh or die $!;
    my $m = Data::HashMap::Shared::II->new($path, 64);
    $m->put(2, 43);
    die "value lost\n" unless ($m->get(2) // -1) == 43;
}), 'ok', 'a write proceeds when the lock word holds our own recycled pid';

# a genuinely foreign live holder must still block rather than be stolen
{ my $m = Data::HashMap::Shared::II->new($path, 64); $m->put(3, 44) }
# The holder must outlive the probe's alarm by a wide margin.  At 6s against an
# 8s alarm the verdict turned on which came first, the alarm or the recovery at
# the first 2s futex expiry after the holder exited -- a coin flip on a loaded
# machine.  It is killed the moment the probe returns, so a long sleep is free.
my $holder = fork // die "fork: $!";
if (!$holder) { select undef, undef, undef, 120; POSIX::_exit(0) }
{
    open my $fh, '+<:raw', $path or die $!;
    seek $fh, 128, 0 or die $!;
    print $fh pack 'L', 0x80000000 | $holder;
    close $fh or die $!;
}
is in_child(sub {
    my $m = Data::HashMap::Shared::II->new($path, 64);
    $m->put(4, 45);
}), 'hung', 'a live foreign holder is still waited for, not recovered';
kill 'KILL', $holder;
waitpid $holder, 0;

# Batch methods materialize every argument before taking the lock, so a tied
# argument whose FETCH re-enters the same map -- even through a second handle --
# runs before the lock, not under it.  It completes instead of self-deadlocking
# the map, and its re-entrant write takes effect.  t/79 sweeps every variant and
# method; here it also confirms the own-pid machinery is never reached for it.
{
    my $rpath = "$dir/reentrant.shm";
    my $A = Data::HashMap::Shared::SS->new($rpath, 256);
    my $B = Data::HashMap::Shared::SS->new($rpath, 256);
    $A->put(seed => 'ok');

    my $entered = 0;
    {
        package ReenterOnFetch;
        sub TIESCALAR { bless {}, shift }
        sub FETCH { $entered++ ? 'plain' : do { $B->put(inner => 'written'); 'outer' } }
    }
    is in_child(sub {
        tie my $tied, 'ReenterOnFetch';
        $A->set_multi(outer => $tied);
    }), 'ok', 'a re-entrant batch argument runs before the lock, not under it (no deadlock)';

    # Read it back from a child: the re-entrant write and the outer store both
    # landed, and a regression (a wedged map) fails here instead of hanging.
    is in_child(sub {
        my $C = Data::HashMap::Shared::SS->new($rpath, 256);
        die "inner not written\n" unless ($C->get('inner') // '') eq 'written';
        die "outer not stored\n"  unless ($C->get('outer') // '') eq 'outer';
        die "seed lost\n"         unless ($C->get('seed')  // '') eq 'ok';
    }), 'ok', '  ... the re-entrant write and the batch store both took effect';
}

done_testing;
