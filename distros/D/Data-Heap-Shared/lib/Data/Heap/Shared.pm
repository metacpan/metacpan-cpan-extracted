package Data::Heap::Shared;
use strict;
use warnings;
our $VERSION = '0.07';
require XSLoader;
XSLoader::load('Data::Heap::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::Heap::Shared - Shared-memory binary min-heap (priority queue) for Linux

=head1 SYNOPSIS

    use Data::Heap::Shared;

    my $heap = Data::Heap::Shared->new(undef, 1000);
    $heap->push(3, 300);   # priority=3, value=300
    $heap->push(1, 100);
    $heap->push(2, 200);

    my ($pri, $val) = $heap->pop;   # (1, 100) -- lowest priority first
    my ($pri, $val) = $heap->peek;  # (2, 200) -- without removing

    # blocking pop
    my ($pri, $val) = $heap->pop_wait(5.0);

=head1 DESCRIPTION

Binary min-heap in shared memory. Elements are C<(priority, value)>
integer pairs. Lowest priority pops first.

Mutex-protected push/pop with sift-up/sift-down. PID-based stale
mutex recovery. Futex blocking when empty.

B<Crash safety>: if a process dies while holding the heap mutex
(mid-push or mid-pop), the mutex is recovered via PID detection,
but the heap data may be in an inconsistent state (partially
sifted). Callers should C<clear> and rebuild if crash recovery
is triggered in a critical application.

B<Linux-only>. Requires 64-bit Perl.

=head1 CONSTRUCTORS

=head2 new

    my $heap = Data::Heap::Shared->new($path, $capacity);
    my $heap = Data::Heap::Shared->new($path, $capacity, $mode);
    my $heap = Data::Heap::Shared->new(undef, $capacity);

Create or attach a heap. C<$capacity> is the maximum number of
elements. If C<$path> is a defined filename, the heap is backed by
that file (created if absent, attached if present). If C<$path> is
C<undef>, an anonymous mapping is used -- it has no backing file but is
C<MAP_SHARED>, so it is inherited across C<fork> and shared with child
processes (an unrelated process simply cannot attach it).

The optional C<$mode> is an octal permission mask applied only when
the backing file is created; it defaults to C<0600> (owner-only).
See L</SECURITY>.

Croaks on error (bad capacity, permission denied, header mismatch,
etc.).

=head2 new_memfd

    my $heap = Data::Heap::Shared->new_memfd($name, $capacity);

Create an anonymous heap backed by a Linux C<memfd>. C<$name> is a
label for debugging (as shown in C</proc>). The underlying file
descriptor can be retrieved with L</memfd> and passed to another
process (e.g. over a unix socket or by inheritance) which attaches
with L</new_from_fd>. Croaks on error.

=head2 new_from_fd

    my $heap = Data::Heap::Shared->new_from_fd($fd);

Attach to an existing heap given an open file descriptor for its
backing store (typically obtained from L</memfd> in another process).
The header is validated on attach. Croaks on error.

=head1 METHODS

=head2 push

    my $ok = $heap->push($priority, $value);

Insert a C<($priority, $value)> integer pair. Returns true on
success, or false if the heap is full (see L</is_full>). Wakes one
blocked L</pop_wait> waiter.

=head2 pop

    my ($pri, $val) = $heap->pop;

Remove and return the lowest-priority element as a C<($priority,
$value)> pair. Returns the empty list if the heap is empty.

=head2 pop_wait

    my ($pri, $val) = $heap->pop_wait;         # block forever
    my ($pri, $val) = $heap->pop_wait($secs);  # block up to $secs
    my ($pri, $val) = $heap->pop_wait(0);      # non-blocking

Like L</pop>, but blocks (via futex) until an element is available.
With no argument (or a negative timeout) it blocks indefinitely. A
timeout of C<0> polls without blocking. A positive fractional
C<$secs> bounds the wait; on timeout the empty list is returned.

=head2 peek

    my ($pri, $val) = $heap->peek;

Return the lowest-priority element without removing it. Returns the
empty list if the heap is empty.

=head2 size

    my $n = $heap->size;

Current number of elements.

=head2 capacity

    my $cap = $heap->capacity;

Maximum number of elements (fixed at creation).

=head2 is_empty

    my $bool = $heap->is_empty;

True if C<< size == 0 >>.

=head2 is_full

    my $bool = $heap->is_full;

True if C<< size >= capacity >>.

=head2 clear

    $heap->clear;

Remove all elements (resets size to zero).

=head2 path

    my $p = $heap->path;

The backing file path, or C<undef> for anonymous / memfd heaps.

=head2 memfd

    my $fd = $heap->memfd;

The backing file descriptor: the C<memfd> of a L</new_memfd> heap, or the
dup'd fd of a L</new_from_fd> heap. Such an fd can be shared with another
process which attaches via L</new_from_fd>. Returns -1 for file-backed and
anonymous heaps, which keep no shareable descriptor.

=head2 sync

    $heap->sync;

Flush the mapping to the backing file with C<msync>. Croaks on error.
No effect for anonymous heaps.

=head2 unlink

    $heap->unlink;
    Data::Heap::Shared->unlink($path);

Remove the backing file from the filesystem. Called as an instance
method it unlinks the heap's own path; called as a class method it
unlinks the given C<$path>. Croaks for anonymous / memfd heaps (no
path) or on unlink failure. The mapping stays valid until all
handles are destroyed.

=head2 stats

    my $stats = $heap->stats;

Return a hashref with the keys C<size>, C<capacity>, C<pushes>,
C<pops>, C<waits>, C<timeouts>, C<recoveries>, and C<mmap_size>.
The counters are cumulative across all processes sharing the heap.

=head1 EVENTFD NOTIFICATION

An optional C<eventfd> lets an event loop (e.g. L<EV>, L<AnyEvent>,
L<IO::Async>) wake when the heap is written, instead of blocking in
L</pop_wait>.

=head2 eventfd

    my $fd = $heap->eventfd;

Create (or return) an eventfd associated with this handle and return
its file descriptor. Watch it for readability; readiness means
L</notify> was called. Croaks on error.

=head2 eventfd_set

    $heap->eventfd_set($fd);

Use a caller-supplied file descriptor for notification instead of
one created by L</eventfd>. Any previously-owned eventfd is closed.
B<The heap takes ownership of C<$fd>>: it is closed on the next
C<eventfd_set> and when the heap is destroyed, so pass a C<dup(2)> of
the descriptor if you need to keep using your own copy.

=head2 fileno

    my $fd = $heap->fileno;

The current notification file descriptor, or -1 if none is set.

=head2 notify

    $heap->notify;

Signal the notification fd (write to the eventfd), making it
readable. Returns true if a notification was delivered.

=head2 eventfd_consume

    my $count = $heap->eventfd_consume;

Read and clear the eventfd counter, returning the accumulated count,
or C<undef> if there was nothing to read.

=head1 BENCHMARKS

Single-process (500K ops, x86_64 Linux, Perl 5.40):

    push (sequential)       5.3M/s
    pop (drain)             2.5M/s
    push+pop (interleaved)  2.5M/s
    peek                    4.9M/s

Multi-process (4 workers, 100K ops each, cap=64):

    push+pop                3.1M/s aggregate

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default, so only the
creating user can open and attach them. To share a backing file across users,
pass an explicit octal file mode such as C<0660> as the last argument to C<new>; the mode is applied
only when the file is created (an existing file keeps its own permissions). The
file is opened with C<O_NOFOLLOW>, so a symlink planted at the path is refused,
and created with C<O_EXCL>; the on-disk header is validated when the file is
attached. Any process you grant write access to a shared mapping is trusted not
to corrupt its contents while other processes are using it.

=head1 SEE ALSO

L<Data::Stack::Shared> - LIFO stack

L<Data::Deque::Shared> - double-ended queue

L<Data::Queue::Shared> - FIFO queue

L<Data::ReqRep::Shared> - request-reply

L<Data::Pool::Shared> - fixed-size object pool

L<Data::Log::Shared> - append-only log (WAL)

L<Data::Buffer::Shared> - typed shared array

L<Data::Sync::Shared> - synchronization primitives

L<Data::HashMap::Shared> - concurrent hash table

L<Data::PubSub::Shared> - publish-subscribe ring

L<Data::Graph::Shared> - directed weighted graph

L<Data::BitSet::Shared> - shared bitset (lock-free per-bit ops)

L<Data::RingBuffer::Shared> - fixed-size overwriting ring buffer

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
