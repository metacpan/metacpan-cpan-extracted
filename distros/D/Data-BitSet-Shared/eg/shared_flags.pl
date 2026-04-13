#!/usr/bin/env perl
# Shared flags: multiple workers claim bit flags atomically
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::BitSet::Shared;
$| = 1;

my $nworkers = shift || 4;
my $bs = Data::BitSet::Shared->new(undef, 128);

my @pids;
for my $w (1..$nworkers) {
    my $pid = fork // die;
    if ($pid == 0) {
        # each worker claims bits in its range
        my $base = ($w - 1) * 32;
        for my $i (0..31) {
            my $old = $bs->set($base + $i);
            # old should be 0 (first to set)
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;

printf "after %d workers: %d bits set (expect %d)\n",
    $nworkers, $bs->count, $nworkers * 32;
printf "first_clear: %s\n", $bs->first_clear // "none";
