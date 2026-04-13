#!/usr/bin/env perl
# Multi-process benchmark: concurrent alloc/free throughput under contention

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use POSIX qw(_exit);
use Data::Pool::Shared;

my $WORKERS  = shift || 8;
my $OPS      = shift || 200_000;
my $CAPACITY = shift || 64;

printf "Data::Pool::Shared multi-process benchmark\n";
printf "  workers=%d  ops=%d  capacity=%d\n\n", $WORKERS, $OPS, $CAPACITY;

sub run_bench {
    my ($label, $pool, $worker_code) = @_;
    $pool->reset;

    my $t0 = time;
    my @pids;
    for my $w (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            $worker_code->($pool, $w);
            _exit(0);
        }
        push @pids, $pid;
    }

    my $fails = 0;
    waitpid($_, 0), $fails += ($? >> 8) != 0 for @pids;
    my $dt = time - $t0;

    my $total = $WORKERS * $OPS;
    my $s = $pool->stats;
    printf "  %-45s %10.0f/s  (%.3fs)  waits=%d\n",
        $label, $total / $dt, $dt, $s->{waits};
    warn "  WARNING: $fails workers failed\n" if $fails;
}

# --- I64: alloc/free cycle (high contention) ---

my $i64 = Data::Pool::Shared::I64->new(undef, $CAPACITY);

run_bench "I64 alloc/free" => $i64, sub {
    my ($p, $w) = @_;
    for (1..$OPS) {
        my $s = $p->alloc(1.0);
        next unless defined $s;
        $p->set($s, $$);
        $p->free($s);
    }
};

# --- I64: alloc/set/get/free ---

run_bench "I64 alloc/set/get/free" => $i64, sub {
    my ($p, $w) = @_;
    for (1..$OPS) {
        my $s = $p->alloc(1.0);
        next unless defined $s;
        $p->set($s, $_);
        my $v = $p->get($s);
        $p->free($s);
    }
};

# --- I64: atomic add on pre-allocated slots ---

{
    $i64->reset;
    my $nslots = $CAPACITY < 16 ? $CAPACITY : 16;
    my @shared;
    for (1..$nslots) {
        my $s = $i64->alloc;
        $i64->set($s, 0);
        push @shared, $s;
    }

    my $t0 = time;
    my @pids;
    for my $w (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            for (1..$OPS) {
                $i64->add($shared[$_ % $nslots], 1);
            }
            _exit(0);
        }
        push @pids, $pid;
    }
    waitpid($_, 0) for @pids;
    my $dt = time - $t0;

    my $total_ops = $WORKERS * $OPS;
    printf "  %-45s %10.0f/s  (%.3fs)\n",
        "I64 atomic add ($nslots slots)", $total_ops / $dt, $dt;

    my $total = 0;
    $total += $i64->get($_) for @shared;
    printf "    verify: sum=%d expected=%d %s\n",
        $total, $total_ops, $total == $total_ops ? "ok" : "MISMATCH";
}

# --- Str: alloc/set/get/free ---

print "\n";
my $str = Data::Pool::Shared::Str->new(undef, $CAPACITY, 64);

run_bench "Str alloc/set/get/free (48B)" => $str, sub {
    my ($p, $w) = @_;
    my $data = sprintf "w=%d pid=%d " x 4, ($w, $$) x 4;
    for (1..$OPS) {
        my $s = $p->alloc(1.0);
        next unless defined $s;
        $p->set($s, $data);
        my $v = $p->get($s);
        $p->free($s);
    }
};

# --- I64: low contention (large pool) ---

print "\n";
my $big = Data::Pool::Shared::I64->new(undef, 4096);

run_bench "I64 alloc/free (cap=4096, low contention)" => $big, sub {
    my ($p, $w) = @_;
    for (1..$OPS) {
        my $s = $p->alloc(1.0);
        next unless defined $s;
        $p->set($s, $$);
        $p->free($s);
    }
};
