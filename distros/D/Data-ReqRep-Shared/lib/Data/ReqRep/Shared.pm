package Data::ReqRep::Shared;
use strict;
use warnings;
our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Data::ReqRep::Shared', $VERSION);

1;

__END__

=encoding utf-8

=head1 NAME

Data::ReqRep::Shared - High-performance shared-memory request/response IPC for Linux

=head1 SYNOPSIS

    use Data::ReqRep::Shared;

    # Server: create channel
    my $srv = Data::ReqRep::Shared->new('/tmp/rr.shm', 1024, 64, 4096);
    #   path, req_capacity, resp_slots, resp_data_max

    # Server loop
    while (my ($req, $id) = $srv->recv_wait) {
        $srv->reply($id, process($req));
    }

    # Client: open existing channel
    my $cli = Data::ReqRep::Shared::Client->new('/tmp/rr.shm');

    # Synchronous
    my $resp = $cli->req("hello");

    # With timeout (single deadline covers send + wait)
    my $resp = $cli->req_wait("hello", 5.0);

    # Asynchronous (multiple in-flight)
    my $id1 = $cli->send("req1");
    my $id2 = $cli->send("req2");
    my $r1  = $cli->get_wait($id1);
    my $r2  = $cli->get_wait($id2);

    # Integer variant (lock-free, 1.5x faster)
    use Data::ReqRep::Shared::Int;
    my $srv = Data::ReqRep::Shared::Int->new($path, 1024, 64);
    my $cli = Data::ReqRep::Shared::Int::Client->new($path);
    my $resp = $cli->req(42);

=head1 DESCRIPTION

Shared-memory request/response channel for interprocess communication
on Linux. Multiple clients send requests, multiple workers process
them, responses are routed back to the correct requester. All through
a single shared-memory file -- no broker process, no socket pairs per
connection.

B<Linux-only>. Requires 64-bit Perl.

=head2 Architecture

=over

=item * B<Request queue> -- bounded MPMC ring buffer. Str variant uses
a futex mutex with circular arena for variable-length data. Int
variant uses a lock-free Vyukov MPMC queue.

=item * B<Response slots> -- fixed pool with per-slot futex for targeted
wakeup and a generation counter for ABA-safe cancel/recycle.

=back

Flow: client acquires a response slot, pushes a request (carrying the
slot ID), server pops the request, writes the response to that slot,
client reads it and releases the slot.

=head2 Variants

=over

=item B<Str> -- C<Data::ReqRep::Shared> / C<Data::ReqRep::Shared::Client>

Variable-length byte string requests and responses. Mutex-protected
request queue with circular arena. Supports UTF-8 flag preservation.

    my $srv = Data::ReqRep::Shared->new($path, $cap, $slots, $resp_size);
    my $srv = Data::ReqRep::Shared->new($path, $cap, $slots, $resp_size, $arena);

=item B<Int> -- C<Data::ReqRep::Shared::Int> / C<Data::ReqRep::Shared::Int::Client>

Single int64 request and response values. Lock-free Vyukov MPMC
request queue. 1.5x faster single-process. No arena, no mutex on the
request path.

    my $srv = Data::ReqRep::Shared::Int->new($path, $cap, $slots);

=back

Both variants share the same response slot infrastructure, the same
generation-counter ABA protection, the same eventfd integration, and
the same crash recovery mechanisms.

=head2 Constructors

B<Server> (creates or opens the channel):

    ->new($path, ...)             # file-backed
    ->new(undef, ...)             # anonymous (fork-inherited)
    ->new_memfd($name, ...)       # memfd (fd-passing or fork)
    ->new_from_fd($fd)            # open from memfd fd

B<Client> (opens existing channel):

    ->new($path)
    ->new_from_fd($fd)

Constructor arguments for Str: C<$path, $req_cap, $resp_slots,
$resp_size [, $arena]>. For Int: C<$path, $req_cap, $resp_slots>.

=head2 Server API

    my ($data, $id) = $srv->recv;              # non-blocking
    my ($data, $id) = $srv->recv_wait;         # blocking
    my ($data, $id) = $srv->recv_wait($secs);  # with timeout

Returns C<($request_data, $id)> or empty list. For Int, C<$data> is
an integer.

    my $ok = $srv->reply($id, $response);

Writes response and wakes the client. Returns false if the slot was
cancelled or recycled (generation mismatch).

B<Batch> (Str only):

    my @pairs = $srv->recv_multi($n);          # up to $n under one lock
    my @pairs = $srv->recv_wait_multi($n, $timeout);
    my @pairs = $srv->drain;
    my @pairs = $srv->drain($max);

Returns flat list C<($data1, $id1, $data2, $id2, ...)>.

B<Management>:

    $srv->clear;       $srv->sync;        $srv->unlink;
    $srv->size;        $srv->capacity;    $srv->is_empty;
    $srv->resp_slots;  $srv->resp_size;   $srv->stats;
    $srv->path;        $srv->memfd;

B<eventfd> (see L</Event Loop Integration>):

    $srv->eventfd;             $srv->eventfd_set($fd);
    $srv->eventfd_consume;     $srv->notify;
    $srv->fileno;              # current request eventfd (-1 if none)
    $srv->reply_eventfd;       $srv->reply_eventfd_set($fd);
    $srv->reply_eventfd_consume;  $srv->reply_notify;
    $srv->reply_fileno;        # current reply eventfd (-1 if none)

=head2 Client API

B<Synchronous>:

    my $resp = $cli->req($data);                # infinite wait
    my $resp = $cli->req_wait($data, $secs);    # single deadline

B<Asynchronous>:

    my $id   = $cli->send($data);               # non-blocking
    my $id   = $cli->send_wait($data, $secs);   # blocking
    my $resp = $cli->get($id);                   # non-blocking
    my $resp = $cli->get_wait($id, $secs);       # blocking
    $cli->cancel($id);                           # abandon request

C<cancel> releases the slot only if the reply hasn't arrived yet. If
it has (state is READY), cancel is a no-op -- call C<get()> to drain.

B<Convenience> (Str only):

    my $id = $cli->send_notify($data);          # send + eventfd signal
    my $id = $cli->send_wait_notify($data);

B<Status>:

    $cli->pending;     $cli->size;       $cli->capacity;
    $cli->is_empty;    $cli->resp_slots; $cli->resp_size;
    $cli->stats;       $cli->path;       $cli->memfd;

B<eventfd> (see L</Event Loop Integration>):

    $cli->eventfd;             $cli->eventfd_set($fd);
    $cli->eventfd_consume;     $cli->fileno;
    $cli->notify;              # signal request eventfd
    $cli->req_eventfd_set($fd);  $cli->req_fileno;

=head2 Event Loop Integration (eventfd)

Two eventfds for bidirectional notification. Both are opt-in --
C<send>/C<reply> do not signal automatically.

    # Request notification (client -> server)
    my $req_fd = $srv->eventfd;     # create
    $srv->eventfd_consume;          # drain in callback
    $cli->notify;                   # signal (or send_notify)
    $cli->req_eventfd_set($fd);     # set inherited fd

    # Reply notification (server -> client)
    my $rep_fd = $srv->reply_eventfd;
    $srv->reply_notify;             # signal after reply
    $cli->eventfd;                  # create (maps to reply fd)
    $cli->eventfd_consume;          # drain in callback
    $cli->eventfd_set($fd);         # set inherited fd

For cross-process use, create both eventfds B<before> C<fork()> so
child inherits the fds:

    my $srv = Data::ReqRep::Shared->new($path, 1024, 64, 4096);
    my $req_fd = $srv->eventfd;
    my $rep_fd = $srv->reply_eventfd;

    if (fork() == 0) {
        my $cli = Data::ReqRep::Shared::Client->new($path);
        $cli->req_eventfd_set($req_fd);
        $cli->eventfd_set($rep_fd);
        $cli->send_notify($data);       # wakes server
        # EV::io $rep_fd for reply ...
        exit;
    }

    # parent = server
    my $w = EV::io $req_fd, EV::READ, sub {
        $srv->eventfd_consume;
        while (my ($req, $id) = $srv->recv) {
            $srv->reply($id, process($req));
        }
        $srv->reply_notify;
    };

=head2 Crash Safety

=over

=item * B<Stale mutex> -- if a process dies holding the request queue
mutex, other processes detect it via PID tracking and recover within
2 seconds.

=item * B<Stale response slots> -- if a client dies while holding a
slot (ACQUIRED or READY state), the slot is reclaimed automatically
during the next slot acquisition scan.

=item * B<ABA protection> -- response slot IDs carry a generation
counter. A cancelled-and-reacquired slot has a different generation,
so stale C<reply>/C<get>/C<cancel> calls are safely rejected.

=back

=head2 Tuning

=over

=item C<req_cap> -- request queue capacity (power of 2). Higher for
bursty workloads (1024-4096), lower for steady-state (64-256).
Memory: 24 bytes/slot + arena (Str) or 24 bytes/slot (Int).

=item C<resp_slots> -- max concurrent in-flight requests across all
clients. One slot per outstanding async request. For synchronous
C<req()>, one per client suffices. Memory: 64 bytes/slot (Int) or
(32 + C<resp_size> rounded up to 64) bytes/slot (Str).

=item C<resp_size> -- max response payload bytes (Str only). Fixed
per slot. Responses exceeding this croak. Pick the 99th percentile.

=item C<arena> -- request data arena bytes (Str only, default
C<req_cap * 256>). Increase for large requests. Monitor
C<arena_used> in C<stats()>.

=back

=head2 Benchmarks

Linux x86_64. Run C<perl -Mblib bench/vs.pl 50000> to reproduce.

    SINGLE-PROCESS ECHO (200K iterations)
    ReqRep::Int (lock-free)    1.8M req/s
    ReqRep::Str (12B, mutex)   1.2M req/s
    ReqRep::Str batch (100x)   1.4M req/s

    CROSS-PROCESS ECHO (50K iterations, 12B payload)
    Pipe pair (1:1)            240K req/s
    Unix socketpair (1:1)      222K req/s
    ReqRep::Int                202K req/s  *
    ReqRep::Str                177K req/s  *
    IPC::Msg (SysV)            165K req/s
    TCP loopback               115K req/s
    MCE::Channel                96K req/s
    Socketpair via broker       82K req/s
    Forks::Queue (Shmem)         5K req/s

C<*> = MPMC with per-request reply routing. Pipes and sockets are
faster for simple 1:1 echo but require dedicated fd pairs per
client-worker connection and cannot do MPMC without a broker (which
halves throughput).


=head1 SEE ALSO

L<Data::Buffer::Shared> - typed shared array

L<Data::HashMap::Shared> - concurrent hash table

L<Data::Queue::Shared> - FIFO queue

L<Data::PubSub::Shared> - publish-subscribe ring

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
