package Data::Stack::Shared;
use strict;
use warnings;
our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Data::Stack::Shared', $VERSION);

@Data::Stack::Shared::Int::ISA = ('Data::Stack::Shared');
@Data::Stack::Shared::Str::ISA = ('Data::Stack::Shared');

1;

__END__

=encoding utf-8

=head1 NAME

Data::Stack::Shared - Shared-memory LIFO stack for Linux

=head1 SYNOPSIS

    use Data::Stack::Shared;

    my $stk = Data::Stack::Shared::Int->new(undef, 100);
    $stk->push(42);
    $stk->push(99);
    say $stk->pop;       # 99 (LIFO)
    say $stk->peek;      # 42
    say $stk->size;      # 1

    # blocking with timeout
    $stk->push_wait(42, 5.0);
    my $val = $stk->pop_wait(5.0);

    # string variant
    my $ss = Data::Stack::Shared::Str->new(undef, 50, 256);
    $ss->push("hello");
    say $ss->pop;

    # anonymous / memfd / file-backed
    my $s = Data::Stack::Shared::Int->new('/tmp/stk.shm', 100);
    $s = Data::Stack::Shared::Int->new(undef, 100);
    $s = Data::Stack::Shared::Int->new_memfd("my_stk", 100);
    my $fd = $s->memfd;
    $s = Data::Stack::Shared::Int->new_from_fd($fd);

=head1 DESCRIPTION

LIFO stack in shared memory. CAS-based lock-free push/pop on an
atomic top index. Futex blocking when empty or full.

B<Linux-only>. Requires 64-bit Perl.

=head2 Variants

=over

=item C<Data::Stack::Shared::Int> - int64_t values

=item C<Data::Stack::Shared::Str> - fixed-length strings

=back

=head1 METHODS

=head2 Push / Pop

    my $ok  = $stk->push($val);               # non-blocking
    $ok     = $stk->push_wait($val);           # blocking (infinite)
    $ok     = $stk->push_wait($val, $timeout); # blocking with timeout

    my $val = $stk->pop;                       # non-blocking, undef if empty
    $val    = $stk->pop_wait;                  # blocking (infinite)
    $val    = $stk->pop_wait($timeout);        # blocking with timeout

    $val    = $stk->peek;                      # read top without removing

=head2 Status

    my $n   = $stk->size;
    my $cap = $stk->capacity;
    my $ok  = $stk->is_empty;
    my $ok  = $stk->is_full;
    $stk->clear;                               # empty (NOT concurrency-safe)
    my $n = $stk->drain;                       # empty (concurrency-safe, returns count)

=head2 Common

    my $p  = $stk->path;
    my $fd = $stk->memfd;
    $stk->sync;
    $stk->unlink;
    my $s  = $stk->stats;

=head2 eventfd

    my $fd = $stk->eventfd;
    $stk->eventfd_set($fd);
    my $fd = $stk->fileno;
    $stk->notify;
    my $n  = $stk->eventfd_consume;

=head1 STATS

C<stats()> returns: C<size>, C<capacity>, C<pushes>, C<pops>,
C<waits>, C<timeouts>, C<mmap_size>.

=head1 SECURITY

The mmap region is writable by all processes that open it.
Do not share backing files with untrusted processes.

=head1 BENCHMARKS

Single-process (1M ops, x86_64 Linux, Perl 5.40):

    Int push + pop          6.4M/s
    Int push (fill) + pop   6.4M/s
    Int peek               13.0M/s
    Str push + pop (48B)    4.7M/s

Multi-process (8 workers, 200K ops each, cap=64):

    Int push + pop          5.0M/s aggregate

=head1 SEE ALSO

L<Data::Deque::Shared> - double-ended queue (deque)

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

=head1 AUTHOR

vividsnow

=head1 LICENSE

Same terms as Perl itself.

=cut
