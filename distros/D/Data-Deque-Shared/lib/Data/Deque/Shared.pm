package Data::Deque::Shared;
use strict;
use warnings;
our $VERSION = '0.07';
require XSLoader;
XSLoader::load('Data::Deque::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
@Data::Deque::Shared::Int::ISA = ('Data::Deque::Shared');
@Data::Deque::Shared::Str::ISA = ('Data::Deque::Shared');
1;
__END__

=encoding utf-8

=head1 NAME

Data::Deque::Shared - Shared-memory double-ended queue for Linux

=head1 SYNOPSIS

    use Data::Deque::Shared;
    use feature 'say';

    my $dq = Data::Deque::Shared::Int->new(undef, 100);
    $dq->push_back(1);
    $dq->push_back(2);
    $dq->push_front(0);
    say $dq->pop_front;   # 0
    say $dq->pop_back;    # 2

    # String variant (fixed max_len per entry)
    my $sq = Data::Deque::Shared::Str->new(undef, 100, 64);
    $sq->push_back("hello");
    say $sq->pop_front;   # hello

    # blocking with timeout
    $dq->push_back_wait(42, 5.0);
    my $v = $dq->pop_front_wait(5.0);

    # file-backed / memfd
    $dq = Data::Deque::Shared::Int->new('/tmp/dq.shm', 100);
    $dq = Data::Deque::Shared::Int->new_memfd("my_dq", 100);
    my $fd = $dq->memfd;
    $dq = Data::Deque::Shared::Int->new_from_fd($fd);

=head1 DESCRIPTION

Double-ended queue (deque) in shared memory. Ring buffer with CAS-based
push/pop at both ends. Futex blocking when empty or full.

B<Linux-only>. Requires 64-bit Perl. Capacity must be E<lt>= 2^31.

Used only as a FIFO (C<push_back> + C<pop_front>), it's effectively a
fixed-slot lock-free string queue: 1.3x-4.7x faster than
L<Data::Queue::Shared::Str> under multi-producer contention, at the cost
of per-slot fixed memory (C<capacity x max_len>).

=head2 Concurrency

Push and pop are safe under multi-producer / multi-consumer workloads.
Each slot carries a 64-bit control word (state + generation) that acts
as a publication gate: a pusher atomically transitions the slot through
C<empty -> writing -> filled>, and a popper transitions it through
C<filled -> reading -> empty> with the generation bumped on completion.
A consumer that claims position C<n> via the head/tail CAS therefore
always observes the publication transition of the corresponding push
before reading the value.

C<drain> is safe under concurrent C<push>/C<pop>: it spin-waits on any
slot whose pusher is mid-publish, then releases each slot through the
state machine. If a pusher crashes after winning its position CAS but
before publishing the value (i.e. anywhere in the cursor-CAS to publish
window), drain waits ~2 seconds and then force-recovers the slot via
a generation bump (counted in C<stats-E<gt>{recoveries}>). A stalled-
but-live pusher whose slot was force-recovered will silently drop its
late publish rather than resurrect the slot as FILLED.

=head2 Compatibility

File format bumped to v2 in this release (per-slot control array added
for MPMC safety). Opening a v1 file (magic C<DEQ1>) created by
Data::Deque::Shared C<E<lt>= 0.02> will croak on header validation.
Re-create the deque with the new version; anonymous and memfd-backed
usage is unaffected.

=head1 METHODS

=head2 Constructors

There are two concrete subclasses; the base class C<Data::Deque::Shared>
is not instantiated directly.

C<Data::Deque::Shared::Int> stores 64-bit signed integers:

    my $dq = Data::Deque::Shared::Int->new($path, $capacity, $mode);
    my $dq = Data::Deque::Shared::Int->new_memfd($name, $capacity);
    my $dq = Data::Deque::Shared::Int->new_from_fd($fd);

C<Data::Deque::Shared::Str> stores byte/UTF-8 strings in fixed-size slots:

    my $sq = Data::Deque::Shared::Str->new($path, $capacity, $max_len, $mode);
    my $sq = Data::Deque::Shared::Str->new_memfd($name, $capacity, $max_len);
    my $sq = Data::Deque::Shared::Str->new_from_fd($fd);

For C<new>, C<$path> may be C<undef> for an anonymous (private) mapping,
or a filesystem path for a file-backed mapping shared across processes.
C<$capacity> is the number of slots (must be E<gt> 0 and E<lt>= 2^31); it is
rounded up to the next power of two, and C<capacity>/C<stats> report that
rounded value. For the Str variant, C<$max_len> is the maximum stored byte
length per entry (must be E<gt> 0 and E<lt> 2 GiB); longer values are truncated.
C<$mode> is an optional octal file permission mode applied only when a
backing file is created (default C<0600>); see L</SECURITY>.

C<new_memfd> creates an anonymous C<memfd> sealed mapping named C<$name>;
retrieve its descriptor with C<memfd> and re-attach in another process
(after passing the fd across, e.g. via C<SCM_RIGHTS>) with C<new_from_fd>.

All constructors croak on failure.

=head2 Push / Pop

    $dq->push_back($val);          $dq->push_front($val);
    $dq->push_back_wait($val, $t); $dq->push_front_wait($val, $t);
    my $v = $dq->pop_front;        my $v = $dq->pop_back;
    my $v = $dq->pop_front_wait($t); my $v = $dq->pop_back_wait($t);

The non-blocking C<push_back> / C<push_front> return true on success and
false if the deque is full. C<pop_front> / C<pop_back> return the value,
or C<undef> if the deque is empty.

The C<*_wait> variants block until the operation can proceed or the
optional timeout C<$t> (fractional seconds; omitted or negative means
wait forever) elapses. C<push_*_wait> return true on success, false on
timeout; C<pop_*_wait> return the value, or C<undef> on timeout.

=head2 Status

    $dq->size;  $dq->capacity;  $dq->is_empty;  $dq->is_full;
    $dq->clear;    # NOT concurrency-safe
    my $n = $dq->drain;  # concurrency-safe, returns count drained
    $dq->stats;    # {size, capacity, pushes, pops, waits, timeouts, recoveries, mmap_size}

=head2 Common

    $dq->path;  $dq->memfd;  $dq->sync;  $dq->unlink;

=head2 eventfd

    $dq->eventfd;  $dq->notify;  $dq->eventfd_consume;
    $dq->eventfd_set($fd);  $dq->fileno;

=head1 STATS

C<stats()> returns: C<size>, C<capacity>, C<pushes>, C<pops>,
C<waits>, C<timeouts>, C<recoveries>, C<mmap_size>.
C<recoveries> counts slots that drain force-skipped because a pusher
crashed (or stalled > 2s) between winning the cursor CAS and
publishing the value.

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default, so only the
creating user can open and attach them. To share a backing file across users,
pass an explicit octal file mode such as C<0660> as the last argument to C<new>; the mode is applied
only when the file is created (an existing file keeps its own permissions). The
file is opened with C<O_NOFOLLOW>, so a symlink planted at the path is refused,
and created with C<O_EXCL>; the on-disk header is validated when the file is
attached. Any process you grant write access to a shared mapping is trusted not
to corrupt its contents while other processes are using it.

=head1 BENCHMARKS

Single-process (1M ops, x86_64 Linux, Perl 5.40):

    push_back + pop_front (FIFO)    6.5M/s
    push_back + pop_back (LIFO)     6.3M/s
    push_front + pop_front (LIFO)   6.4M/s
    push_front + pop_back (FIFO)    6.5M/s

Multi-process (8 workers, 200K ops each):

    cap=16     5.7M/s aggregate
    cap=64     5.9M/s aggregate
    cap=256    5.8M/s aggregate

=head1 SEE ALSO

L<Data::Stack::Shared> - LIFO stack

L<Data::Queue::Shared> - FIFO queue

L<Data::ReqRep::Shared> - request-reply

L<Data::Pool::Shared> - fixed-size object pool

L<Data::Log::Shared> - append-only log (WAL)

L<Data::Buffer::Shared> - typed shared array

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
