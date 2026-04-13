package Data::Queue::Shared;
use strict;
use warnings;
our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Data::Queue::Shared', $VERSION);

# Keyword API hint activation (requires XS::Parse::Keyword)
sub _enable_keywords {
    my ($pkg, @kws) = @_;
    $^H{"$pkg/$_"} = 1 for @kws;
}

for my $variant (qw(Int Int32 Int16 Str)) {
    my $lc = lc $variant;
    my $pkg = "Data::Queue::Shared::$variant";
    my @kws = map { "q_${lc}_$_" } qw(push pop peek size);
    no strict 'refs';
    *{"${pkg}::import"} = sub {
        my $class = shift;
        return unless $Data::Queue::Shared::HAVE_KEYWORDS;
        _enable_keywords($pkg, @kws);
    };
    *{"${pkg}::unimport"} = sub {
        my $class = shift;
        delete $^H{"$pkg/$_"} for @kws;
    };
}

1;

__END__

=encoding utf-8

=head1 NAME

Data::Queue::Shared - High-performance shared-memory MPMC queues for Linux

=head1 SYNOPSIS

    use Data::Queue::Shared;

    # Integer queue (lock-free Vyukov MPMC)
    my $q = Data::Queue::Shared::Int->new('/tmp/myq.shm', 1024);

    # Anonymous queue (fork-inherited, no filesystem)
    my $q = Data::Queue::Shared::Int->new(undef, 1024);

    # memfd-backed queue (shareable via fd passing)
    my $q = Data::Queue::Shared::Str->new_memfd("my_queue", 1024);
    my $fd = $q->memfd;  # pass via SCM_RIGHTS or fork
    my $q2 = Data::Queue::Shared::Str->new_from_fd($fd);
    $q->push(42);
    my $val = $q->pop;              # non-blocking, undef if empty

    # Blocking pop (waits for data)
    my $val = $q->pop_wait;         # infinite wait
    my $val = $q->pop_wait(1.5);    # 1.5 second timeout

    # Batch operations
    my $pushed = $q->push_multi(1, 2, 3, 4, 5);
    my @vals = $q->pop_multi(10);   # pop up to 10

    # String queue (mutex-protected, circular arena)
    my $sq = Data::Queue::Shared::Str->new('/tmp/strq.shm', 1024);
    $sq->push("hello world");
    my $msg = $sq->pop;

    # With explicit arena size (default: capacity * 256)
    my $sq = Data::Queue::Shared::Str->new('/tmp/strq.shm', 1024, 1048576);

    # Multiprocess
    if (fork() == 0) {
        my $child = Data::Queue::Shared::Int->new('/tmp/myq.shm', 1024);
        $child->push(99);
        exit;
    }
    wait;
    print $q->pop;  # 99

=head1 DESCRIPTION

Data::Queue::Shared provides bounded MPMC (multi-producer, multi-consumer)
queues stored in file-backed shared memory (C<mmap(MAP_SHARED)>), enabling
efficient multiprocess data sharing on Linux.

B<Linux-only>. Requires 64-bit Perl.

=head2 Variants

=over

=item L<Data::Queue::Shared::Int> - int64 values, lock-free (16 bytes/slot)

Uses the Vyukov bounded MPMC algorithm. Push and pop are lock-free
(CAS-based). Optimal for integer job IDs, counters, indices.

=item L<Data::Queue::Shared::Int32> - int32 values, lock-free (8 bytes/slot)

=item L<Data::Queue::Shared::Int16> - int16 values, lock-free (8 bytes/slot)

Compact variants with 32-bit Vyukov sequence numbers. Half the memory
footprint per slot = double the cache density. Same lock-free algorithm.
Same API as Int. Values outside the type range are silently truncated
(standard C cast semantics).

=item L<Data::Queue::Shared::Str> - byte string values, mutex-protected

Uses a futex-based mutex with a circular arena for variable-length string
storage. Supports UTF-8 flag preservation. Optimal for messages,
serialized data, filenames.

=back

=head2 Features

=over

=item * File-backed mmap for cross-process sharing

=item * Lock-free MPMC for integer queues (Vyukov algorithm)

=item * Futex-based blocking wait with timeout (no busy-spin)

=item * PID-based stale lock recovery (dead process detection)

=item * Batch push/pop operations

=item * Circular arena for zero-fragmentation string storage

=item * Optional keyword API via XS::Parse::Keyword (zero method-dispatch overhead)

=back

=head2 Constructor

    # Int queue
    my $q = Data::Queue::Shared::Int->new($path, $capacity);

    # Str queue
    my $q = Data::Queue::Shared::Str->new($path, $capacity);
    my $q = Data::Queue::Shared::Str->new($path, $capacity, $arena_bytes);

Creates or opens a shared queue backed by file C<$path>.
C<$capacity> is rounded up to the next power of 2.
When opening an existing file, parameters are read from the stored header.
Multiple processes can open the same file simultaneously.

Pass C<undef> for C<$path> to create an anonymous queue using
C<MAP_SHARED|MAP_ANONYMOUS>. Anonymous queues are shared with child
processes via C<fork()> but cannot be opened by unrelated processes.

=head2 memfd Constructor

    my $q = Data::Queue::Shared::Int->new_memfd($name, $capacity);
    my $q = Data::Queue::Shared::Str->new_memfd($name, $capacity);
    my $q = Data::Queue::Shared::Str->new_memfd($name, $cap, $arena);

Creates a queue backed by C<memfd_create(2)>. No filesystem path — the
backing memory is identified by a file descriptor. Use C<memfd()> to
retrieve the fd and pass it to other processes via C<SCM_RIGHTS>
(Unix domain socket fd passing) or C<fork()> inheritance.

    my $q2 = Data::Queue::Shared::Int->new_from_fd($fd);
    my $q2 = Data::Queue::Shared::Str->new_from_fd($fd);

Opens a queue from a received memfd. The fd is dup'd internally.

    my $fd = $q->memfd;    # backing fd (-1 if file-backed/anonymous)

For Str queues, C<$arena_bytes> sets the string storage arena size
(default: C<$capacity * 256>, minimum 4096, maximum 4GB). Strings are
stored in a circular arena; total stored string bytes cannot exceed the
arena capacity. Individual strings are limited to ~2GB.

=head2 API

=head3 Core operations

    my $ok  = $q->push($value);             # non-blocking, false if full
    my $val = $q->pop;                       # non-blocking, undef if empty
    my $ok  = $q->push_wait($value);         # blocking, infinite wait
    my $ok  = $q->push_wait($value, $secs);  # blocking with timeout
    my $val = $q->pop_wait;                  # blocking, infinite wait
    my $val = $q->pop_wait($secs);           # blocking with timeout
    my $val = $q->peek;                      # read front without consuming

C<peek> returns the front element without removing it (C<undef> if empty).
For Int, this is a best-effort snapshot (racy in concurrent MPMC).
For Str, this is exact (mutex-protected).

=head3 Deque operations (Str only)

    my $ok  = $q->push_front($value);           # non-blocking push to front
    my $ok  = $q->push_front_wait($value);       # blocking push to front
    my $ok  = $q->push_front_wait($val, $secs);  # with timeout
    my $val = $q->pop_back;                 # non-blocking pop from back
    my $val = $q->pop_back_wait;            # blocking pop from back
    my $val = $q->pop_back_wait($timeout);  # with timeout

C<push_front> inserts at the head — useful for requeueing failed jobs.
C<pop_back> removes from the tail — useful for work-stealing or undo.
Not available for Int (Vyukov algorithm is strictly FIFO).

=head3 Batch operations

    my $n  = $q->push_multi(@values);          # non-blocking, returns pushed count
    my @v  = $q->pop_multi($count);            # non-blocking, pop up to $count
    my $n  = $q->push_wait_multi($timeout, @values);  # blocking batch push
    my @v  = $q->pop_wait_multi($n, $timeout); # block for >=1, grab up to $n
    my @v  = $q->drain;                        # pop all elements
    my @v  = $q->drain($max);                  # pop up to $max elements

C<pop_wait_multi> blocks until at least one element is available (or timeout),
then grabs up to C<$n> elements non-blocking. Returns empty list on timeout.

C<push_wait_multi> pushes all values, blocking if the queue is full.
C<$timeout> is seconds (C<-1> = infinite, C<0> = try once).

=head3 Status

    my $n   = $q->size;         # approximate for Int (lock-free), exact for Str
    my $cap = $q->capacity;     # max elements
    my $ok  = $q->is_empty;
    my $ok  = $q->is_full;

=head3 Management

    $q->clear;                  # remove all elements
    $q->sync;                   # msync — flush to disk for crash durability
    $q->unlink;                 # remove backing file
    Class->unlink($path);       # class method form
    my $p = $q->path;           # backing file path
    my $s = $q->stats;          # diagnostic hashref

Stats keys: C<size>, C<capacity>, C<mmap_size>, C<push_ok>, C<pop_ok>,
C<push_full>, C<pop_empty>, C<recoveries>, C<push_waiters>, C<pop_waiters>.
Str queues additionally include C<arena_cap> and C<arena_used>.
All counters are approximate under concurrent access (diagnostic only).
C<push_waiters>/C<pop_waiters> show currently blocked producers/consumers.

=head2 Event Loop Integration (eventfd)

    my $fd = $q->eventfd;           # create eventfd, returns fd number
    $q->eventfd_set($fd);           # use an existing fd (e.g. inherited via fork)
    my $fd = $q->fileno;            # current eventfd (-1 if none)
    $q->notify;                     # signal eventfd (call after push)
    $q->eventfd_consume;            # drain notification counter

Notification is B<opt-in>: C<push> does not write to the eventfd
automatically. Call C<notify> explicitly after pushing. This gives full
control over batching (push N items, notify once) and avoids any overhead
when eventfd is not used.

    use EV;
    my $q = Data::Queue::Shared::Str->new($path, 1024);
    my $fd = $q->eventfd;
    my $w = EV::io $fd, EV::READ, sub {
        $q->eventfd_consume;
        while (defined(my $item = $q->pop)) {
            process($item);
        }
    };
    # Producer side:
    $q->push($item);
    $q->notify;   # wake the EV watcher
    EV::run;

For cross-process notification, create the eventfd B<before> C<fork()>.
Child processes inherit the fd and should call C<eventfd_set($fd)> on
their queue handle. Writes from any process sharing the fd will wake
all event-loop watchers.

=head2 Crash Safety

If a process dies while holding the Str queue mutex, other processes
detect the stale lock within 2 seconds via PID tracking and automatically
recover. The Int queue is lock-free and requires no crash recovery for
normal push/pop operations.

=head2 Keyword API

When L<XS::Parse::Keyword> is installed at build time, keyword forms
are available that bypass method dispatch:

    use Data::Queue::Shared::Int;    # activates q_int_* keywords

    q_int_push $q, $value;
    my $val = q_int_pop $q;
    my $val = q_int_peek $q;
    my $n   = q_int_size $q;

Replace C<int> with C<int32>, C<int16>, or C<str> for other variants.
Keywords are lexically scoped and require C<use> (not C<require>).

=head1 BENCHMARKS

Throughput versus other Perl queue/IPC modules, 200K items,
single process and cross-process, Linux x86_64.
Run C<perl -Mblib bench/vs.pl 200000> to reproduce.

    SINGLE-PROCESS INTEGER PUSH+POP (interleaved)
                               Rate
    Data::Queue::Shared::Int  5.0M/s
    MCE::Queue                1.8M/s
    POSIX::RT::MQ             806K/s
    IPC::Msg (SysV)           802K/s
    IPC::Transit               58K/s
    Forks::Queue (Shmem)       11K/s

    SINGLE-PROCESS STRING PUSH+POP (~50B, interleaved)
                               Rate
    Data::Queue::Shared::Str  2.6M/s
    MCE::Queue                1.5M/s
    POSIX::RT::MQ             990K/s
    IPC::Msg (SysV)           857K/s
    Forks::Queue (Shmem)       11K/s

    BATCH PUSH+POP (100 per batch, integers)
                               Rate
    Shared::Int push_multi    14.9M/s
    MCE::Queue                 4.5M/s

    CROSS-PROCESS (1 producer + 1 consumer, integers)
                               Rate
    Shared::Int               6.0M/s
    MCE::Queue                4.1M/s
    POSIX::RT::MQ             1.2M/s
    IPC::Msg (SysV)           956K/s
    Forks::Queue (Shmem)        4K/s

Key takeaways:

=over

=item * B<2.8x> faster than MCE::Queue for single-process integer ops

=item * B<1.5x> faster than MCE::Queue for cross-process integers

=item * B<6x> faster than kernel IPC (POSIX mq / SysV msgq)

=item * B<3.3x> faster batch ops (single mutex hold vs per-item)

=item * True concurrent MPMC (MCE::Queue is workers-to-manager only)

=back

=head1 SEE ALSO

L<Data::Buffer::Shared> - typed shared array

L<Data::HashMap::Shared> - concurrent hash table

L<Data::PubSub::Shared> - publish-subscribe ring

L<Data::ReqRep::Shared> - request-reply

L<Data::Sync::Shared> - synchronization primitives

L<Data::Pool::Shared> - fixed-size object pool

L<Data::Stack::Shared> - LIFO stack

L<Data::Deque::Shared> - double-ended queue

L<Data::Log::Shared> - append-only log (WAL)

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
