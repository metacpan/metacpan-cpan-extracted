use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use POSIX ();

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'shm_fork') . '.shm' }

# Concurrent CAS: many workers race to flip a value 0 → 1. Exactly one wins.
{
    my $path = tmpfile();
    my $parent = Data::HashMap::Shared::II->new($path, 100);
    $parent->put(0, 0);   # the contested cell

    my $N = 8;
    my @pids;
    for my $i (1..$N) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            my $child = Data::HashMap::Shared::II->new($path, 100);
            my $won = $child->cas(0, 0, $i) ? 1 : 0;
            POSIX::_exit($won);  # exit status = whether this worker won
        }
        push @pids, $pid;
    }
    my $wins = 0;
    for my $pid (@pids) {
        waitpid($pid, 0);
        $wins += ($? >> 8);
    }
    is($wins, 1, "concurrent CAS: exactly 1 winner across $N workers");
    my $final = $parent->get(0);
    ok($final >= 1 && $final <= $N, "CAS winner stored a valid worker id ($final)");
    unlink $path;
}

# Concurrent add: only first worker per key inserts; others see add fail.
{
    my $path = tmpfile();
    my $N = 6;
    my @pids;
    for my $i (1..$N) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            my $child = Data::HashMap::Shared::II->new($path, 100);
            my $inserted = $child->add(42, $i) ? 1 : 0;
            POSIX::_exit($inserted);
        }
        push @pids, $pid;
    }
    my $inserts = 0;
    for my $pid (@pids) { waitpid($pid, 0); $inserts += ($? >> 8) }
    is($inserts, 1, "concurrent add: exactly 1 insert across $N workers");
    unlink $path;
}

# Concurrent incr: sum visible to parent equals N
{
    my $path = tmpfile();
    my $parent = Data::HashMap::Shared::II->new($path, 100);
    my $N = 20;
    my @pids;
    for my $i (1..$N) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            my $child = Data::HashMap::Shared::II->new($path, 100);
            $child->incr(1);
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }
    waitpid($_, 0) for @pids;
    is($parent->get(1), $N, "concurrent incr: parent sees $N");
    unlink $path;
}

# Concurrent cas_take: only one process gets the value
{
    my $path = tmpfile();
    my $parent = Data::HashMap::Shared::SS->new($path, 100);
    $parent->put("token", "secret");
    my $N = 5;
    my @pids;
    for (1..$N) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            my $child = Data::HashMap::Shared::SS->new($path, 100);
            my $got = $child->cas_take("token", "secret");
            POSIX::_exit(defined $got ? 1 : 0);
        }
        push @pids, $pid;
    }
    my $wins = 0;
    for my $pid (@pids) { waitpid($pid, 0); $wins += ($? >> 8) }
    is($wins, 1, "concurrent cas_take: exactly 1 worker claimed the token");
    ok(!$parent->exists("token"), "cas_take: token removed");
    unlink $path;
}

done_testing;
