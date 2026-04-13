use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Config;

use Data::Sync::Shared;

my $perl = $Config{perlpath};

# ============================================================
# File-backed state survives across independent processes
#
# We create a file-backed primitive, modify its state, msync,
# then exec a fresh perl process to reopen and verify state.
# ============================================================

# 1. Semaphore: state persists
{
    my $path = tmpnam() . '.shm';
    my $sem = Data::Sync::Shared::Semaphore->new($path, 10, 10);
    $sem->try_acquire for 1..3;
    is $sem->value, 7, 'parent: sem value 7';
    $sem->sync;

    my $out = `$perl -Mblib -MData::Sync::Shared -e '
        my \$s = Data::Sync::Shared::Semaphore->new("\Q$path\E", 10);
        print \$s->value, "\\n";
        print \$s->max, "\\n";
    ' 2>&1`;
    chomp $out;
    my @lines = split /\n/, $out;
    is $lines[0], '7', 'child process: sem value persisted (7)';
    is $lines[1], '10', 'child process: sem max persisted (10)';
    unlink $path;
}

# 2. RWLock: unlocked state persists (no lock held across exec)
{
    my $path = tmpnam() . '.shm';
    my $rw = Data::Sync::Shared::RWLock->new($path);
    $rw->wrlock;
    $rw->wrunlock;
    $rw->sync;

    my $out = `$perl -Mblib -MData::Sync::Shared -e '
        my \$rw = Data::Sync::Shared::RWLock->new("\Q$path\E");
        my \$s = \$rw->stats;
        print \$s->{state}, "\\n";
        print \$s->{acquires}, "\\n";
    ' 2>&1`;
    chomp $out;
    my @lines = split /\n/, $out;
    is $lines[0], 'unlocked', 'child: rwlock state persisted (unlocked)';
    ok $lines[1] > 0, 'child: rwlock acquires counter persisted';
    unlink $path;
}

# 3. Once: done state persists
{
    my $path = tmpnam() . '.shm';
    my $once = Data::Sync::Shared::Once->new($path);
    $once->enter;
    $once->done;
    $once->sync;

    my $out = `$perl -Mblib -MData::Sync::Shared -e '
        my \$o = Data::Sync::Shared::Once->new("\Q$path\E");
        print \$o->is_done ? "done" : "not_done", "\\n";
        print \$o->enter ? "init" : "waited", "\\n";
    ' 2>&1`;
    chomp $out;
    my @lines = split /\n/, $out;
    is $lines[0], 'done', 'child: once is_done persisted';
    is $lines[1], 'waited', 'child: enter returns false (already done)';
    unlink $path;
}

# 4. Barrier: generation persists
{
    my $path = tmpnam() . '.shm';
    my $bar = Data::Sync::Shared::Barrier->new($path, 2);
    # trip the barrier manually by reset (bumps generation)
    $bar->reset;
    $bar->reset;
    $bar->reset;
    $bar->sync;

    my $out = `$perl -Mblib -MData::Sync::Shared -e '
        my \$b = Data::Sync::Shared::Barrier->new("\Q$path\E", 2);
        print \$b->generation, "\\n";
        print \$b->parties, "\\n";
    ' 2>&1`;
    chomp $out;
    my @lines = split /\n/, $out;
    is $lines[0], '3', 'child: barrier generation persisted (3)';
    is $lines[1], '2', 'child: barrier parties persisted (2)';
    unlink $path;
}

# 5. Condvar: stats persist
{
    my $path = tmpnam() . '.shm';
    my $cv = Data::Sync::Shared::Condvar->new($path);
    $cv->lock;
    $cv->signal;
    $cv->signal;
    $cv->signal;
    $cv->unlock;
    $cv->sync;

    my $out = `$perl -Mblib -MData::Sync::Shared -e '
        my \$c = Data::Sync::Shared::Condvar->new("\Q$path\E");
        my \$s = \$c->stats;
        print \$s->{signals}, "\\n";
    ' 2>&1`;
    chomp $out;
    is $out, '3', 'child: condvar signal count persisted (3)';
    unlink $path;
}

done_testing;
