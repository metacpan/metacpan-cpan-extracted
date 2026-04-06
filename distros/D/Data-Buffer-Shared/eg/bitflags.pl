#!/usr/bin/env perl
# Shared atomic bitflag array
use strict;
use warnings;
use Data::Buffer::Shared::U32;

my $buf = Data::Buffer::Shared::U32->new_anon(64); # 64 flag words = 2048 bits

# set bit 5 in word 0
$buf->atomic_or(0, 1 << 5);
printf "word 0 after set bit 5: 0x%08x\n", $buf->get(0);

# set bits 0-3
$buf->atomic_or(0, 0x0F);
printf "word 0 after set bits 0-3: 0x%08x\n", $buf->get(0);

# clear bit 5
$buf->atomic_and(0, ~(1 << 5));
printf "word 0 after clear bit 5: 0x%08x\n", $buf->get(0);

# toggle bit 0
$buf->atomic_xor(0, 1);
printf "word 0 after toggle bit 0: 0x%08x\n", $buf->get(0);

# check if bit 1 is set
my $word = $buf->get(0);
printf "bit 1 is %s\n", ($word & (1 << 1)) ? 'set' : 'clear';
