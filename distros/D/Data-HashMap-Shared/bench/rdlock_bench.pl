#!/usr/bin/env perl
# Focused incr_by benchmark: measures the lock-free fast path that is hottest
# in the bidder workload. Runs single-process and multi-process variants.

use strict;
use warnings;
use POSIX ();
use Time::HiRes qw(time);
use File::Temp ();
use Getopt::Long;
use Data::HashMap::Shared::SI;

my $duration  = 3;
my $workers   = 4;
my $key_range = 256;

GetOptions(
    'duration=f' => \$duration,
    'workers=i'  => \$workers,
    'keys=i'     => \$key_range,
);

sub fmt { my $n = reverse $_[0]; $n =~ s/(\d{3})(?=\d)/$1,/g; scalar reverse $n }

sub run_workers {
    my ($label, $n, $work) = @_;
    my @pids;
    my @pipes;
    for my $w (0 .. $n - 1) {
        pipe(my $rd, my $wr) or die "pipe: $!";
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            close $rd;
            srand($w * 100 + $$);
            my $ops = $work->($w);
            print $wr "$ops\n";
            close $wr;
            POSIX::_exit(0);
        }
        close $wr;
        push @pids, $pid;
        push @pipes, $rd;
    }
    my $total = 0;
    for my $rd (@pipes) {
        chomp(my $line = <$rd> // 0);
        $total += $line;
        close $rd;
    }
    waitpid($_, 0) for @pids;
    printf "%-32s %s ops/sec across %d workers (%s ops total)\n",
        $label, fmt(int($total / $duration)), $n, fmt($total);
}

sub bench_incr_by {
    my ($n_workers) = @_;
    my $tmp = File::Temp::tempnam(File::Temp::tempdir(CLEANUP => 1), 'bench');
    my $m = Data::HashMap::Shared::SI->new($tmp . ".shm", 100_000);
    # Pre-populate keys to exercise the existing-key lock-free fast path
    $m->put("k$_", 0) for 1 .. $key_range;
    my $end = time + $duration;
    run_workers(sprintf('SI incr_by (%d procs)', $n_workers), $n_workers, sub {
        my $w = shift;
        my $c = Data::HashMap::Shared::SI->new($tmp . ".shm", 100_000);
        my $ops = 0;
        while (time < $end) {
            for (1..1000) {
                $c->incr_by('k' . (int(rand($key_range)) + 1), 1);
                $ops++;
            }
        }
        return $ops;
    });
}

print "Benchmark: incr_by on existing key (lock-free fast path)\n";
print "Duration: ${duration}s, key range: $key_range\n\n";
bench_incr_by(1);
bench_incr_by(4);
bench_incr_by(16);
bench_incr_by(64) if $workers >= 64;
