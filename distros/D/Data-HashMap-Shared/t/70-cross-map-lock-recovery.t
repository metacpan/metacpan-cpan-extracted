use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();

# A batch method's argument is a tied scalar or overloaded object whose FETCH
# touches another Data::HashMap::Shared map -- a common shape (a tied value that
# reads a second shared map).  Its FETCH runs before this map's lock is taken,
# so it neither deadlocks this map nor is blocked by it: it can write a second
# map, and can recover that second map's own stale lock (a dead writer whose pid
# was recycled to us), exactly as a call with no batch in progress would.  A
# genuinely foreign live holder of the second map is still waited for.
#
# Each probe runs in a child under a no-handler alarm: a regression (a wedged
# map) is a signal death rather than a hung suite, since a Perl alarm cannot
# interrupt an XSUB spinning in C.

my $dir = tempdir(CLEANUP => 1);
my ($A, $B) = ("$dir/a.shm", "$dir/b.shm");

sub in_child {
    my ($code) = @_;
    my $pid = fork // die "fork: $!";
    if (!$pid) { $SIG{ALRM} = 'DEFAULT'; alarm 8; eval { $code->() }; POSIX::_exit($@ ? 2 : 0) }
    waitpid $pid, 0;
    return ($? & 127) == 14 ? 'hung' : ($? >> 8) == 2 ? 'died' : 'ok';
}

sub fresh {
    unlink $A, $B;
    Data::HashMap::Shared::II->new($A, 64)->put(1, 1);
    Data::HashMap::Shared::II->new($B, 64)->put(1, 42);
}

# wlock at 128 holds 0x80000000|pid while write-locked; seq at 64 is odd while a
# writer sits between the two halves of a publish.
sub stamp {
    my ($path, $pid, $odd) = @_;
    open my $fh, '+<:raw', $path or die $!;
    seek $fh, 128, 0 or die $!;
    print $fh pack 'L', 0x80000000 | $pid;
    if ($odd) {
        seek $fh, 64, 0 or die $!;
        read $fh, my $raw, 4 or die "short read";
        seek $fh, 64, 0 or die $!;
        print $fh pack 'L', unpack('L', $raw) | 1;
    }
    close $fh or die $!;
}

use Data::HashMap::Shared::II;

{
    package FetchRuns;
    sub TIESCALAR { my ($class, $code) = @_; bless { code => $code, ran => 0 }, $class }
    sub FETCH { my $s = shift; $s->{ran}++ ? 2 : do { $s->{code}->(); 1 } }
}

# $code runs from a batch argument's FETCH, i.e. before set_multi's lock.
sub via_batch_fetch {
    my ($code) = @_;
    my $m = Data::HashMap::Shared::II->new($A, 64);
    tie my $tied, 'FetchRuns', $code;
    $m->set_multi(2 => $tied);
}

for my $arm (
    ['a write', sub {
        my $b = Data::HashMap::Shared::II->new($B, 64);
        $b->put(2, 7);
        ($b->get(2) // -1) == 7 or die "value lost\n";
    }, 0],
    ['a lock-free read', sub {
        my $b = Data::HashMap::Shared::II->new($B, 64);
        ($b->get(1) // -1) == 42 or die "value lost\n";
    }, 1],
) {
    my ($what, $on_b, $odd) = @$arm;
    fresh();
    is in_child(sub {
        stamp($B, $$, $odd);
        via_batch_fetch($on_b);
    }), 'ok', "$what on a second map from a batch FETCH recovers that map's own stale lock";

    # Control: the same operation with no batch in progress must also pass, or
    # the arm above proves nothing about the second map's own recovery.
    fresh();
    is in_child(sub { stamp($B, $$, $odd); $on_b->() }), 'ok',
        "  ... and still does called directly";
}

# A second handle onto the SAME map, written from a batch argument's FETCH, runs
# before the lock too: it completes and its write lands, instead of the pre-fix
# self-deadlock (t/79 sweeps every variant and method).
fresh();
is in_child(sub {
    my $inner = Data::HashMap::Shared::II->new($A, 64);
    via_batch_fetch(sub { $inner->put(3, 9) });
    ($inner->get(3) // -1) == 9 or die "re-entrant write lost\n";
}), 'ok', 'a re-entrant write from a batch FETCH runs before the lock and takes effect';

# A genuinely foreign live holder of the second map is still waited for, not
# recovered.
fresh();
my $holder = fork // die "fork: $!";
if (!$holder) { select undef, undef, undef, 120; POSIX::_exit(0) }
stamp($B, $holder, 0);
is in_child(sub {
    my $b = Data::HashMap::Shared::II->new($B, 64);
    $b->put(2, 7);
}), 'hung', 'a live foreign holder of the second map is still waited for';
kill 'KILL', $holder;
waitpid $holder, 0;

done_testing;
