#!/usr/bin/env perl
# Single-process benchmark: build, has() (hit + miss), each_key, plus the
# compact-index size (bits/key) and total on-disk footprint. int and str.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Temp 'tempdir';
use Time::HiRes qw(time);
use Data::PerfectHash::Shared;

my $N   = $ENV{N} || 1_000_000;
my $dir = tempdir(CLEANUP => 1);

for my $type (qw(int str)) {
    my $path = "$dir/$type.phs";
    my @keys = $type eq 'int' ? (map { $_ * 3 + 1 } 0 .. $N - 1)
                              : (map { "key-$_" }    0 .. $N - 1);
    my @miss = $type eq 'int' ? (map { $_ * 3 + 2 } 0 .. $N - 1)
                              : (map { "nope-$_" }   0 .. $N - 1);

    my $t = time;
    $type eq 'int' ? Data::PerfectHash::Shared->build_int($path, \@keys)
                   : Data::PerfectHash::Shared->build_str($path, \@keys);
    my $build = time - $t;

    my $set = Data::PerfectHash::Shared->load($path);

    # Pre-build randomized probe orders BEFORE timing, so the timed loop
    # measures has() alone -- not the per-iteration int-rand + array index.
    my @hp = map { $keys[int rand $N] } 1 .. $N;   # random members
    my @mp = map { $miss[int rand $N] } 1 .. $N;   # random non-members
    $t = time; my $h = 0; $h += $set->has($_) for @hp;
    my $hit = $N / (time - $t);
    $t = time; my $m = 0; $m += $set->has($_) for @mp;
    my $missr = $N / (time - $t);
    $t = time; my $c = 0; $set->each_key(sub { $c++ }); my $ek = $N / (time - $t);

    # index size straight from the header: disp_len bytes over n keys
    # (header is 'L4Q11'; n is field 5, disp_len is field 9).
    open my $fh, '<:raw', $path or die $!;
    read $fh, my $hdr, 104; close $fh;
    my ($n, $disp_len) = (unpack 'L4Q11', $hdr)[5, 9];

    printf "%s N=%d: build %.2fs (%.2fM/s) | has hit %.1fM/s miss %.1fM/s | each_key %.1fM/s | index %.2f bits/key | file %.1f MB\n",
        $type, $N, $build, $N / $build / 1e6, $hit / 1e6, $missr / 1e6,
        $ek / 1e6, $disp_len * 8 / $n, (-s $path) / 1e6;
}
