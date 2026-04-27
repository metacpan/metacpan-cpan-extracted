package Data::Buffer::Shared;
use strict;
use warnings;
our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Data::Buffer::Shared', $VERSION);

1;

__END__

=encoding utf-8

=head1 NAME

Data::Buffer::Shared - Type-specialized shared-memory buffers for multiprocess access

=head1 SYNOPSIS

    use Data::Buffer::Shared::I64;

    # Create or open a shared buffer (file-backed mmap)
    my $buf = Data::Buffer::Shared::I64->new('/tmp/mybuf.shm', 1024);

    # Keyword API (fastest)
    buf_i64_set $buf, 0, 42;
    my $val = buf_i64_get $buf, 0;

    # Method API
    $buf->set(0, 42);
    my $v = $buf->get(0);

    # Lock-free atomic operations (integer types)
    buf_i64_incr $buf, 0;
    buf_i64_add $buf, 0, 10;
    buf_i64_cas $buf, 0, 52, 100;

    # Multiprocess
    if (fork() == 0) {
        my $child = Data::Buffer::Shared::I64->new('/tmp/mybuf.shm', 1024);
        buf_i64_incr $child, 0;   # atomic, visible to parent
        exit;
    }
    wait;

=head1 DESCRIPTION

Data::Buffer::Shared provides type-specialized fixed-capacity buffers stored in
file-backed shared memory (C<mmap(MAP_SHARED)>), enabling efficient multiprocess
data sharing on Linux.

B<Linux-only>. Requires 64-bit Perl.

=head2 Features

=over

=item * File-backed mmap for cross-process sharing

=item * Lock-free atomic get/set for numeric types (single-element)

=item * Lock-free atomic counters: incr/decr/add/cas (integer types)

=item * Seqlock-guarded bulk operations (slice, fill)

=item * Futex-based read-write lock with stale lock recovery

=item * Keyword API via XS::Parse::Keyword

=item * Presized: fixed capacity, no growing

=back

=head2 Variants

=over

=item L<Data::Buffer::Shared::I8> - int8

=item L<Data::Buffer::Shared::U8> - uint8

=item L<Data::Buffer::Shared::I16> - int16

=item L<Data::Buffer::Shared::U16> - uint16

=item L<Data::Buffer::Shared::I32> - int32

=item L<Data::Buffer::Shared::U32> - uint32

=item L<Data::Buffer::Shared::I64> - int64

=item L<Data::Buffer::Shared::U64> - uint64

=item L<Data::Buffer::Shared::F32> - float

=item L<Data::Buffer::Shared::F64> - double

=item L<Data::Buffer::Shared::Str> - fixed-length string

=back

=head2 Constructors

    my $buf = Data::Buffer::Shared::I64->new($path, $capacity);         # file-backed
    my $buf = Data::Buffer::Shared::I64->new_anon($capacity);           # anonymous
    my $buf = Data::Buffer::Shared::I64->new_memfd($name, $capacity);   # memfd
    my $buf = Data::Buffer::Shared::I64->new_from_fd($fd);              # reopen memfd

The C<Str> variant takes an additional C<$max_len> argument giving the
per-element fixed byte width:

    my $buf = Data::Buffer::Shared::Str->new($path, $capacity, $max_len);
    my $buf = Data::Buffer::Shared::Str->new_anon($capacity, $max_len);
    my $buf = Data::Buffer::Shared::Str->new_memfd($name, $capacity, $max_len);
    my $buf = Data::Buffer::Shared::Str->new_from_fd($fd, $max_len);

C<new_from_fd> duplicates the caller's fd internally; the caller keeps
ownership of the passed fd. The C<Str> variant requires the same
C<$max_len> the original was created with — there is no header field
storing it.

=head2 Lifecycle

    my $p  = $buf->path;    # backing file path, or undef for anon/memfd
    my $fd = $buf->fd;      # memfd fd, or undef for anon/file-backed
    my $fd = $buf->memfd;   # alias of fd() for sibling-module parity
    $buf->sync;             # msync(MS_SYNC) mmap to backing store
    $buf->unlink;           # remove backing file
    my $h = $buf->stats;    # diagnostic hashref

=head2 API

Replace C<xx> with variant prefix: C<i8>, C<u8>, C<i16>, C<u16>,
C<i32>, C<u32>, C<i64>, C<u64>, C<f32>, C<f64>, C<str>.

    buf_xx_set $buf, $idx, $value;    # set element (lock-free atomic for numeric)
    my $v = buf_xx_get $buf, $idx;    # get element (lock-free atomic for numeric)
    my @v = buf_xx_slice $buf, $from, $count;  # bulk read (seqlock)
    buf_xx_fill $buf, $value;         # fill all elements (write-locked)

Integer variants also have:

    my $n = buf_xx_incr $buf, $idx;          # atomic increment, returns new value
    my $n = buf_xx_decr $buf, $idx;          # atomic decrement
    my $n = buf_xx_add $buf, $idx, $delta;   # atomic add
    my $ok = buf_xx_cas $buf, $idx, $old, $new;          # compare-and-swap
    my $p = buf_xx_cmpxchg $buf, $idx, $old, $new;       # CAS, returns prior value
    my $n = buf_xx_atomic_and $buf, $idx, $mask;         # atomic AND (integer variants)
    my $n = buf_xx_atomic_or  $buf, $idx, $mask;         # atomic OR
    my $n = buf_xx_atomic_xor $buf, $idx, $mask;         # atomic XOR

Raw / bulk:

    my $raw = buf_xx_get_raw $buf, $from, $count;        # bulk bytes, seqlock-guarded
    buf_xx_set_raw $buf, $from, $raw;                    # bulk bytes, write-locked
    $buf->add_slice($from, \@deltas);                    # batch atomic add (integer variants)
    my $ptr = buf_xx_ptr $buf;           # raw pointer to data, for FFI use
    my $ptr = buf_xx_ptr_at $buf, $idx;  # pointer to element at index

Zero-copy (numeric variants):

    my $sv = $buf->as_scalar;   # mmap-aliased read-only scalar ref

Diagnostics:

    my $c = buf_xx_capacity $buf;
    my $s = buf_xx_mmap_size $buf;
    my $e = buf_xx_elem_size $buf;
    my $h = $buf->stats;    # hashref: capacity/elem_size/mmap_size/variant_id/recoveries

Persistence:

    $buf->sync;             # msync(MS_SYNC) mmap to backing store

Explicit locking (for batch operations):

    buf_xx_lock_wr $buf;    # write lock + seqlock begin
    buf_xx_unlock_wr $buf;  # seqlock end + write unlock
    buf_xx_lock_rd $buf;    # read lock
    buf_xx_unlock_rd $buf;  # read unlock

=head1 SEE ALSO

L<Data::HashMap::Shared> - concurrent hash table

L<Data::Queue::Shared> - FIFO queue

L<Data::PubSub::Shared> - publish-subscribe ring

L<Data::ReqRep::Shared> - request-reply

L<Data::Sync::Shared> - synchronization primitives

L<Data::Pool::Shared> - fixed-size object pool

L<Data::Stack::Shared> - LIFO stack

L<Data::Deque::Shared> - double-ended queue

L<Data::Log::Shared> - append-only log (WAL)

L<Data::Heap::Shared> - priority queue

L<Data::Graph::Shared> - directed weighted graph

L<Data::RingBuffer::Shared> - fixed-size overwriting ring buffer

L<Data::BitSet::Shared> - shared bitset (lock-free per-bit ops)

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
