package Data::Buffer::Shared;
use strict;
use warnings;
our $VERSION = '0.06';

require XSLoader;
XSLoader::load('Data::Buffer::Shared', $VERSION);

# ithreads: blessed shared-memory handles must never be cloned into a
# child thread -- the clone would double-free the handle on thread exit.
{ no strict 'refs'; *{"${_}::CLONE_SKIP"} = sub { 1 } for qw(
  Data::Buffer::Shared::U8
  Data::Buffer::Shared::I8
  Data::Buffer::Shared::U16
  Data::Buffer::Shared::I16
  Data::Buffer::Shared::U32
  Data::Buffer::Shared::I32
  Data::Buffer::Shared::U64
  Data::Buffer::Shared::I64
  Data::Buffer::Shared::F32
  Data::Buffer::Shared::F64
  Data::Buffer::Shared::Str
); }

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

=item * Write-preferring futex read-write lock with dead-process recovery

=item * eventfd-based cross-process notification (optional)

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
C<$max_len> the original was created with: it is recorded in the header as
the element size and checked on attach, so passing a different C<$max_len>
dies with an "elem_size mismatch" error.

=head2 Lifecycle

    my $p  = $buf->path;    # backing file path, or undef for anon/memfd
    my $fd = $buf->fd;      # memfd fd, or undef for anon/file-backed
    my $fd = $buf->memfd;   # alias of fd()
    $buf->clear;            # zero all elements (write-locked)
    $buf->sync;             # msync(MS_SYNC) mmap to backing store
    $buf->unlink;           # remove backing file (dies for anonymous buffers)
    my $h = $buf->stats;    # diagnostic hashref

C<unlink> also works as a class method: C<< Data::Buffer::Shared::I64->unlink($path) >>.

C<memfd> is an alias of C<fd> (present on every variant): both return the backing
file descriptor for a memfd-backed buffer (created with C<new_memfd>), or C<undef>
for anonymous and file-backed buffers.

=head2 API

Replace C<xx> with variant prefix: C<i8>, C<u8>, C<i16>, C<u16>,
C<i32>, C<u32>, C<i64>, C<u64>, C<f32>, C<f64>, C<str>.

    buf_xx_set $buf, $idx, $value;    # set element (lock-free atomic for numeric)
    my $v = buf_xx_get $buf, $idx;    # get element (lock-free atomic for numeric)
    my @v = buf_xx_slice $buf, $from, $count;  # bulk read (seqlock)
    buf_xx_fill $buf, $value;         # fill all elements (write-locked)
    buf_xx_clear $buf;                # zero all elements (write-locked)

C<set_slice> is a method only (its variadic argument list has no keyword form);
it writes a run of elements starting at C<$from> and returns true on success:

    $buf->set_slice($from, @values);  # bulk write (write-locked)

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
    $buf->add_slice($from, @deltas);                     # batch atomic add (integer variants; flat list)
    my $ptr = buf_xx_ptr $buf;           # raw pointer to data, for FFI use
    my $ptr = buf_xx_ptr_at $buf, $idx;  # pointer to element at index

Zero-copy:

    my $sv = $buf->as_scalar;   # mmap-aliased read-only scalar ref

The returned scalar aliases the mapped bytes directly (no copy) and holds a
reference to the buffer so the mapping stays alive while it is in use.

Cross-process notification (all variants):

    my $efd = $buf->create_eventfd;   # create + attach an eventfd, returns the fd
    $buf->attach_eventfd($fd);        # attach an already-open eventfd
    my $efd = $buf->eventfd;          # current eventfd, or undef if none
    $buf->notify;                     # signal (eventfd write)
    my $n = $buf->wait_notify;        # drain the counter, non-blocking (undef if 0)

These are a thin wrapper over an C<eventfd(2)> descriptor stored in the handle,
letting one process signal another that the buffer changed. The eventfd is
created non-blocking, so C<wait_notify> does B<not> block: it reads and clears
the counter, returning the accumulated notify count, or C<undef> when the counter
is zero (nothing pending) or no eventfd is attached. Nothing else in the API
depends on them; watch the descriptor for readability in an event loop rather
than expecting a blocking wakeup.

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

The explicit locks are B<non-recursive> and B<non-upgradable>: calling
C<lock_wr> while holding C<lock_rd> on the same handle, or calling C<lock_wr>
twice without an intervening C<unlock_wr>, self-deadlocks. Dropping the last
reference to a handle while holding one of its locks leaks that handle's
reader slot (and any held lock contribution) until the process exits.

=head1 CONCURRENCY AND CRASH SAFETY

Single-element numeric get/set and the atomic counter operations
(C<incr>/C<decr>/C<add>/C<cas>/C<cmpxchg>/C<atomic_and>/C<atomic_or>/C<atomic_xor>)
are lock-free and safe to call concurrently from any number of processes. Bulk
reads (C<slice>, C<get_raw>) are guarded by a seqlock and retry if a writer
intervenes. Bulk writes (C<set_slice>, C<fill>, C<clear>, C<set_raw>) and the
explicit C<lock_wr>/C<unlock_wr> region take a write lock.

The write/read lock is a write-preferring futex read-write lock with
dead-process recovery: if a process crashes while holding the lock, another
process detects the dead holder and reclaims its contribution so the mapping
does not deadlock. See L</Reader-slot exhaustion> for the one narrow case this
recovery cannot cover.

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

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default, so only the
creating user can open and attach them. To share a backing file across users,
pass an explicit octal file mode such as C<0660> as the last argument to C<new>; the mode is applied
only when the file is created or initialized (an existing non-empty file keeps its own
permissions; a pre-existing empty file owned by your effective uid is initialized as a
fresh backing file and the mode is applied to it via C<fchmod>). The
file is opened with C<O_NOFOLLOW>, so a symlink planted at the path is refused,
and created with C<O_EXCL>; the on-disk header is validated when the file is
attached. Any process you grant write access to a shared mapping is trusted not
to corrupt its contents while other processes are using it.

=head2 Reader-slot exhaustion

Reader-slot exhaustion (slotless readers): dead-process recovery attributes a
crashed lock holder's contribution through its reader-slot. The slot table holds
1024 entries (one per concurrent reader process). If more than that many reader
processes share one mapping at once, a reader that cannot claim a slot proceeds
"slotless" -- it still takes the read lock but leaves no per-process record. If
such a slotless reader is then killed while holding the read lock, its share of
the lock cannot be attributed to a dead process, so writer recovery cannot
reclaim it and writers may block until the mapping is recreated. Reaching this
needs more than 1024 concurrent reader processes on one mapping plus a crash in
the brief read-lock window; the dead-process slot reclaim keeps the table from
filling with stale entries, so in practice it is very unlikely.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
