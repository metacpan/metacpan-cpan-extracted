#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use Data::PubSub::Shared;

my $N = shift || 500_000;

sub rate { sprintf "%.1fM/s", $_[0] / $_[1] / 1e6 }

print "Data::PubSub::Shared fan-out benchmark ($N items)\n";
print "Measuring publish throughput with 1..N subscribers\n\n";

for my $n_subs (0, 1, 2, 4, 8, 16) {
    my $cap = $N < 1048576 ? 1048576 : $N;
    my $ps = Data::PubSub::Shared::Int->new(undef, $cap);
    my @subs;
    for (1..$n_subs) {
        push @subs, $ps->subscribe;
    }

    my $t0 = time;
    for my $i (1..$N) {
        $ps->publish($i);
    }
    my $dt = time - $t0;

    my $ok = 1;
    for my $sub (@subs) {
        my @got = $sub->drain;
        $ok = 0 if @got != $N;
    }

    printf "  %2d subscribers: publish %s  drain %s\n",
        $n_subs, rate($N, $dt), $ok ? "OK" : "FAIL";
}

print "\nCross-process fan-out:\n";

for my $n_subs (1, 2, 4) {
    my $path = "/tmp/pubsub_bench_fanout_$$";
    my $cap = $N < 1048576 ? 1048576 : $N;
    my $ps = Data::PubSub::Shared::Int->new($path, $cap);

    my @pids;
    for my $s (1..$n_subs) {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            my $child = Data::PubSub::Shared::Int->new($path, $cap);
            my $sub = $child->subscribe;
            my $count = 0;
            while ($count < $N) {
                my $v = $sub->poll_wait(5);
                $count++ if defined $v;
            }
            exit 0;
        }
        push @pids, $pid;
    }

    select(undef, undef, undef, 0.1);

    my $t0 = time;
    for my $i (1..$N) { $ps->publish($i) }
    my $dt = time - $t0;

    for my $pid (@pids) { waitpid($pid, 0) }

    printf "  %2d child subscribers: publish %s\n", $n_subs, rate($N, $dt);
    unlink $path;
}

print "\nDone.\n";
