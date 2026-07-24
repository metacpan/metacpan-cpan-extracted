#!/usr/bin/perl
# Regression: destroying a handle that still holds a lock must not strand it.
#
# buf_close_map released the process's reader slot only when rdepth == 0, and
# never released a held write lock. So `$b->lock_rd; undef $b;` left the slot
# pinned with a LIVE pid and rdepth > 0 -- and because that pid is alive,
# dead-owner recovery never fires, so every other process's lock_wr starved
# until this process exited.
#
# rdepth is per-process and shared by all handles, so the handle now tracks how
# much of it IT owns (rd_held) and releases exactly that on close.
#
# The waiting writer blocks inside XS (futex), which Perl's alarm cannot
# interrupt, so it runs in a child with a hard timeout from the parent.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(:sys_wait_h);
use Data::Buffer::Shared;

plan skip_all => 'fork required' unless $Config::Config{d_fork};

my $dir = tempdir(CLEANUP => 1);

for my $mode (qw(rd wr)) {
    my $path = "$dir/leak_$mode.bin";
    unlink $path;

    my $h1 = Data::Buffer::Shared::I64->new($path, 16);
    $mode eq 'rd' ? $h1->lock_rd : $h1->lock_wr;
    undef $h1;                       # destroyed while still holding the lock

    my $pid = fork();
    unless ($pid) {
        my $h2 = Data::Buffer::Shared::I64->new($path, 16);
        $h2->lock_wr;
        $h2->unlock_wr;
        exit 0;
    }

    my ($waited, $done) = (0, 0);
    while ($waited < 10) {
        if (waitpid($pid, WNOHANG) == $pid) { $done = 1; last }
        select undef, undef, undef, 0.2;
        $waited += 0.2;
    }
    unless ($done) { kill 'KILL', $pid; waitpid($pid, 0) }

    ok $done, "a later writer is not starved by a handle destroyed holding a $mode-lock";
    unlink $path;
}

done_testing;
