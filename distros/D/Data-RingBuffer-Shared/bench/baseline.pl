#!/usr/bin/env perl
# Baseline throughput benchmark — runs a fixed scenario and emits a JSON
# line per metric. Intended for before/after comparison; not for humans.
#
# Usage: perl bench/baseline.pl > bench/baseline.json
use strict;
use warnings;
use Time::HiRes qw(time);
use POSIX qw(_exit);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::RingBuffer::Shared;
use JSON::PP;

sub emit { print encode_json($_[0]), "\n" }

sub bench_single_writer {
    my ($elem, $cap, $n) = @_;
    my $r = $elem eq 'int'
        ? Data::RingBuffer::Shared::Int->new(undef, $cap)
        : Data::RingBuffer::Shared::F64->new(undef, $cap);
    my $t0 = time;
    for (1..$n) { $r->write($_) }
    my $elapsed = time - $t0;
    return { ops => $n, elapsed => $elapsed, rate => $n / $elapsed };
}

sub bench_mpmc_write {
    my ($writers, $per, $cap) = @_;
    my $r = Data::RingBuffer::Shared::Int->new(undef, $cap);
    my @pids;
    my $t0 = time;
    for my $w (1..$writers) {
        my $pid = fork // die;
        if ($pid == 0) {
            for my $i (1..$per) { $r->write($w * 1_000_000 + $i) }
            _exit(0);
        }
        push @pids, $pid;
    }
    waitpid($_, 0) for @pids;
    my $elapsed = time - $t0;
    my $total = $writers * $per;
    return { writers => $writers, ops => $total, elapsed => $elapsed, rate => $total / $elapsed };
}

emit({ scenario => 'ring_int_1w',  %{bench_single_writer('int', 1024, 1_000_000)} });
emit({ scenario => 'ring_f64_1w',  %{bench_single_writer('f64', 1024, 1_000_000)} });
emit({ scenario => 'ring_int_mpmc_2w', %{bench_mpmc_write(2, 500_000, 1024)} });
emit({ scenario => 'ring_int_mpmc_4w', %{bench_mpmc_write(4, 250_000, 1024)} });
emit({ scenario => 'ring_int_mpmc_8w', %{bench_mpmc_write(8, 125_000, 1024)} });
