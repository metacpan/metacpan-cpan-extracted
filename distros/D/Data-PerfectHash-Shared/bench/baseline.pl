#!/usr/bin/env perl
# Baseline: PerfectHash::Shared has() vs a native Perl hash lookup. The native
# hash is in-process only and rebuilt every run; the .phs image is dumped once
# and mmap'd -- shared across processes and persistent -- at a few bits/key of
# index. This shows has() is in the same ballpark as a raw hash lookup while
# buying the shared/immutable/dump-load model.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Temp 'tempdir';
use Time::HiRes qw(time);
use Data::PerfectHash::Shared;

my $N     = $ENV{N} || 1_000_000;
my $dir   = tempdir(CLEANUP => 1);
my $path  = "$dir/b.phs";
my @keys  = map { $_ * 3 + 1 } 0 .. $N - 1;
my @probe = map { $keys[int rand $N] } 1 .. $N;

my %h; @h{@keys} = ();
my $t = time; my $a = 0; exists $h{$_} and $a++ for @probe;
printf "native hash  exists: %.1fM lookups/s  (in-process only, not shareable/persistent)\n",
    $N / (time - $t) / 1e6;

Data::PerfectHash::Shared->build_int($path, \@keys);
my $set = Data::PerfectHash::Shared->load($path);
$t = time; my $b = 0; $set->has($_) and $b++ for @probe;
printf "PerfectHash  has:    %.1fM lookups/s  (mmap'd %.1f MB file, shared across processes + persistent)\n",
    $N / (time - $t) / 1e6, (-s $path) / 1e6;
