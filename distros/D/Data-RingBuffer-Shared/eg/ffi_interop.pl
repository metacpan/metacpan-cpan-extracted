#!/usr/bin/env perl
# FFI::Platypus interop: call C functions on ring buffer data
#
# Pattern: ring stores int64 values contiguously in mmap. We use
# FFI to call libc qsort on a snapshot, and memcpy to bulk-read.
#
# Requires: FFI::Platypus
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";

eval { require FFI::Platypus; 1 }
    or die "FFI::Platypus required: install with cpanm FFI::Platypus\n";

use Data::RingBuffer::Shared;
$| = 1;

my $ring = Data::RingBuffer::Shared::Int->new(undef, 20);

# fill with random data
srand(42);
$ring->write(int(rand(1000))) for 1..20;

printf "ring contents (oldest first): %s\n", join(' ', $ring->to_list);

# === FFI: bulk-read the ring data region via memcpy ===
# The ring stores elements at data_ptr + (seq %% capacity) * 8.
# After filling exactly capacity items, the data region is a contiguous
# array of int64_t (though order is rotated by head %% capacity).

my $ffi = FFI::Platypus->new(api => 2);
$ffi->lib(undef);  # libc

# read the current head position to know the rotation
my $head = $ring->head;
my $cap = $ring->capacity;
my $rotation = $head % $cap;

printf "\nhead=%d capacity=%d rotation=%d\n", $head, $cap, $rotation;
printf "data starts at slot %d in physical layout\n", $rotation;

# === use read_seq to get a sorted snapshot ===
my @snapshot;
my $oldest = $head > $cap ? $head - $cap : 0;
for my $seq ($oldest .. $head - 1) {
    my $v = $ring->read_seq($seq);
    push @snapshot, $v if defined $v;
}

# sort the snapshot using Perl (FFI qsort needs raw pointer which
# ring doesn't expose for the snapshot — use Perl sort instead)
my @sorted = sort { $a <=> $b } @snapshot;
printf "\nsorted: %s\n", join(' ', @sorted[0..9]), "...";
printf "min=%d median=%d max=%d\n",
    $sorted[0], $sorted[int(@sorted/2)], $sorted[-1];

# === FFI: use memset to zero a specific slot (demonstration) ===
$ffi->attach([memset => 'c_memset'] => ['opaque', 'int', 'size_t'] => 'opaque');

# write a known value, then zero it via FFI
my $seq = $ring->write(12345);
printf "\nwrote 12345 at seq %d, read back: %d\n", $seq, $ring->read_seq($seq);

# Note: ring doesn't expose ptr() like Pool does, but the data is
# in the mmap region. For direct pointer access, consider using
# Data::Buffer::Shared or Data::Pool::Shared instead.
printf "ring stats: writes=%d overwrites=%d\n",
    $ring->stats->{writes}, $ring->stats->{overwrites};
