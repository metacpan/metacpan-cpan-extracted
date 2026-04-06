#!/usr/bin/env perl
# Basic usage: typed shared buffer with file-backed mmap
use strict;
use warnings;
use Data::Buffer::Shared::I64;

my $path = '/tmp/demo_buf.shm';
my $buf = Data::Buffer::Shared::I64->new($path, 1024);

# set / get (lock-free atomic for single elements)
$buf->set(0, 42);
$buf->set(1, 100);
printf "buf[0] = %d, buf[1] = %d\n", $buf->get(0), $buf->get(1);

# atomic counters
$buf->incr(0);
$buf->add(0, 10);
printf "after incr+add: buf[0] = %d\n", $buf->get(0);

# compare-and-swap
if ($buf->cas(0, 53, 200)) {
    printf "cas succeeded: buf[0] = %d\n", $buf->get(0);
}

# bulk operations (seqlock-guarded)
$buf->set_slice(10, 1, 2, 3, 4, 5);
my @vals = $buf->slice(10, 5);
printf "slice: %s\n", join(', ', @vals);

# fill entire buffer
$buf->fill(0);
printf "after fill(0): buf[0] = %d\n", $buf->get(0);

# raw binary access
$buf->set(0, 0x0102030405060708);
my $raw = $buf->get_raw(0, 8);
printf "raw bytes: %s\n", unpack("H*", $raw);

# zero-copy scalar ref (aliased to mmap)
my $ref = $buf->as_scalar;
printf "as_scalar length: %d bytes\n", length($$ref);

# cleanup
$buf->unlink;
