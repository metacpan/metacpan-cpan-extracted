#!/usr/bin/env perl
# Benchmark: cross-process throughput (readers vs writers vs mixed)
use strict;
use warnings;
use Time::HiRes qw(time);
use POSIX qw(_exit);

use Data::Buffer::Shared::I64;

my $n = $ARGV[0] || 500_000;
my $cap = 10_000;
my $nprocs = $ARGV[1] || 2;

sub bench_fork {
    my ($label, $code) = @_;
    my $buf = Data::Buffer::Shared::I64->new_anon($cap);
    $buf->fill(1);

    my $t0 = time();
    my @pids;
    for (1..$nprocs) {
        my $pid = fork();
        if ($pid == 0) {
            $code->($buf);
            _exit(0);
        }
        push @pids, $pid;
    }
    waitpid($_, 0) for @pids;
    my $elapsed = time() - $t0;
    my $total = $n * $nprocs;
    printf "%-35s %10.0f ops/sec  (%d procs, %.3fs)\n",
        $label, $total / $elapsed, $nprocs, $elapsed;
}

printf "=== Cross-process benchmark (%d procs, %d ops/proc, %d elements) ===\n\n",
    $nprocs, $n, $cap;

bench_fork "reads only (atomic get)" => sub {
    my $buf = shift;
    my $v;
    for my $i (1..$n) { $v = $buf->get($i % $cap) }
};

bench_fork "writes only (atomic set)" => sub {
    my $buf = shift;
    for my $i (1..$n) { $buf->set($i % $cap, $i) }
};

bench_fork "atomic incr" => sub {
    my $buf = shift;
    for my $i (1..$n) { $buf->incr($i % $cap) }
};

bench_fork "mixed read/write 50/50" => sub {
    my $buf = shift;
    my $v;
    for my $i (1..$n) {
        if ($i & 1) { $v = $buf->get($i % $cap) }
        else        { $buf->set($i % $cap, $i) }
    }
};

bench_fork "slice(100) reads" => sub {
    my $buf = shift;
    my $m = int($n / 100);
    for (1..$m) { my @v = $buf->slice(0, 100) }
};

bench_fork "get_raw(800B) reads" => sub {
    my $buf = shift;
    my $m = int($n / 100);
    for (1..$m) { my $r = $buf->get_raw(0, 800) }
};
