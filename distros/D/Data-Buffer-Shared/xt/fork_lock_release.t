#!/usr/bin/perl
# Regression tests for two destroy-time lock defects:
#
# F1 (fork guard): a forked child inherits the handle's rd_held/wr_locked
# verbatim.  buf_close_map released whatever it found, so a child that never
# locked anything itself still dropped the PARENT's read contribution (slot
# rdepth) or write lock (wlock) on exit -- unlocking the parent's live
# critical section.  The close path must release only locks recorded by the
# calling process (cached_pid/cached_fork_gen), same guard as the slot
# release below it.
#
# F2 (orphaned seqlock): the close path released a held write lock with
# buf_rwlock_wrunlock only, never ending the seqlock write section, leaving
# hdr->seq odd forever.  Every seqlock bulk reader (slice/get_raw/Str get)
# then spins in its slow path with no recovery (wlock == 0, so stale-writer
# recovery never fires).  The release must mirror unlock_wr: seqlock end
# first, then wrunlock.
#
# Header words are checked directly against the on-disk layout (seq @ 64,
# wlock @ 68), the same technique t/12-dead-reader-recovery.t uses: the
# symptom of F2 IS the header state, so that is what we assert.  Lock
# contenders block inside XS (futex), which alarm cannot interrupt, so they
# run in children with a hard timeout from the parent.
use strict;
use warnings;
use Config;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(:sys_wait_h);
use Data::Buffer::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

my $dir = tempdir(CLEANUP => 1);

sub read_hdr_words {
    my ($path, $off, $n) = @_;
    open my $fh, '<:raw', $path or die "open $path: $!";
    sysseek($fh, $off, 0) or die "sysseek: $!";
    sysread($fh, my $buf, $n * 4) == $n * 4 or die "sysread: $!";
    return unpack "V$n", $buf;
}

# Returns 1 if $pid exited within $secs seconds (reaping it), 0 otherwise.
sub poll_exit {
    my ($pid, $secs) = @_;
    my $waited = 0;
    while ($waited < $secs) {
        return 1 if waitpid($pid, WNOHANG) == $pid;
        select undef, undef, undef, 0.1;
        $waited += 0.1;
    }
    return 0;
}

# ---- F2: destroy while holding lock_wr must not orphan the seqlock ----
{
    my $path = "$dir/f2.bin";

    my $b = Data::Buffer::Shared::I64->new($path, 16);
    $b->set(0, 111);
    $b->lock_wr;
    undef $b;    # destroyed while holding the write lock

    # The specific symptom: seq (offset 64) must be EVEN and wlock (68) 0.
    my ($seq, $wlock) = read_hdr_words($path, 64, 2);
    ok(($seq & 1) == 0, 'destroy with lock_wr held leaves seq even (no orphaned write section)');
    is($wlock, 0, 'destroy with lock_wr held clears wlock');

    # A seqlock bulk read in another process must complete, not spin on the
    # odd seq.  Without the fix this child hangs and is killed below.
    my $pid = fork();
    unless ($pid) {
        my $c = Data::Buffer::Shared::I64->new($path, 16);
        my @v = $c->slice(0, 1);
        exit(@v == 1 && $v[0] == 111 ? 0 : 2);
    }
    my $done = poll_exit($pid, 10);
    unless ($done) { kill 'KILL', $pid; waitpid($pid, 0) }
    ok($done && $? == 0, 'bulk read after destroy-with-lock_wr completes with the right value');
    unlink $path;
}

# ---- F1: a forked child's DESTROY must not release the parent's locks ----
for my $mode (qw(wr rd)) {
    my $path = "$dir/f1_$mode.bin";

    my $b = Data::Buffer::Shared::I64->new($path, 16);
    $mode eq 'wr' ? $b->lock_wr : $b->lock_rd;

    # Child inherits the handle and destroys it without ever locking.
    my $c1 = fork();
    unless ($c1) { undef $b; exit 0 }
    waitpid($c1, 0);

    if ($mode eq 'wr') {
        my ($wlock) = read_hdr_words($path, 68, 1);
        ok($wlock & 0x80000000, 'wlock still owned after forked child exit');
    }

    # A contender for the write lock must stay blocked while the parent
    # still holds its lock...
    my $c2 = fork();
    unless ($c2) {
        my $h = Data::Buffer::Shared::I64->new($path, 16);
        $h->lock_wr;
        $h->unlock_wr;
        exit 0;
    }
    my $early = poll_exit($c2, 3);
    ok(!$early, "writer contender still blocked after forked child exit (parent's $mode-lock intact)");

    # ...and must proceed once the parent unlocks.
    $mode eq 'wr' ? $b->unlock_wr : $b->unlock_rd;
    my $late = !$early && poll_exit($c2, 10);
    unless ($late) { kill 'KILL', $c2; waitpid($c2, 0) }
    ok($late && $? == 0, 'contender acquires the lock once the parent unlocks');
    unlink $path;
}

done_testing;
