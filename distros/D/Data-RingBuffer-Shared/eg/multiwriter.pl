#!/usr/bin/env perl
# Multi-writer: several processes write to same ring, reader sees all
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::RingBuffer::Shared;
$| = 1;

my $nwriters = shift || 4;
my $per      = shift || 100;

my $ring = Data::RingBuffer::Shared::Int->new(undef, 256);

my @pids;
for my $w (1..$nwriters) {
    my $pid = fork // die;
    if ($pid == 0) {
        for my $i (1..$per) {
            $ring->write($w * 10000 + $i);
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;

printf "writers=%d per=%d total_writes=%d ring_size=%d\n",
    $nwriters, $per, $ring->count, $ring->size;

# verify: last 10 entries
printf "last 10: %s\n", join(' ', map { $ring->latest($_) // '?' } 0..9);

my $s = $ring->stats;
printf "overwrites=%d\n", $s->{overwrites};
