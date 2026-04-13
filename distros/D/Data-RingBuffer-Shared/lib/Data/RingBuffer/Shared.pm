package Data::RingBuffer::Shared;
use strict;
use warnings;
our $VERSION = '0.01';
require XSLoader;
XSLoader::load('Data::RingBuffer::Shared', $VERSION);
@Data::RingBuffer::Shared::Int::ISA = ('Data::RingBuffer::Shared');
@Data::RingBuffer::Shared::F64::ISA = ('Data::RingBuffer::Shared');

sub to_list {
    my ($self) = @_;
    my $sz = $self->size;
    return () unless $sz;
    grep { defined } map { $self->latest($sz - 1 - $_) } 0 .. $sz - 1;
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

    # overwrites oldest when full — never blocks
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
oldest entry when the buffer is full — writes never block or fail.
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

=head2 Write

    my $seq = $ring->write($value);  # returns sequence number

Always succeeds. Overwrites oldest when full.

=head2 Read

    my $val = $ring->latest;       # most recent (undef if empty)
    my $val = $ring->latest($n);   # nth most recent (0=latest)
    my $val = $ring->read_seq($s); # by sequence (undef if overwritten)

    my @all = $ring->to_list;      # entire ring, oldest first

=head2 Status

    $ring->size;       # entries in buffer (max = capacity)
    $ring->capacity;
    $ring->head;       # next write position (monotonic)
    $ring->count;      # total writes (for wait_for)

=head2 Waiting

    my $ok = $ring->wait_for($expected_count);          # block until count changes
    my $ok = $ring->wait_for($expected_count, $timeout);

Returns 1 if new data arrived (count != expected), 0 on timeout.

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
    Int read_seq    10.4M/s
    F64 write        8.8M/s
    F64 latest      12.0M/s

=head1 STATS

C<stats()> returns a hashref: C<size>, C<capacity>, C<head>, C<count>,
C<writes>, C<overwrites>, C<mmap_size>.

=head1 SECURITY

The mmap region is writable by all processes that open it.
Do not share backing files with untrusted processes.

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

Same terms as Perl itself.

=cut
