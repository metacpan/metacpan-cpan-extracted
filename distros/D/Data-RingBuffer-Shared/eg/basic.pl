#!/usr/bin/env perl
# Basic ring buffer: write values, read latest, overwrite demo
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::RingBuffer::Shared;
$| = 1;

my $ring = Data::RingBuffer::Shared::Int->new(undef, 5);

$ring->write($_) for 1..7;
printf "capacity=%d size=%d head=%d\n", $ring->capacity, $ring->size, $ring->head;
printf "latest:    %d\n", $ring->latest;
printf "latest(1): %d\n", $ring->latest(1);
printf "latest(4): %d\n", $ring->latest(4);
printf "to_list:   %s\n", join(' ', $ring->to_list);
printf "read_seq(0): %s (overwritten)\n", $ring->read_seq(0) // "undef";
printf "read_seq(2): %d\n", $ring->read_seq(2);
