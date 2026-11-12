#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Temp qw(tempdir);
use Time::HiRes qw(time);
use Data::Shared qw(shared_set);

# Reproduces the PERFORMANCE section's flat-mount creation, key-write and reopen figures.

my @counts = @ARGV ? @ARGV : (25, 50, 100, 200);
my $keys = $ENV{DS_BENCH_KEYS} || 10_000;
my $replay = $ENV{DS_BENCH_REPLAY} || 400;

printf "Perl %vd; wall time; flat-mount topology costs\n", $^V;
print "Creating N flat mounts in one root (each mount republishes the manifest)\n";

for my $n (@counts) {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    my $start = time;
    my $last;
    for my $i (1 .. $n) {
        my $one = time;
        $root->mount("m$i", 'hashmap:ii', undef, 16);
        $last = time - $one;
    }
    my $total = time - $start;
    printf "  %3d mounts  total %7.3f s  average %6.2f ms  the %dth alone %6.2f ms\n",
        $n, $total, $total * 1000 / $n, $n, $last * 1000;
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('one', 'hashmap:ii', undef, $keys * 2);
    my @before = stat "$dir/manifest.json";
    my $start = time;
    shared_set($root, "/one/$_", $_) for 1 .. $keys;
    my $elapsed = time - $start;
    my @after = stat "$dir/manifest.json";
    printf "\n  %d keys into one mount  %7.3f s  (%.2f us/key)  manifest untouched: %s\n",
        $keys, $elapsed, $elapsed * 1e6 / $keys,
        ($before[1] == $after[1] && $before[9] == $after[9]) ? 'yes' : 'NO';
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount("m$_", 'hashmap:ii', undef, 16) for 1 .. $replay;
    undef $root;
    my $start = time;
    my $reopened = Data::Shared->open($dir);
    my $elapsed = time - $start;
    printf "  reopening a root of %d mounts  %7.3f s  (%d mounts replayed)\n",
        $replay, $elapsed, scalar(() = $reopened->mounts);
}
