package Data::Buffer::Shared;
use strict;
use warnings;
our $VERSION = '0.01';

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
    my $ok = buf_xx_cas $buf, $idx, $old, $new;  # compare-and-swap

Diagnostics:

    my $c = buf_xx_capacity $buf;
    my $s = buf_xx_mmap_size $buf;
    my $e = buf_xx_elem_size $buf;

Explicit locking (for batch operations):

    buf_xx_lock_wr $buf;    # write lock + seqlock begin
    buf_xx_unlock_wr $buf;  # seqlock end + write unlock
    buf_xx_lock_rd $buf;    # read lock
    buf_xx_unlock_rd $buf;  # read unlock

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
