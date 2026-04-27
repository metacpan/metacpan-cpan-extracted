package Data::Heap::Shared;
use strict;
use warnings;
our $VERSION = '0.03';
require XSLoader;
XSLoader::load('Data::Heap::Shared', $VERSION);
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

    my ($pri, $val) = $heap->pop;   # (1, 100) — lowest priority first
    my ($pri, $val) = $heap->peek;  # (2, 200) — without removing

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

=head1 METHODS

    $heap->push($priority, $value);          # returns bool
    my ($pri, $val) = $heap->pop;            # returns () if empty
    my ($pri, $val) = $heap->pop_wait;       # blocking
    my ($pri, $val) = $heap->pop_wait($t);   # with timeout
    my ($pri, $val) = $heap->peek;           # without removing

    $heap->size;  $heap->capacity;  $heap->is_empty;  $heap->is_full;
    $heap->clear;  $heap->stats;  $heap->path;  $heap->memfd;
    $heap->sync;   $heap->unlink;

    # constructors
    $heap = Data::Heap::Shared->new_memfd($name, $capacity);
    $heap = Data::Heap::Shared->new_from_fd($fd);

    # eventfd
    $heap->eventfd;  $heap->eventfd_set($fd);  $heap->fileno;
    $heap->notify;   $heap->eventfd_consume;

=head1 STATS

C<stats()> returns: C<size>, C<capacity>, C<pushes>, C<pops>,
C<waits>, C<timeouts>, C<recoveries>, C<mmap_size>.

=head1 BENCHMARKS

Single-process (500K ops, x86_64 Linux, Perl 5.40):

    push (sequential)       5.3M/s
    pop (drain)             2.5M/s
    push+pop (interleaved)  2.5M/s
    peek                    4.9M/s

Multi-process (4 workers, 100K ops each, cap=64):

    push+pop                3.1M/s aggregate

=head1 SECURITY

The mmap region is writable by all processes that open it.
Do not share backing files with untrusted processes.

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
