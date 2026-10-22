package Data::RingBuffer::Shared;
use strict;
use warnings;
our $VERSION = '0.08';
require XSLoader;
XSLoader::load('Data::RingBuffer::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
@Data::RingBuffer::Shared::Int::ISA = ('Data::RingBuffer::Shared');
@Data::RingBuffer::Shared::F64::ISA = ('Data::RingBuffer::Shared');

sub to_list {
    my ($self) = @_;
    my $head = $self->head;
    return () unless $head;
    my $cap = $self->capacity;
    my $oldest = $head > $cap ? $head - $cap : 0;
    grep { defined } map { $self->read_seq($_) } $oldest .. $head - 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::RingBuffer::Shared - Shared-memory fixed-size ring buffer for Linux

=head1 SYNOPSIS

    use Data::RingBuffer::Shared;

    my $ring = Data::RingBuffer::Shared::Int->new(undef, 100);
    $ring->write(42);
    $ring->write(99);
    say $ring->latest;        # 99 (most recent)
    say $ring->latest(1);     # 42 (previous)
    say $ring->size;          # 2

    # overwrites oldest when full
    $ring->write($_) for 1..200;
    say $ring->size;          # 100 (capacity)
    say $ring->latest;        # 200

    # read by sequence number
    my $seq = $ring->write(777);
    say $ring->read_seq($seq);  # 777

    # wait for new data
    my $cnt = $ring->count;
    $ring->wait_for($cnt, 5.0);

    # F64 variant
    my $f = Data::RingBuffer::Shared::F64->new(undef, 1000);
    $f->write(3.14);

    # dump entire ring as list (oldest first)
    my @vals = $ring->to_list;

=head1 DESCRIPTION

Fixed-size circular buffer in shared memory. Writes overwrite the
oldest entry when the buffer is full.
Readers access data by relative position (0=latest) or absolute
sequence number.

Unlike L<Data::Queue::Shared> (consumed on read, blocks when full)
and L<Data::PubSub::Shared> (subscription tracking), RingBuffer is
a simple overwriting window with no consumer state.

Useful for metrics rings, sensor data, rolling windows, debug traces.

B<Linux-only>. Requires 64-bit Perl.

=head2 Variants

=over

=item C<Data::RingBuffer::Shared::Int> - int64_t values

=item C<Data::RingBuffer::Shared::F64> - double values

=back

=head1 METHODS

=head2 Constructors

    $r = Data::RingBuffer::Shared::Int->new($path, $capacity);
    $r = Data::RingBuffer::Shared::Int->new(undef, $capacity);
    $r = Data::RingBuffer::Shared::Int->new_memfd($name, $cap);
    $r = Data::RingBuffer::Shared::Int->new_from_fd($fd);

The descriptor you pass to C<new_from_fd> is duplicated
(C<F_DUPFD_CLOEXEC>), so it stays yours to close and closing it does not
disturb the buffer.

C<new> and C<new_memfd> reserve the whole segment when they create one, so a
full filesystem makes them croak instead of the initialization dying with
SIGBUS; set C<DATA_RINGBUFFER_SHARED_SPARSE=1> to skip the reservation. On
tmpfs and memfd the segment is memory, and a memory cgroup too small for it
gets an OOM kill rather than a croak.

=head2 Write

    my $seq = $ring->write($value);  # returns sequence number

Returns a sequence number. Overwrites oldest when full.

=head2 Read

    my $val = $ring->latest;       # most recent (undef if empty)
    my $val = $ring->latest($n);   # nth most recent (0=latest)
    my $val = $ring->read_seq($s); # by sequence (undef if overwritten)

    my @all = $ring->to_list;      # starting window, oldest first

=head2 Status

    $ring->size;       # entries in buffer (max = capacity)
    $ring->capacity;
    $ring->head;       # next write position (monotonic)
    $ring->count;      # total writes (for wait_for)

=head2 Waiting

    my $ok = $ring->wait_for($expected_count);          # block until count changes
    my $ok = $ring->wait_for($expected_count, $timeout);

Returns 1 if new data arrived (count != expected), 0 on timeout. An omitted
or negative timeout waits indefinitely; Perl signal handlers run during waits.

=head2 Lifecycle

    $ring->clear;      # reset head/count (NOT concurrency-safe)
    $ring->sync;  $ring->unlink;  $ring->path;  $ring->memfd;
    $ring->stats;

=head2 eventfd

    $ring->eventfd;  $ring->eventfd_set($fd);  $ring->fileno;
    $ring->notify;   $ring->eventfd_consume;

=head1 BENCHMARKS

Single-process (1M ops, x86_64 Linux, Perl 5.40, cap=1000):

    Int write       11.7M/s
    Int latest      11.1M/s
    Int read_seq(stale) 10.4M/s
    F64 write        8.8M/s
    F64 latest      12.0M/s

=head1 STATS

C<stats()> returns a hashref: C<size>, C<capacity>, C<head>, C<count>,
C<writes>, C<overwrites>, C<mmap_size>.

=head1 CONCURRENCY AND CRASH SAFETY

Writers claim unique positions with an atomic increment of the head counter,
so multiple writer and reader processes may share one buffer concurrently.
Writers serialize on each slot using atomics; a stalled writer can delay another
writer until the recovery timeout. A full buffer overwrites the oldest slot.

Each slot carries a publication sequence used as a seqlock. A reader loads the
sequence, copies the value, then re-checks the sequence; if a write was in
progress or the slot has since been overwritten, the read is retried and
ultimately reports "no value" (C<latest> and C<read_seq> return C<undef>). A
reader therefore never observes a torn or half-written value.

If a writer crashes mid-write, its slot is left marked in-progress. Readers skip
that slot (returning C<undef>) rather than block, and after a short recovery
timeout a later writer reclaims the slot and overwrites the partial data. The
buffer as a whole stays usable. C<wait_for> blocks on a futex over an internal
wake counter, so a crashed waiter cannot stall writers either.

C<clear> is B<not> concurrency-safe: call it only when no other process is
using the buffer.

An interrupted create is recovered too. A creator killed after the backing
file is sized but before its header is committed leaves a full-size, all-zero
file. C<new> re-initializes such a file automatically, but only when it is
exactly the size the requested geometry needs, is owned by your effective uid,
and is still entirely zero -- a file holding data is never re-initialized. If
the creator got as far as writing part of the header, the file cannot be told
apart from a corrupt one and C<new> croaks with C<incomplete ring file left by
an interrupted create; remove it and retry>. A file left behind by an
interrupted create never held data, so removing it is safe -- but a file whose
header was corrupted after the fact reaches the same croak, so confirm it is
an abandoned create before deleting anything you care about.

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default, so only
the creating user can open and attach them. To share a backing file across
users, pass an explicit octal file mode such as C<0660> as the last argument
to C<new>; the mode is applied when the file is created, and when a file left
behind by an interrupted create is re-initialized (see L</CONCURRENCY AND
CRASH SAFETY>); a file already in use keeps its own permissions. The file is
opened with C<O_NOFOLLOW>, so a symlink planted at the path is refused, and
created with C<O_EXCL>; the on-disk header is validated when the file is
attached. Any process you grant write access to a shared mapping is trusted
not to corrupt its contents while other processes are using it.

=head1 SEE ALSO

L<Data::Queue::Shared> - FIFO queue (consumed on read)

L<Data::PubSub::Shared> - publish-subscribe ring (subscription tracking)

L<Data::Buffer::Shared> - typed shared array

L<Data::BitSet::Shared> - shared bitset

L<Data::Pool::Shared> - fixed-size object pool

L<Data::Stack::Shared> - LIFO stack

L<Data::Deque::Shared> - double-ended queue

L<Data::Log::Shared> - append-only log

L<Data::Heap::Shared> - priority queue

L<Data::Graph::Shared> - directed weighted graph

L<Data::Sync::Shared> - synchronization primitives

L<Data::HashMap::Shared> - concurrent hash table

L<Data::ReqRep::Shared> - request-reply

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
