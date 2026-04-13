#!/usr/bin/env perl
# Barrier throughput benchmark: measures barrier round-trip time
use strict;
use warnings;
use Time::HiRes qw(time);
use POSIX qw(_exit);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $rounds = shift || 10_000;

sub bench {
    my ($label, $nprocs, $code) = @_;
    my $t0 = time;
    $code->();
    my $elapsed = time - $t0;
    printf "  %-40s %8.0f rounds/s  (%.3fs)\n",
        $label, $rounds / $elapsed, $elapsed;
}

print "Barrier benchmark, $rounds rounds:\n\n";

for my $nprocs (2, 3, 4, 8) {
    bench "$nprocs processes" => $nprocs, sub {
        my $bar = Data::Sync::Shared::Barrier->new(undef, $nprocs);

        my @pids;
        for my $p (1..$nprocs - 1) {
            my $pid = fork // die "fork: $!";
            if ($pid == 0) {
                $bar->wait for 1..$rounds;
                _exit(0);
            }
            push @pids, $pid;
        }

        # Parent is the last party
        $bar->wait for 1..$rounds;

        waitpid($_, 0) for @pids;
    };
}
