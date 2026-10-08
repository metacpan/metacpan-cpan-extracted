use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();

# A batch argument whose FETCH touches a second map runs before this map's lock,
# so it neither deadlocks nor is blocked: it can write the second map and
# recover that map's own stale lock (a dead writer's pid recycled to us); a live
# foreign holder is still waited for. Each probe runs in a child under a
# no-handler alarm (a Perl alarm cannot interrupt an XSUB spinning in C), so a
# wedged map is a signal death rather than a hung suite.

my $dir = tempdir(CLEANUP => 1);
my ($A, $B) = ("$dir/a.shm", "$dir/b.shm");

sub in_child {
    my ($code) = @_;
    my $pid = fork // die "fork: $!";
    if (!$pid) { $SIG{ALRM} = 'DEFAULT'; alarm 8; eval { $code->() }; POSIX::_exit($@ ? 2 : 0) }
    waitpid $pid, 0;
    return ($? & 127) == 14 ? 'hung' : $? & 127 ? 'signal' : ($? >> 8) == 2 ? 'died' : 'ok';
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

    # control: without it the arm above proves nothing about the second map's
    # own recovery
    fresh();
    is in_child(sub { stamp($B, $$, $odd); $on_b->() }), 'ok',
        "  ... and still does called directly";
}

fresh();
is in_child(sub {
    my $inner = Data::HashMap::Shared::II->new($A, 64);
    via_batch_fetch(sub { $inner->put(3, 9) });
    ($inner->get(3) // -1) == 9 or die "re-entrant write lost\n";
}), 'ok', 'a re-entrant write from a batch FETCH runs before the lock and takes effect';

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
