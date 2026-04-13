#!/usr/bin/env perl
# FFI::Platypus interop: call libc qsort on pool data via raw pointer
#
# Pattern: alloc I64 slots with random data → get raw pointer via ptr() →
# call C qsort directly on shared memory → verify sorted in Perl
#
# Requires: FFI::Platypus

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";

eval { require FFI::Platypus; 1 }
    or die "FFI::Platypus required: install with cpanm FFI::Platypus\n";

$| = 1;
use Data::Pool::Shared;

my $N = shift || 20;

my $pool = Data::Pool::Shared::I64->new(undef, $N);

# alloc N slots and fill with random data
# NOTE: slots are contiguous in memory (data_ptr + idx * 8),
# but only if allocated in order starting from 0
my @slots;
for (1 .. $N) {
    push @slots, $pool->alloc;
}
# verify contiguous allocation (slot 0, 1, 2, ...)
die "non-contiguous alloc" unless $slots[-1] == $N - 1;

srand(42);
$pool->set($_, int(rand(10000))) for @slots;

printf "before sort: %s\n", join(' ', map { $pool->get($_) } @slots[0..9]);

# --- FFI: call qsort on the raw pool memory ---
my $ffi = FFI::Platypus->new(api => 2);
$ffi->lib(undef);  # libc

# int64_t comparator: cmp(const void *a, const void *b)
# returns negative/zero/positive
my $cmp = $ffi->closure(sub {
    my ($a_ptr, $b_ptr) = @_;
    # read int64_t from raw pointers
    my $a = unpack('q<', $ffi->cast('opaque', 'string(8)', $a_ptr));
    my $b = unpack('q<', $ffi->cast('opaque', 'string(8)', $b_ptr));
    return $a <=> $b;
});

# qsort(base, nmemb, size, compar)
$ffi->attach([qsort => 'c_qsort'] => ['opaque', 'size_t', 'size_t',
    '(opaque,opaque)->int'] => 'void');

my $base_ptr = $pool->data_ptr;
printf "data_ptr = 0x%x, sorting %d elements in-place...\n", $base_ptr, $N;

c_qsort($base_ptr, $N, 8, $cmp);

printf "after sort:  %s\n", join(' ', map { $pool->get($_) } @slots[0..9]);

# verify sorted
my $sorted = 1;
for my $i (1 .. $#slots) {
    if ($pool->get($slots[$i]) < $pool->get($slots[$i-1])) {
        $sorted = 0;
        last;
    }
}
printf "sorted: %s\n", $sorted ? "yes" : "NO";

# --- FFI: call memset to zero a specific slot via ptr() ---
$ffi->attach([memset => 'c_memset'] => ['opaque', 'int', 'size_t'] => 'opaque');

my $slot_ptr = $pool->ptr($slots[5]);
printf "\nslot[5] before memset: %d\n", $pool->get($slots[5]);
c_memset($slot_ptr, 0, 8);
printf "slot[5] after memset:  %d\n", $pool->get($slots[5]);

$pool->free($_) for @slots;
