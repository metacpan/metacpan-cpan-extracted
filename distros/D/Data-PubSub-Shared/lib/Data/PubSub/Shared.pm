package Data::PubSub::Shared;
use strict;
use warnings;
our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Data::PubSub::Shared', $VERSION);

sub _enable_keywords {
    my ($pkg, @kws) = @_;
    $^H{"$pkg/$_"} = 1 for @kws;
}

for my $variant (qw(Int Int32 Int16 Str)) {
    my $lc = lc $variant;
    my $pkg = "Data::PubSub::Shared::$variant";
    my @kws = map { "ps_${lc}_$_" } qw(publish poll lag);
    no strict 'refs';
    *{"${pkg}::import"} = sub {
        _enable_keywords($pkg, @kws);
    };
    *{"${pkg}::unimport"} = sub {
        delete $^H{"$pkg/$_"} for @kws;
    };
}

1;

__END__

=encoding utf-8

=head1 NAME

Data::PubSub::Shared - High-performance shared-memory pub/sub for Linux

=head1 SYNOPSIS

    use Data::PubSub::Shared;

    # Publisher
    my $ps = Data::PubSub::Shared::Int->new('/tmp/ps.shm', 1024);
    $ps->publish(42);
    $ps->publish_multi(1, 2, 3);

    # Subscriber (same or different process)
    my $ps2 = Data::PubSub::Shared::Int->new('/tmp/ps.shm', 1024);
    my $sub  = $ps2->subscribe;      # future messages only
    my $sub2 = $ps2->subscribe_all;  # from oldest available

    # Polling
    my $val = $sub->poll;            # non-blocking, undef if empty
    my @v   = $sub->drain;           # all available
    my $val = $sub->poll_wait(1.5);  # blocking with timeout

    # Callback-based (no per-message method dispatch)
    $sub->poll_cb(sub { process($_[0]) });

    # String variant
    my $sps = Data::PubSub::Shared::Str->new('/tmp/ps.shm', 1024);
    $sps->publish("hello world");

    # Compact variants (half the memory, same API)
    my $ps32 = Data::PubSub::Shared::Int32->new(undef, 65536);
    my $ps16 = Data::PubSub::Shared::Int16->new(undef, 65536);

    # Multiprocess
    if (fork() == 0) {
        my $child = Data::PubSub::Shared::Int->new('/tmp/ps.shm', 1024);
        my $sub = $child->subscribe;
        while (defined(my $v = $sub->poll_wait(1))) {
            print "got: $v\n";
        }
        exit;
    }
    $ps->publish(99);
    wait;

=head1 DESCRIPTION

Broadcast pub/sub over shared memory (C<mmap(MAP_SHARED)>).
Publishers write to a ring buffer; each subscriber independently
reads with its own cursor. Messages are never consumed -- the ring
overwrites old data when it wraps. Slow subscribers auto-recover
by resetting to the oldest available position.

B<Linux-only>. Requires 64-bit Perl.

=head2 Features

=over

=item * File-backed, anonymous, or memfd-backed mmap

=item * Lock-free MPMC publish for integer variants

=item * Lock-free subscribers for all variants (seqlock)

=item * Variable-length Str messages (circular arena)

=item * Futex-based blocking poll with timeout

=item * PID-based stale lock recovery (Str)

=item * Batch operations: publish_multi, drain, poll_cb, poll_wait_multi

=item * Per-subscriber overflow counting

=item * Keyword API via L<XS::Parse::Keyword>

=back

=head2 Variants

=over

=item L<Data::PubSub::Shared::Int> -- int64, 16 bytes/slot

Lock-free MPMC publish via atomic fetch-and-add. Seqlock-protected
subscribers. Best for counters, timestamps, event IDs.

=item L<Data::PubSub::Shared::Int32> -- int32, 8 bytes/slot

=item L<Data::PubSub::Shared::Int16> -- int16, 8 bytes/slot

Compact variants -- half the memory, 2x cache density. Same lock-free
algorithm. Values silently truncated to type range (C cast semantics).
Best for status codes, small enums, sensor readings.

=item L<Data::PubSub::Shared::Str> -- variable-length strings

Mutex-protected publish, lock-free subscribers. Messages stored in a
circular arena (max capped at C<msg_size>, default 256 bytes). UTF-8
flag preserved. Best for log lines, JSON, serialized payloads.

=back

=head2 Int vs Str

B<Int> (including Int32/Int16): lock-free, zero contention between
publishers. Use when the payload fits in an integer.

B<Str>: mutex serializes publishers, but subscribers are still
lock-free. Use for arbitrary byte strings.

=head1 API

=head2 Constructor

    my $ps = Data::PubSub::Shared::Int->new($path, $capacity);
    my $ps = Data::PubSub::Shared::Str->new($path, $capacity);
    my $ps = Data::PubSub::Shared::Str->new($path, $capacity, $msg_size);

C<$capacity> is rounded up to the next power of 2. When opening an
existing file, parameters are read from the stored header. Pass
C<undef> for C<$path> for anonymous (fork-inherited) pub/sub.

Replace C<Int> with C<Int32>, C<Int16>, or C<Str> as needed.

=head2 memfd

    my $ps = Data::PubSub::Shared::Int->new_memfd($name, $capacity);
    my $fd = $ps->memfd;
    my $ps2 = Data::PubSub::Shared::Int->new_from_fd($fd);

No filesystem path -- backed by C<memfd_create(2)>. Share via
C<fork()> inheritance or C<SCM_RIGHTS> fd passing. The fd is
dup'd internally by C<new_from_fd>.

=head2 Publishing

    $ps->publish($value);                # always succeeds
    my $n = $ps->publish_multi(@values); # batch (max 8192 values)
    $ps->publish_notify($value);         # publish + eventfd notify

Int: C<publish_multi> claims all slots in one atomic fetch-add, then
writes values and wakes subscribers once. Str: holds mutex for the
entire batch.

=head2 Subscribing

    my $sub = $ps->subscribe;       # future messages only
    my $sub = $ps->subscribe_all;   # from oldest available

Subscribers are process-local. Each process creates its own.

=head2 Polling

    my $val = $sub->poll;                       # non-blocking
    my @v   = $sub->poll_multi($n);             # up to $n
    my @v   = $sub->drain;                      # all available
    my @v   = $sub->drain($max);                # up to $max
    my $val = $sub->poll_wait;                  # block forever
    my $val = $sub->poll_wait($timeout);        # block with timeout
    my @v   = $sub->poll_wait_multi($n, $timeout);  # block for >=1

=head2 Callback Polling

    my $n = $sub->poll_cb(\&handler);

Calls C<handler($msg)> for each available message without returning
to Perl between messages. Returns count processed.

=head2 Event Loop Integration

    my $fd = $ps->eventfd;           # create eventfd
    $ps->notify;                     # signal after publish
    $ps->eventfd_consume;            # drain notification counter

    # Combined: consume eventfd + drain messages
    my @v = $sub->drain_notify;
    my @v = $sub->drain_notify($max);

    # EV example
    my $w = EV::io $fd, EV::READ, sub {
        my @msgs = $sub->drain_notify;
        process($_) for @msgs;
    };

Subscribers inherit the handle's eventfd at creation time.
Use C<< $sub->eventfd_set($fd) >> to set manually after creation.

=head2 Status

    my $n = $sub->lag;             # messages behind
    my $n = $sub->overflow_count;  # total messages lost to overflow
    my $o = $sub->has_overflow;    # true if currently overflowed
    my $c = $sub->cursor;         # read position
    $sub->cursor($pos);           # seek
    my $p = $sub->write_pos;      # publisher position

=head2 Cursor Management

    $sub->reset;         # jump to latest (future messages only)
    $sub->reset_oldest;  # jump to oldest available

If a subscriber falls behind by more than C<capacity> messages,
C<poll> auto-recovers by resetting to the oldest available position.
Lost messages are counted in C<overflow_count>.

=head2 Handle Management

    $ps->clear;              # reset ring to initial state
    $ps->sync;               # msync to disk
    $ps->unlink;             # remove backing file
    Class->unlink($path);    # class method form
    my $p = $ps->path;       # undef for anonymous/memfd
    my $s = $ps->stats;      # diagnostic hashref

=head2 Keyword API

    use Data::PubSub::Shared::Int;

    ps_int_publish $ps, $value;
    my $val = ps_int_poll $sub;
    my $n   = ps_int_lag $sub;

Replace C<int> with C<int32>, C<int16>, or C<str>.
Keywords are lexically scoped.

=head2 Crash Safety

Str mode: futex mutex with PID tracking. If a publisher dies holding
the mutex, other publishers recover within 2 seconds. Int modes are
lock-free and need no recovery.

=head1 BENCHMARKS

Single-process, 1M items, Linux x86_64.
Run C<perl -Mblib bench/throughput.pl> to reproduce.

    PUBLISH + POLL (interleaved)
    Int     5.0M/s   (16 bytes/slot)
    Int32   5.9M/s   (8 bytes/slot)
    Int16   5.7M/s   (8 bytes/slot)
    Str     2.5M/s   (~30B messages)

    BATCH (100/batch)
    Int publish_multi:    170M/s
    Str publish_multi:     42M/s

Fan-out: publish throughput is independent of subscriber count.


=head1 SEE ALSO

L<Data::Buffer::Shared> - typed shared array

L<Data::HashMap::Shared> - concurrent hash table

L<Data::Queue::Shared> - FIFO queue

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
