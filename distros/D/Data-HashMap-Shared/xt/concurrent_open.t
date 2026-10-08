use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);

use Data::HashMap::Shared::II;

my $N = 8;
my $ITERS = 20;

# The barrier makes the children open together: without it the first open
# finishes before the last fork (0.15ms against 0.8ms), and the race is mostly
# not tested.
for my $iter (1..$ITERS) {
    my $path = tmpnam() . ".$$.$iter";
    pipe(my $barrier_r, my $barrier_w) or die "pipe: $!";
    my @pids;
    for (1..$N) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            close $barrier_w;
            <$barrier_r>;
            my $ok = eval {
                my $m = Data::HashMap::Shared::II->new($path, 1024);
                1;
            };
            _exit($ok ? 0 : 1);
        }
        push @pids, $pid;
    }
    close $barrier_r;
    close $barrier_w;
    my @fails;
    for my $pid (@pids) {
        waitpid $pid, 0;
        push @fails, $pid if $? != 0;
    }
    unlink $path;
    is scalar(@fails), 0, "iter $iter: $N procs race open, all succeed"
        or diag "failed pids: @fails";
}

# A sharded set stamps its shard count into every shard header: a process
# starting mid-stamp must not refuse a sound set as "shards that disagree".
for my $shards (8, 64) {
    for my $iter (1 .. 5) {
        my $prefix = tmpnam() . ".sh$shards.$$.$iter";
        pipe(my $barrier_r, my $barrier_w) or die "pipe: $!";
        my @pids;
        for (1 .. $N) {
            my $pid = fork // die "fork: $!";
            if ($pid == 0) {
                close $barrier_w;
                <$barrier_r>;
                my $ok = eval {
                    Data::HashMap::Shared::II->new_sharded($prefix, $shards, 4096);
                    1;
                };
                _exit($ok ? 0 : 1);
            }
            push @pids, $pid;
        }
        close $barrier_r;
        close $barrier_w;
        my @fails;
        for my $pid (@pids) {
            waitpid $pid, 0;
            push @fails, $pid if $?;
        }
        unlink glob "$prefix.*";
        is scalar(@fails), 0,
            "$shards shards, iter $iter: $N procs race first open, all succeed"
            or diag "failed pids: @fails";
    }
}

# Two creators passing different counts must not both succeed: whoever claims
# shard 0's count first wins and the other is refused.
for my $iter (1 .. 10) {
    my $prefix = tmpnam() . ".race.$$.$iter";
    pipe(my $barrier_r, my $barrier_w) or die "pipe: $!";
    my @pids;
    for my $shards (8, 16) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            close $barrier_w;
            <$barrier_r>;
            my $ok = eval {
                my $m = Data::HashMap::Shared::II->new_sharded($prefix, $shards, 4096);
                $m->put($_, $_) for 1 .. 100;
                1;
            };
            _exit($ok ? 0 : 1);
        }
        push @pids, $pid;
    }
    close $barrier_r;
    close $barrier_w;
    my $winners = 0;
    for my $pid (@pids) { waitpid $pid, 0; $winners++ unless $? }
    is $winners, 1, "iter $iter: exactly one of two different shard counts wins";

    my %recorded;
    for my $shard (glob "$prefix.*") {
        open my $sh, '<', $shard or die "$shard: $!";
        sysseek $sh, 98, 0;
        sysread $sh, my $byte, 1;
        close $sh;
        my $log2 = unpack 'C', $byte;
        $recorded{$log2}++ if $log2;
    }
    is scalar(keys %recorded), 1, "  ... and the set records exactly one count";
    unlink glob "$prefix.*";
}

done_testing;
