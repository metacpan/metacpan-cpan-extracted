#!/usr/bin/env perl
# plan_clamav_clamd phase 0 - what does the N+1th caller experience?
#
# MaxThreads bounds clamd's scanning concurrency and MaxQueue bounds what
# waits behind it. A Punk worker blocked here is a request holding a
# connection, so the question is not "how fast is clamd" but what happens
# to the caller who arrives when every thread is busy: served late,
# refused, or dropped.
use strict;
use warnings;
use Time::HiRes qw(time);

my $target = shift or die "usage: $0 FILE|DIR [N ...]\n";
my @levels = @ARGV ? @ARGV : (1, 5, 10, 20, 40);

# clamd caches clean verdicts by content hash (CacheSize entries), so
# scanning one file N times measures the cache, not the thread pool.
# A directory gives every concurrent scan distinct content.
my @files = -d $target ? sort glob("$target/*") : ($target);
die "no files in $target\n" unless @files;
my $probe = './dev/fildes_probe';
die "build $probe first\n" unless -x $probe;

# NB: the parameter must not be called $a or $b - a lexical of either
# name shadows the sort variables and the comparison silently degrades.
sub pct { my ($vals, $p) = @_; my @s = sort { $a <=> $b } @$vals;
          return $s[ int($p / 100 * $#s + 0.5) ] }

printf "%-5s %-9s %-9s %-9s %-9s %-9s %s\n",
    'N', 'wall', 'median', 'p95', 'max', 'per-scan', 'verdicts';

# A global cursor, not a per-rung one: a file scanned at N=5 is in the
# clean cache when N=10 comes round, and a cached rung reports the cache
# rather than the pool.
my $cursor = 0;

for my $n (@levels) {
    my (@pids, %pipe);
    if ($cursor + $n > @files) {
        printf "%-5d SKIPPED - needs %d unscanned files, %d left\n",
            $n, $n, @files - $cursor;
        next;
    }
    my $t0 = time;
    for my $i (1 .. $n) {
        pipe(my $r, my $w) or die "pipe: $!";
        my $file = $files[ $cursor++ ];
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            # Child: close the read end and, critically, do not let the
            # parent's buffered handles leak into the measurement.
            close $r;
            my $s = time;
            my $out = qx{$probe "$file" 2>&1};
            my $e = time;
            chomp $out;
            $out =~ s/.*reply=//s;
            $out =~ s/\\0$//;
            $out =~ s/^fd\[\d+\]:\s*//;
            printf {$w} "%.4f\t%s\n", $e - $s, $out;
            close $w;
            exit 0;
        }
        close $w;
        $pipe{$pid} = $r;
        push @pids, $pid;
    }

    my (@times, %verdict);
    for my $pid (@pids) {
        my $fh = $pipe{$pid};
        my $line = <$fh>;
        close $fh;
        waitpid($pid, 0);
        next unless defined $line;
        chomp $line;
        my ($t, $v) = split /\t/, $line, 2;
        push @times, $t;
        $verdict{ $v // '<none>' }++;
    }
    my $wall = time - $t0;
    next unless @times;

    my $sum = 0; $sum += $_ for @times;
    printf "%-5d %-9.3f %-9.3f %-9.3f %-9.3f %-9.3f %s\n",
        $n, $wall, pct(\@times, 50), pct(\@times, 95),
        (sort { $a <=> $b } @times)[-1], $sum / @times,
        join(', ', map { "$_ x$verdict{$_}" } sort keys %verdict);
}
