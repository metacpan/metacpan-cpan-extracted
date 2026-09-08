use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);

use Data::HashMap::Shared::II;

my $N = 8;
my $ITERS = 20;

# Without a barrier the first child's whole open finishes before the loop has
# spawned the last one -- measured, 0.15ms against 0.8ms to fork eight -- so
# only two or three of them ever overlap and the race is mostly not tested.
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

# A sharded set is the interesting case: 0.20 stamps the shard count into every
# shard header, and stamping the whole set after creating it left a window where
# shard 0 read stamped and shard k did not, so a second process starting at the
# same moment refused a sound set as "shards that disagree" about half the time.
# N workers starting together is the ordinary way a sharded set gets opened.
for my $shards (8, 64) {
    for my $iter (1 .. 5) {
        my $prefix = tmpnam() . ".sh$shards.$$.$iter";
        pipe(my $barrier_r, my $barrier_w) or die "pipe: $!";
        my @pids;
        for (1 .. $N) {
            my $pid = fork // die "fork: $!";
            if ($pid == 0) {
                close $barrier_w;
                <$barrier_r>;               # released together
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

# Two creators passing DIFFERENT counts must not both succeed: whoever claims
# shard 0's count first wins and the other is refused.  Stamping the whole set
# after the loop let both clear it while every shard still read 0, and they then
# stamped disjoint halves -- a set recording two counts, where the keys written
# to the losing half could never be read again.
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
