#!/usr/bin/env perl
# History buffer: keep last N commands, replay on demand
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::RingBuffer::Shared;
$| = 1;

my $history = Data::RingBuffer::Shared::Int->new(undef, 5);

# simulate command IDs being executed
for my $cmd (101..112) {
    $history->write($cmd);
    printf "execute cmd %d\n", $cmd;
}

printf "\nhistory (last %d commands):\n", $history->size;
for my $i (reverse 0 .. $history->size - 1) {
    printf "  %d. cmd %d\n", $history->size - $i, $history->latest($i);
}

printf "\nreplay last 3:\n";
for my $i (reverse 0..2) {
    printf "  replay cmd %d\n", $history->latest($i);
}

printf "\nby sequence (seq 10 = cmd %s):\n",
    $history->read_seq(10) // "overwritten";
printf "by sequence (seq 5 = cmd %s):\n",
    $history->read_seq(5) // "overwritten";
