#!/usr/bin/env perl
# PDL interop: ring buffer as a shared rolling signal, PDL for analysis
#
# Pattern: writer pushes F64 samples into ring, reader snapshots the
# ring into a PDL piddle for FFT, stats, or windowed computation.
#
# Requires: PDL
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";

eval { require PDL; PDL->import; 1 }
    or die "PDL required: install with cpanm PDL\n";

use POSIX qw(_exit);
use Time::HiRes qw(time sleep);
use Data::RingBuffer::Shared;
$| = 1;

my $N = 256;
my $ring = Data::RingBuffer::Shared::F64->new(undef, $N);

# writer: produce a noisy sine wave
my $pid = fork // die;
if ($pid == 0) {
    for my $i (0..511) {
        $ring->write(sin($i * 0.05) * 50 + rand(5));
        sleep 0.002;
    }
    _exit(0);
}

# wait for ring to fill
sleep 0.3;

# === snapshot ring into PDL ===
my @vals = $ring->to_list;
my $pdl = pdl(\@vals);

my @st = $pdl->stats;
printf "ring snapshot (%d samples):\n", $pdl->nelem;
printf "  min=%.2f max=%.2f mean=%.2f rms=%.2f\n", $st[3], $st[4], $st[0], $st[6];

# === windowed analysis: split into 4 chunks ===
my $chunk = int($pdl->nelem / 4);
for my $i (0..3) {
    my $slice = $pdl->slice([$i * $chunk, ($i + 1) * $chunk - 1]);
    printf "  chunk %d: mean=%.2f\n", $i, $slice->avg;
}

# === continuous: snapshot latest 64 samples, compute running RMS ===
printf "\nrolling RMS (latest 64 samples):\n";
for (1..5) {
    sleep 0.1;
    my @recent;
    for my $i (0..63) {
        my $v = $ring->latest($i);
        push @recent, $v if defined $v;
    }
    my $p = pdl(\@recent);
    my $rms = sqrt(($p ** 2)->avg);
    printf "  n=%d rms=%.2f\n", $p->nelem, $rms;
}

waitpid($pid, 0);
printf "\ndone: ring count=%d\n", $ring->count;
