package Data::Deque::Shared;
use strict;
use warnings;
our $VERSION = '0.02';
require XSLoader;
XSLoader::load('Data::Deque::Shared', $VERSION);
@Data::Deque::Shared::Int::ISA = ('Data::Deque::Shared');
1;
__END__

=encoding utf-8

=head1 NAME

Data::Deque::Shared - Shared-memory double-ended queue for Linux

=head1 SYNOPSIS

    use Data::Deque::Shared;

    my $dq = Data::Deque::Shared::Int->new(undef, 100);
    $dq->push_back(1);
    $dq->push_back(2);
    $dq->push_front(0);
    say $dq->pop_front;   # 0
    say $dq->pop_back;    # 2

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

B<Linux-only>. Requires 64-bit Perl.

=head1 METHODS

=head2 Push / Pop

    $dq->push_back($val);          $dq->push_front($val);
    $dq->push_back_wait($val, $t); $dq->push_front_wait($val, $t);
    my $v = $dq->pop_front;        my $v = $dq->pop_back;
    my $v = $dq->pop_front_wait($t); my $v = $dq->pop_back_wait($t);

=head2 Status

    $dq->size;  $dq->capacity;  $dq->is_empty;  $dq->is_full;
    $dq->clear;    # NOT concurrency-safe
    my $n = $dq->drain;  # concurrency-safe, returns count drained
    $dq->stats;    # {size, capacity, pushes, pops, waits, timeouts, mmap_size}

=head2 Common

    $dq->path;  $dq->memfd;  $dq->sync;  $dq->unlink;

=head2 eventfd

    $dq->eventfd;  $dq->notify;  $dq->eventfd_consume;
    $dq->eventfd_set($fd);  $dq->fileno;

=head1 STATS

C<stats()> returns: C<size>, C<capacity>, C<pushes>, C<pops>,
C<waits>, C<timeouts>, C<mmap_size>.

=head1 SECURITY

The mmap region is writable by all processes that open it.
Do not share backing files with untrusted processes.

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

=head1 AUTHOR

vividsnow

=head1 LICENSE

Same terms as Perl itself.

=cut
