use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();

use Data::HashMap::Shared::II;

# A writer killed between the two halves of a publish leaves the seqlock odd
# and its pid in the lock word.  Lock-free readers wait for the holder, and a
# pid that answers kill(pid, 0) is a holder -- so once the kernel recycled that
# pid to the reading process, get, exists and cursors spun for ever: our own
# pid always answers.  Our own pid in the word is a dead writer by construction
# (t/61 makes the same case for the write path) unless another thread of ours
# holds the lock, and the seqlock's timeout recovery now treats it as one.
#
# Each probe runs in a child under a no-handler alarm: a regression is a
# signal death rather than a hung suite, since a Perl alarm cannot interrupt
# an XSUB.

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/ghost.shm";

sub in_child {
    my ($code) = @_;
    my $pid = fork // die "fork: $!";
    if (!$pid) { $SIG{ALRM} = 'DEFAULT'; alarm 8; eval { $code->() }; POSIX::_exit($@ ? 2 : 0) }
    waitpid $pid, 0;
    return ($? & 127) == 14 ? 'hung' : ($? >> 8) == 2 ? 'died' : 'ok';
}

sub fresh_map {
    unlink $path;
    my $m = Data::HashMap::Shared::II->new($path, 64);
    $m->put(1, 42);
}

# wlock (at 128) holds 0x80000000|pid while write-locked; seq (at 64) is odd
# while a writer is between its two publish halves.
sub stamp_writer_mid_publish {
    my ($pid) = @_;
    open my $fh, '+<:raw', $path or die $!;
    seek $fh, 128, 0 or die $!;
    print $fh pack 'L', 0x80000000 | $pid;
    seek $fh, 64, 0 or die $!;
    read $fh, my $raw, 4 or die "short read";
    seek $fh, 64, 0 or die $!;
    print $fh pack 'L', unpack('L', $raw) | 1;
    close $fh or die $!;
}

for my $arm (
    ['get',          sub { ($_[0]->get(1) // -1) == 42 or die "value lost\n" }],
    ['exists',       sub { $_[0]->exists(1) or die "entry lost\n" }],
    ['a cursor',     sub { my $c = $_[0]->cursor; defined $c->next or die "entry lost\n" }],
    ['keys',         sub { my @k = $_[0]->keys; @k == 1 or die "entry lost\n" }],
    ['get then put', sub { $_[0]->get(1); $_[0]->put(2, 43); ($_[0]->get(2) // -1) == 43 or die "value lost\n" }],
) {
    my ($what, $op) = @$arm;
    fresh_map();
    is in_child(sub {
        stamp_writer_mid_publish($$);
        my $m = Data::HashMap::Shared::II->new($path, 64);
        $op->($m);
    }), 'ok', "$what proceeds when the writer mid-publish is our own recycled pid";
}

# A live foreign writer mid-publish must still be waited for, not recovered.
fresh_map();
my $holder = fork // die "fork: $!";
if (!$holder) { select undef, undef, undef, 120; POSIX::_exit(0) }
stamp_writer_mid_publish($holder);
is in_child(sub {
    my $m = Data::HashMap::Shared::II->new($path, 64);
    $m->get(1);
}), 'hung', 'a live foreign writer mid-publish is still waited for';
kill 'KILL', $holder;
waitpid $holder, 0;

done_testing;
