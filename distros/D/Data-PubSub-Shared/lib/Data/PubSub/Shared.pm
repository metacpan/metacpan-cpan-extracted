package Data::PubSub::Shared;
use strict;
use warnings;
our $VERSION = '0.01';

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
        my $class = shift;
        return unless $Data::PubSub::Shared::HAVE_KEYWORDS;
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

Data::PubSub::Shared - High-performance shared-memory pub/sub for Linux

=head1 SYNOPSIS

    use Data::PubSub::Shared;

    # Publisher
    my $ps = Data::PubSub::Shared::Int->new('/tmp/ps.shm', 1024);
    $ps->publish(42);
    $ps->publish_multi(1, 2, 3);

    # Subscriber (same or different process)
    my $ps2 = Data::PubSub::Shared::Int->new('/tmp/ps.shm', 1024);
    my $sub  = $ps2->subscribe;       # future messages only
    my $sub2 = $ps2->subscribe_all;  # from oldest available

    # Polling
    my $val = $sub->poll;            # non-blocking, undef if nothing
    my @v   = $sub->poll_multi(10);  # batch poll
    my @v   = $sub->drain;           # poll all available
    my @v   = $sub->drain(100);      # poll up to 100
    my $val = $sub->poll_wait;       # blocking, infinite wait
    my $val = $sub->poll_wait(1.5);  # with timeout
    my @v   = $sub->poll_wait_multi(10, 1.5);  # block for >=1, grab up to 10

    # Combined publish + eventfd notify
    $ps->publish_notify($value);

    # Status
    my $n = $sub->lag;               # messages behind
    my $n = $sub->overflow_count;    # total messages skipped
    $sub->reset;                     # skip to latest
    $sub->reset_oldest;              # go back to oldest available

    # String variant
    my $ps = Data::PubSub::Shared::Str->new('/tmp/ps.shm', 1024);
    $ps->publish("hello world");
    my $sub = $ps->subscribe;
    my $msg = $sub->poll;

    # Anonymous (fork-inherited)
    my $ps = Data::PubSub::Shared::Int->new(undef, 1024);

    # memfd-backed (shareable via fd passing)
    my $ps = Data::PubSub::Shared::Int->new_memfd("myps", 1024);
    my $fd = $ps->memfd;
    my $ps2 = Data::PubSub::Shared::Int->new_from_fd($fd);

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

Data::PubSub::Shared provides broadcast pub/sub over shared memory
(C<mmap(MAP_SHARED)>). Publishers write to a ring buffer; each subscriber
independently reads with its own cursor. Messages are never consumed --
the ring overwrites old data when it wraps. Slow subscribers auto-recover
by resetting to the oldest available position.

B<Linux-only>. Requires 64-bit Perl.

=head2 Features

=over

=item * File-backed mmap for cross-process sharing

=item * Lock-free MPMC publish for Int (atomic fetch-and-add)

=item * Lock-free subscribers for both variants (seqlock-style)

=item * Variable-length Str messages with circular arena

=item * Futex-based blocking poll with timeout (no busy-spin)

=item * PID-based stale lock recovery (Str mode)

=item * Batch publish/poll operations (drain, poll_wait_multi)

=item * Per-subscriber overflow counting

=item * Optional keyword API via XS::Parse::Keyword

=back

=head2 When to Use Int vs Str

B<Int> is best for signaling, counters, indices, timestamps, or any
integer-valued broadcast. Lock-free MPMC publish means multiple
publishers never block each other.

B<Str> is best for serialized messages, log lines, JSON payloads, or
any variable-length data. Mutex-protected publish serializes concurrent
publishers but subscribers remain lock-free.

=head2 Variants

=over

=item L<Data::PubSub::Shared::Int> - int64 values, lock-free MPMC publish

Uses atomic fetch-and-add for multi-publisher support. Each slot has a
sequence number; subscribers verify data consistency via double-check
(seqlock-style). Zero contention between publishers and subscribers.

=item L<Data::PubSub::Shared::Int32> - int32 values, lock-free, 8 bytes/slot

=item L<Data::PubSub::Shared::Int16> - int16 values, lock-free, 8 bytes/slot

Compact variants with 32-bit sequence numbers. Half the memory of Int
(8 bytes/slot vs 16). Same lock-free MPMC algorithm and full API.
Values outside the type range are silently truncated (standard C cast).

=item L<Data::PubSub::Shared::Str> - byte string values, mutex-protected publish

Mutex-protected publish with variable-length messages stored in a
circular arena (max capped at C<msg_size>). Short messages use only
the space they need. Subscribers read lock-free with seqlock-style
double-check. UTF-8 flag preserved. Default max message size: 256 bytes.

=back

=head2 Key Differences from Data::Queue::Shared

=over

=item * B<Broadcast>: every subscriber sees every message (queues consume)

=item * B<No backpressure>: publish always succeeds (ring overwrites old data)

=item * B<Multiple independent readers>: each subscriber has its own cursor

=item * B<Lock-free subscribers>: subscribers never block publishers

=back

=head2 Constructor

    # Int
    my $ps = Data::PubSub::Shared::Int->new($path, $capacity);

    # Str
    my $ps = Data::PubSub::Shared::Str->new($path, $capacity);
    my $ps = Data::PubSub::Shared::Str->new($path, $capacity, $msg_size);

Creates or opens a shared pub/sub backed by file C<$path>.
C<$capacity> is rounded up to the next power of 2.
When opening an existing file, parameters are read from the stored header.
Pass C<undef> for C<$path> for anonymous (fork-inherited) pub/sub.

For Str, C<$msg_size> sets the maximum bytes per message (default: 256).
Messages exceeding this size will croak. A circular arena of
C<capacity * (msg_size + 8)> bytes is allocated automatically.

=head2 memfd Constructor

    my $ps = Data::PubSub::Shared::Int->new_memfd($name, $capacity);
    my $ps2 = Data::PubSub::Shared::Int->new_from_fd($ps->memfd);

=head2 Publishing

    $ps->publish($value);                 # returns true
    my $n = $ps->publish_multi(@values);  # returns count published
    $ps->publish_notify($value);          # publish + eventfd notify

Publish writes to the ring buffer and wakes any blocked subscribers.
Int publish is lock-free (atomic fetch-and-add); C<publish_multi>
claims all slots in a single atomic operation (one fetch-add instead
of N). Str publish is mutex-protected.

C<publish_notify> combines C<publish> and C<notify> in a single XS
call, saving method dispatch overhead in the common non-batching case.

=head2 Management

    $ps->clear;                  # reset ring: write_pos=0, all slots cleared
    $ps->sync;                   # msync to disk
    $ps->unlink;                 # remove backing file
    Class->unlink($path);        # class method form
    my $p = $ps->path;           # backing file path (undef for anon/memfd)
    my $s = $ps->stats;          # diagnostic hashref

C<clear> resets the ring buffer to its initial state: C<write_pos>,
C<stat_publish_ok>, and all slot sequences are zeroed. Existing
subscribers will need to call C<reset_oldest> to see new messages.
For Str mode, the arena write position is also reset.

For Str, C<publish_multi> holds the mutex for the entire batch (one
lock/unlock cycle instead of N), which significantly improves
throughput for batch string publishing.

=head2 Subscribing

    my $sub = $ps->subscribe;       # future messages only
    my $sub = $ps->subscribe_all;   # from oldest available

Creates a subscriber with its own cursor. Subscribers are process-local
and cannot be shared between processes. Each process should create its
own subscribers.

=head2 Subscriber API

=head3 Polling

    my $val = $sub->poll;            # non-blocking, undef if empty
    my @v   = $sub->poll_multi($n);  # batch, up to $n items
    my @v   = $sub->drain;           # poll all available
    my @v   = $sub->drain($max);     # poll up to $max
    my $val = $sub->poll_wait;       # blocking, infinite wait
    my $val = $sub->poll_wait($t);   # blocking with timeout (seconds)
    my @v   = $sub->poll_wait_multi($n, $timeout);

C<drain> returns all currently available messages in one call.

C<poll_wait_multi> blocks until at least one message is available
(or timeout), then grabs up to C<$n> messages non-blocking.
Returns empty list on timeout.

=head3 Status

    my $n = $sub->lag;             # messages behind write_pos
    my $c = $sub->cursor;         # current read position
    $sub->cursor($new_pos);       # seek to specific position
    my $o = $sub->has_overflow;    # true if ring wrapped past us
    my $n = $sub->overflow_count;  # total messages skipped due to overflow
    my $p = $sub->write_pos;      # publisher's current position

C<overflow_count> is a cumulative counter of messages skipped due to
ring overflow. It increments each time C<poll> auto-recovers by the
number of messages that were lost.

=head3 Callback-based Polling

    my $n = $sub->poll_cb(\&handler);    # call handler for each message
    my @v = $sub->drain_notify;          # eventfd_consume + drain
    my @v = $sub->drain_notify($max);    # eventfd_consume + drain up to $max

C<poll_cb> calls C<handler> once per available message without
returning to Perl between messages. Eliminates per-message method
dispatch overhead. Returns the number of messages processed.

C<drain_notify> combines C<eventfd_consume> and C<drain> in a single
XS call. Designed for event-loop callbacks:

    my $w = EV::io $fd, EV::READ, sub {
        my @msgs = $sub->drain_notify;
        process($_) for @msgs;
    };

Subscribers inherit the handle's eventfd at creation time. Use
C<< $sub->eventfd_set($fd) >> to set it manually, or
C<< $sub->fileno >> to query it.

=head3 Cursor Management

    $sub->reset;         # skip to current write_pos (future only)
    $sub->reset_oldest;  # go back to oldest available

If a subscriber falls behind by more than C<capacity> messages,
C<poll> auto-recovers by resetting to the oldest available position
and returning the next available message. The skipped message count
is added to C<overflow_count>.

=head2 Event Loop Integration

    my $fd = $ps->eventfd;
    $ps->notify;            # after publish (opt-in)

    use EV;
    my $sub = $ps->subscribe;
    my $w = EV::io $fd, EV::READ, sub {
        $ps->eventfd_consume;
        while (defined(my $v = $sub->poll)) { process($v) }
    };

=head2 Crash Safety

Str mode uses a futex-based mutex with PID tracking. If a publisher
dies while holding the mutex, other publishers detect the stale lock
within 2 seconds and automatically recover. Int mode is lock-free
and requires no crash recovery.

=head2 Keyword API

    use Data::PubSub::Shared::Int;

    ps_int_publish $ps, $value;
    my $val = ps_int_poll $sub;
    my $n   = ps_int_lag $sub;

    use Data::PubSub::Shared::Str;

    ps_str_publish $ps, $value;
    my $val = ps_str_poll $sub;

Replace C<int> with C<int32>, C<int16>, or C<str> for other variants.
Keywords are lexically scoped and require L<XS::Parse::Keyword> at
build time.

=head1 BENCHMARKS

Single-process throughput, 1M items, Linux x86_64.
Run C<perl -Mblib bench/throughput.pl> to reproduce.

    PUBLISH + POLL (interleaved)
    Int     5.0M/s   (16 bytes/slot)
    Int32   5.9M/s   (8 bytes/slot)
    Int16   5.7M/s   (8 bytes/slot)
    Str     2.5M/s   (~30B messages)

    BATCH PUBLISH (100/batch)
    Int publish_multi:    170M/s
    Str publish_multi:     42M/s

Fan-out: publish throughput is independent of subscriber count
(subscribers are lock-free and read-only).

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
