package Data::ReqRep::Shared;
use strict;
use warnings;
our $VERSION = '0.08';

require XSLoader;
XSLoader::load('Data::ReqRep::Shared', $VERSION);

# ithreads: blessed shared-memory handles must never be cloned into a
# child thread -- the clone would double-free the handle on thread exit.
{ no strict 'refs'; *{"${_}::CLONE_SKIP"} = sub { 1 } for qw(
  Data::ReqRep::Shared
  Data::ReqRep::Shared::Client
  Data::ReqRep::Shared::Int
  Data::ReqRep::Shared::Int::Client
); }

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
the same response-slot crash recovery. Their request queues differ: see
L</CRASH SAFETY>.

=head2 Constructors

B<Server> (creates or opens the channel):

    ->new($path, ...)             # file-backed
    ->new(undef, ...)             # anonymous (fork-inherited)
    ->new_memfd($name, ...)       # memfd (fd-passing or fork)
    ->new_from_fd($fd)            # open from memfd fd

B<Client> (opens existing channel):

    ->new($path)
    ->new_from_fd($fd)

Constructor arguments for Str: C<$path, $req_cap, $resp_slots, $resp_size [,
$arena [, $mode]]>. For Int: C<$path, $req_cap, $resp_slots [, $mode]>.
C<$mode> is the octal backing-file permission (default C<0600>); see
L</SECURITY>. The descriptor you pass is duplicated (C<F_DUPFD_CLOEXEC>), so
it stays yours to close and closing it does not disturb the handle.

=head2 Server API

    my ($data, $id) = $srv->recv;              # non-blocking
    my ($data, $id) = $srv->recv_wait;         # blocking
    my ($data, $id) = $srv->recv_wait($secs);  # with timeout

Returns C<($request_data, $id)> or empty list. For Int, C<$data> is
an integer.

    my $ok = $srv->reply($id, $response);

Writes response and wakes the client. Returns false if the slot was
cancelled or recycled (generation mismatch), or if C<$id> names no slot.

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

C<cancel> releases the slot only if the reply hasn't arrived yet. If it
has, cancel is a no-op -- call C<get()> to drain, or the slot stays held
until the client exits. A reply still being copied in does not delay
C<cancel>: the responder frees the slot when its copy finishes.
C<req_wait> and C<get_wait> do the cancel-and-drain for you; only a
hand-rolled send/cancel loop needs it.

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

=head2 Event Loop Integration

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

The C<*_eventfd_set> methods duplicate the descriptor, as C<new_from_fd>
does: the one you pass stays yours to close. One that is not open croaks.

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


=head1 CRASH SAFETY

Response slots are recovered from dead owners, and the Str request queue
recovers a mutex held by a dead process. B<The Int request queue is not
crash-safe>: it is lock-free, and a producer or consumer killed between
claiming a queue position and publishing its sequence number leaves a hole
that wedges the queue from that position on. Nothing reclaims it -- C<clear>
is the only recovery. C<clear> on the Int variant is likewise safe only when
no peer is mid-enqueue; the Str variant takes the mutex and has no such
caveat.

Destroying a client with requests still in flight abandons their slots: they
are held by a live process, so death-based recovery never reclaims them, and
they stay held until that process exits. Drain or C<cancel> outstanding ids
before dropping a client in a long-lived process.

A slot's generation counter is 32-bit. It guards against a stale id being
honoured after the slot is recycled, which it does for any realistic run;
after 2^32 re-acquisitions of the same slot an ancient id would compare equal
again.

Recovery tells a dead process from a live one with C<kill($pid, 0)>, so a PID
reused before recovery runs is taken for the process that died. Until that
unrelated process exits, a Str queue mutex its predecessor held stays held --
every Str C<send> and C<recv> blocks -- and a response slot it held is not
recovered. Linux hands out PIDs in sequence, so this needs the PID space to
wrap between the death and the next attempt to recover; a larger
C<kernel.pid_max> makes it rarer.

A responder killed in the few instructions between claiming a reply slot and
recording its PID leaves that slot held until C<clear>, which gives the PID two
seconds to appear before reclaiming it. Nothing else can tell it from a
responder merely descheduled there, and reclaiming a live one would deliver its
reply to the wrong request. For the same reason C<clear> leaves a slot a live
responder is still writing into to that responder, which frees it when done.

An interrupted create is recovered too. A creator killed after the backing
file is sized but before its header is committed leaves a full-size, all-zero
file. C<new> re-initializes such a file automatically, but only when it is
exactly the size the requested geometry needs, is owned by your effective uid,
and is still entirely zero -- a file holding data is never re-initialized. If
the creator got as far as writing part of the header, the file cannot be told
apart from a corrupt one and C<new> croaks with C<incomplete reqrep file left
by an interrupted create; remove it and retry>. A file left behind by an
interrupted create never held data, so removing it is safe -- but a file whose
header was corrupted after the fact reaches the same croak, so confirm it is
an abandoned create before deleting anything you care about.

=head1 CONTAINERS

Stale-slot and stale-mutex recovery identify peers by PID, and a PID only means
something inside one PID namespace. A peer attaching from another namespace
would read live processes as dead -- taking their slots and misdelivering
replies -- and unrelated local processes as alive, never recovering a real
casualty. None of that is detectable after the fact, so C<new> refuses it: the
header records the creating process's PID namespace and the current boot id,
and attaching from anywhere else croaks.

B<All peers must therefore share a PID namespace> -- C<docker run
--pid=container:NAME>, or a Kubernetes pod with C<shareProcessNamespace: true>.
Sharing only the filesystem or the IPC namespace is not enough. The same check
rejects a file left over from a previous boot, whose recorded PIDs now name
unrelated processes.

Set C<DATA_REQREP_SHARED_UNSAFE_PIDNS=1> to attach anyway. Only do that if you
do not depend on recovery -- for example a fixed set of peers that never die
mid-request -- because the failure mode it re-enables is silent corruption.

For sharing across containers without a shared filesystem, create the segment
with C<new_memfd> and pass the descriptor over a unix socket with
C<SCM_RIGHTS>; a memfd crosses namespaces natively. If you use a file, note
that a container's default C</dev/shm> is often only 64 MB. Under a user
namespace, C<new>'s ownership checks compare uids I<as mapped in the caller's
namespace>, so peers need a common id mapping.

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

L<Data::Heap::Shared> - priority queue

L<Data::Graph::Shared> - directed weighted graph

L<Data::BitSet::Shared> - shared bitset (lock-free per-bit ops)

L<Data::RingBuffer::Shared> - fixed-size overwriting ring buffer

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default, so only
the creating user can open and attach them. To share a backing file across
users, pass an explicit octal file mode such as C<0660> as the final C<$mode>
argument to C<new> -- for Str after the optional C<$arena> (C<< new($path,
$req_cap, $resp_slots, $resp_size, $arena, 0660) >>), for Int as the fourth
argument (C<< new($path, $req_cap, $resp_slots, 0660) >>); the mode is applied
when the file is created, and when a file left behind by an interrupted create
is re-initialized (see L</CRASH SAFETY>); a file already in use keeps its own
permissions. The file is opened with C<O_NOFOLLOW>, so a symlink planted at
the path is refused, and created with C<O_EXCL>; the on-disk header is
validated when the file is attached. Attaching refuses a world-writable file
owned by another user; share with a group mode such as C<0660> instead. Any
process that can open the file can hold its lock, so C<new> waits for the lock
for at most 10 seconds and then croaks. Any process you grant write access to a
shared mapping is trusted not to corrupt its contents while other processes
are using it.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
