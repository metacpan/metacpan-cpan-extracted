package Data::Pool::Shared;
use strict;
use warnings;
our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Data::Pool::Shared', $VERSION);

# Variant @ISA — inherit alloc/free/is_allocated/capacity/etc. from base

@Data::Pool::Shared::I64::ISA = ('Data::Pool::Shared');
@Data::Pool::Shared::F64::ISA = ('Data::Pool::Shared');
@Data::Pool::Shared::I32::ISA = ('Data::Pool::Shared');
@Data::Pool::Shared::Str::ISA = ('Data::Pool::Shared');

# Guard — auto-free on scope exit

package Data::Pool::Shared::Guard {
    sub DESTROY {
        my $self = shift;
        eval { $self->[0]->free($self->[1]) } if $self->[0];
    }
}

sub alloc_guard {
    my ($self, $timeout) = @_;
    my $idx = $self->alloc($timeout // -1);
    return unless defined $idx;
    my $guard = bless [$self, $idx], 'Data::Pool::Shared::Guard';
    return wantarray ? ($idx, $guard) : $guard;
}

sub try_alloc_guard {
    my ($self) = @_;
    my $idx = $self->try_alloc;
    return unless defined $idx;
    my $guard = bless [$self, $idx], 'Data::Pool::Shared::Guard';
    return wantarray ? ($idx, $guard) : $guard;
}

# Convenience — alloc + set in one call

sub alloc_set {
    my ($self, $val, $timeout) = @_;
    my $idx = $self->alloc($timeout // -1);
    return unless defined $idx;
    $self->set($idx, $val);
    return $idx;
}

sub try_alloc_set {
    my ($self, $val) = @_;
    my $idx = $self->try_alloc;
    return unless defined $idx;
    $self->set($idx, $val);
    return $idx;
}

# Iterate allocated slots

sub each_allocated {
    my ($self, $cb) = @_;
    $cb->($_) for @{ $self->allocated_slots };
}

1;

__END__

=encoding utf-8

=head1 NAME

Data::Pool::Shared - Fixed-size shared-memory object pool for Linux

=head1 SYNOPSIS

    use Data::Pool::Shared;

    # Raw byte pool — 100 slots of 64 bytes each
    my $pool = Data::Pool::Shared->new('/tmp/pool.shm', 100, 64);
    my $idx = $pool->alloc;           # allocate a slot
    $pool->set($idx, "hello world");  # write data
    my $data = $pool->get($idx);      # read data
    $pool->free($idx);                # release slot

    # Typed pools
    my $ints = Data::Pool::Shared::I64->new('/tmp/ints.shm', 1000);
    my $i = $ints->alloc;
    $ints->set($i, 42);
    $ints->add($i, 8);            # atomic add, returns 50
    $ints->cas($i, 50, 99);       # atomic CAS
    say $ints->get($i);           # 99

    my $floats = Data::Pool::Shared::F64->new('/tmp/f.shm', 100);
    my $strs = Data::Pool::Shared::Str->new('/tmp/s.shm', 100, 256);

    # Guard — auto-free on scope exit
    {
        my ($idx, $guard) = $pool->alloc_guard;
        $pool->set($idx, $data);
        # ... use slot ...
    }  # auto-freed

    # Lock-free primitives
    my $prev = $ints->cmpxchg($i, 99, 200);  # CAS returning old value
    $prev = $ints->xchg($i, 300);            # atomic exchange

    # Batch operations
    my $slots = $pool->alloc_n(10);           # allocate 10 slots
    $pool->free_n($slots);                    # batch free

    # Zero-copy and raw pointers
    my $sv  = $pool->slot_sv($idx);           # read-only SV over slot memory
    my $ptr = $pool->ptr($idx);               # C pointer (UV) for FFI/OpenGL
    my @all = @{ $pool->allocated_slots };    # list all allocated indices

    # Convenience
    my $j = $ints->alloc_set(42);         # alloc + set
    $j = $ints->try_alloc_set(42);        # non-blocking

    # Crash recovery
    my $n = $pool->recover_stale;         # free slots owned by dead PIDs

    # Cross-process via fork
    if (fork == 0) {
        my $child = Data::Pool::Shared::I64->new('/tmp/ints.shm', 1000);
        my $i = $child->alloc;
        $child->set($i, $$);
        exit;
    }

    # Anonymous (fork-inherited)
    $pool = Data::Pool::Shared::I64->new(undef, 100);

    # memfd (fd-passable)
    $pool = Data::Pool::Shared::I64->new_memfd("my_pool", 100);
    my $fd = $pool->memfd;

=head1 DESCRIPTION

Data::Pool::Shared provides a fixed-size object pool in shared memory.
Slots are allocated and freed explicitly, like a memory allocator but
for cross-process shared objects.

Unlike L<Data::Buffer::Shared> (index-based array access), Pool provides
allocate/free semantics: you request a slot, use it, and return it.
The pool tracks which slots are in use via a lock-free bitmap.

B<Linux-only>. Requires 64-bit Perl.

=head2 Variants

=over

=item L<Data::Pool::Shared> - raw byte slots (any elem_size)

=item L<Data::Pool::Shared::I64> - int64_t (atomic get/set/cas/add)

=item L<Data::Pool::Shared::F64> - double

=item L<Data::Pool::Shared::I32> - int32_t (atomic get/set/cas/add)

=item L<Data::Pool::Shared::Str> - fixed-length strings

=back

=head2 Allocation

Allocation uses a CAS-based bitmap scan (lock-free). Each 64-slot group
is managed by one atomic uint64_t word. On contention, CAS retries
automatically. When the pool is full, C<alloc> blocks on a futex until
a slot is freed.

=head2 Crash Safety

Each slot records the PID of its allocator. C<recover_stale> scans for
slots owned by dead processes and frees them. Call periodically or on
startup for crash recovery.

=head1 CONSTRUCTORS

    # Raw pool
    my $p = Data::Pool::Shared->new($path, $capacity, $elem_size);
    my $p = Data::Pool::Shared->new(undef, $capacity, $elem_size);  # anonymous
    my $p = Data::Pool::Shared->new_memfd($name, $capacity, $elem_size);
    my $p = Data::Pool::Shared->new_from_fd($fd);

    # I64 / I32 / F64 pools (elem_size is implicit)
    my $p = Data::Pool::Shared::I64->new($path, $capacity);
    my $p = Data::Pool::Shared::I32->new($path, $capacity);
    my $p = Data::Pool::Shared::F64->new($path, $capacity);
    my $p = Data::Pool::Shared::I64->new_memfd($name, $capacity);

    # All variants support new_from_fd
    my $p = Data::Pool::Shared::I64->new_from_fd($fd);

    # Str pool
    my $p = Data::Pool::Shared::Str->new($path, $capacity, $max_len);
    my $p = Data::Pool::Shared::Str->new_memfd($name, $capacity, $max_len);
    my $p = Data::Pool::Shared::Str->new_from_fd($fd);

=head1 METHODS

=head2 Allocation

    my $idx = $pool->alloc;             # block until available
    my $idx = $pool->alloc($timeout);   # with timeout (seconds)
    my $idx = $pool->alloc(0);          # non-blocking
    my $idx = $pool->try_alloc;         # non-blocking (alias)

Returns slot index on success, C<undef> on failure/timeout.

    $pool->free($idx);                  # release slot (returns true/false)

=head2 Batch Operations

    my $slots = $pool->alloc_n($n);            # allocate N slots (blocking)
    my $slots = $pool->alloc_n($n, $timeout);  # with timeout
    my $slots = $pool->alloc_n($n, 0);         # non-blocking
    # returns arrayref of indices, or undef (all-or-nothing)

    my $freed = $pool->free_n(\@indices);      # batch free, returns count freed
    # single used-decrement + single futex wake (faster than N individual frees)

    my $slots = $pool->allocated_slots;  # arrayref of all allocated indices

=head2 Data Access

    my $val = $pool->get($idx);         # read slot
    $pool->set($idx, $val);             # write slot

For I64/I32 variants:

    my $ok  = $pool->cas($idx, $old, $new);     # atomic CAS, returns bool
    my $old = $pool->cmpxchg($idx, $old, $new); # atomic CAS, returns old value
    my $old = $pool->xchg($idx, $val);          # atomic exchange, returns old
    my $val = $pool->add($idx, $delta);          # atomic add, returns new value
    my $val = $pool->incr($idx);                 # atomic increment
    my $val = $pool->decr($idx);                 # atomic decrement

For Str variant:

    my $max = $pool->max_len;           # maximum string length

=head2 Raw Pointers

    my $ptr = $pool->ptr($idx);     # raw C pointer to slot data (UV)
    my $ptr = $pool->data_ptr;      # pointer to start of data section

C<ptr> returns the memory address of a slot's data as an unsigned
integer. Use with L<FFI::Platypus>, OpenGL C<_c> functions, or XS
code that needs a C<void*>.

C<data_ptr> returns the base of the contiguous data region. Slots
are laid out as C<data_ptr + idx * elem_size>.

B<Warning>: The returned pointer becomes dangling if the pool object
is destroyed. Do not use after the pool goes out of scope.

=head2 Zero-Copy Access

    my $sv = $pool->slot_sv($idx);  # SV backed by slot memory

Returns a read-only scalar whose PV points directly into the shared
memory slot. Reading the scalar reads the slot with no C<memcpy>.
Useful for large slots where avoiding copy matters.

The scalar holds a reference to the pool object, keeping it alive
for as long as the scalar (or any copy of it) is live. However, the
scalar still reflects the current contents of the slot: if the slot
is C<free()>d and later re-allocated, reads will see the new data.
To modify the slot, use C<set()>.

=head2 Status

    my $ok  = $pool->is_allocated($idx);
    my $cap = $pool->capacity;
    my $esz = $pool->elem_size;
    my $n   = $pool->used;              # allocated count
    my $n   = $pool->available;         # free count
    my $pid = $pool->owner($idx);       # PID of allocator

=head2 Recovery

    my $n = $pool->recover_stale;       # free slots owned by dead PIDs
    $pool->reset;                       # free all slots (exclusive access only)

=head2 Guards

    my ($idx, $guard) = $pool->alloc_guard;           # auto-free on scope exit
    my ($idx, $guard) = $pool->alloc_guard($timeout);
    my ($idx, $guard) = $pool->try_alloc_guard;       # non-blocking

=head2 Convenience

    my $idx = $pool->alloc_set($val);           # alloc + set
    my $idx = $pool->alloc_set($val, $timeout); # with timeout
    my $idx = $pool->try_alloc_set($val);       # non-blocking

    $pool->each_allocated(sub { my $idx = shift; ... });

=head2 Common Methods

    my $p  = $pool->path;        # backing file (undef if anon)
    my $fd = $pool->memfd;       # memfd fd (-1 if not memfd)
    $pool->sync;                 # msync to disk
    $pool->unlink;               # remove backing file
    my $s  = $pool->stats;       # diagnostic hashref

=head3 eventfd Integration

    my $fd = $pool->eventfd;           # create eventfd
    $pool->eventfd_set($fd);           # use existing fd
    my $fd = $pool->fileno;            # current eventfd (-1 if none)
    $pool->notify;                     # signal eventfd
    my $n  = $pool->eventfd_consume;   # drain counter

=head1 STATS

C<stats()> returns a hashref with diagnostic counters. All values are
approximate under concurrency.

=over

=item C<capacity> — total slot count (immutable)

=item C<elem_size> — bytes per slot (immutable)

=item C<used> — currently allocated slot count

=item C<available> — currently free slot count (C<capacity - used>)

=item C<waiters> — processes currently blocked on C<alloc>

=item C<mmap_size> — total mmap region size in bytes

=item C<allocs> — cumulative successful allocations

=item C<frees> — cumulative frees (including stale recovery)

=item C<waits> — C<alloc> calls that entered the retry loop

=item C<timeouts> — C<alloc> calls that timed out

=item C<recoveries> — slots freed by C<recover_stale>

=back

=head1 SECURITY

The shared memory region (mmap) is writable by all processes that open
it. A malicious process with write access to the backing file or memfd
can corrupt header fields (bitmap, counters, slot data) and cause other
processes to crash, spin, or return incorrect data. Do not share backing
files with untrusted processes. Use anonymous mode or memfd with
restricted fd passing for isolation.

=head1 PERFORMANCE

=over

=item * Allocation scans a bitmap of C<ceil(capacity/64)> words.
O(capacity/64) worst case, O(1) amortized with scan_hint.

=item * Each allocation is a single CAS on one bitmap word.
Under contention, CAS retries on the same word are ~10ns each.

=item * When pool is full, C<alloc> blocks on a futex (zero CPU).
Woken by a single C<FUTEX_WAKE> syscall on C<free>.

=item * C<free_n> batches N frees into a single C<used> decrement
and a single C<FUTEX_WAKE> syscall — faster than N individual frees.

=item * C<slot_sv> provides zero-copy access to slot data, avoiding
C<memcpy> overhead for large slots.

=item * Typed variants (I64, I32) use atomic load/store/CAS/add
directly on the mmap'd memory — no locking overhead.

=back

=head1 BENCHMARKS

Measured on a single-socket x86_64 Linux system, Perl 5.40.

    Single process (1M ops):
      I64 alloc + free          3.3M/s
      I64 get/set              ~10M/s
      I64 add/incr             ~10M/s
      I64 cas                   9.8M/s
      Str set (48B)            ~10M/s
      Str get (48B)             7.5M/s
      alloc_set + free          1.9M/s

    Multi-process (8 workers, 200K ops each, cap=64):
      I64 alloc/free            4.7M/s aggregate
      I64 alloc/set/get/free    5.1M/s aggregate
      I64 atomic add           22.9M/s aggregate
      Str alloc/set/get/free    4.9M/s aggregate

    Batch (single process, alloc_n + free_n):
      batch=1                   ~2.3M/s
      batch=16                  ~400K/s  (vs ~200K individual)
      batch=64                  ~110K/s  (vs ~50K individual, 2x gain)

Bottleneck is Perl XS call overhead, not the CAS or futex.

=head1 SEE ALSO

L<Data::Buffer::Shared> - typed shared array (index-based, no alloc/free)

L<Data::Stack::Shared> - LIFO stack

L<Data::Deque::Shared> - double-ended queue

L<Data::Queue::Shared> - FIFO queue

L<Data::ReqRep::Shared> - request-reply

L<Data::Log::Shared> - append-only log (WAL)

L<Data::Sync::Shared> - synchronization primitives

L<Data::HashMap::Shared> - concurrent hash table

L<Data::PubSub::Shared> - publish-subscribe ring

L<Data::Heap::Shared> - priority queue

L<Data::Graph::Shared> - directed weighted graph

L<Data::BitSet::Shared> - shared bitset (lock-free per-bit ops)

L<Data::RingBuffer::Shared> - fixed-size overwriting ring buffer

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
