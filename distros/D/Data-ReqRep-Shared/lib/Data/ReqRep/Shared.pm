package Data::ReqRep::Shared;
use strict;
use warnings;
our $VERSION = '0.09';

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
    my $srv = Data::ReqRep::Shared->new('/dev/shm/rr.shm', 1024, 64, 4096);
    #   path, req_capacity, resp_slots, resp_data_max

    # Server loop
    while (my ($req, $id) = $srv->recv_wait) {
        $srv->reply($id, process($req));
    }

    # Client: open existing channel
    my $cli = Data::ReqRep::Shared::Client->new('/dev/shm/rr.shm');

    # Synchronous
    my $resp = $cli->req("hello");

    # With timeout (single deadline covers send + wait)
    my $resp = $cli->req_wait("hello", 5.0);

    # Asynchronous (multiple in-flight)
    my $id1 = $cli->send("req1");
    my $id2 = $cli->send("req2");
    my $r1  = $cli->get_wait($id1);
    my $r2  = $cli->get_wait($id2);

    # Integer variant (lock-free)
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

B<Linux-only>, with C</proc> mounted (see L</CONTAINERS>) and a C library
with C<memfd_create> (glibc 2.27 or later, or musl). Requires a Perl with
64-bit integers.

=head2 Architecture

=over

=item * B<Request queue> -- bounded MPMC ring buffer. Str variant uses
a futex mutex with circular arena for variable-length data. Int
variant uses a lock-free MPMC queue.

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

Single int64 request and response values: numbers outside that range,
fractions and non-numeric strings are converted the way Perl converts to an
integer, so check them first. Lock-free MPMC request queue. No arena,
no mutex on the request path.

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

An anonymous channel is an unnamed memfd: a forked child attaches with
C<< Client->new_from_fd($srv->memfd) >>.

B<Client> (opens existing channel):

    ->new($path)
    ->new_from_fd($fd)

Constructor arguments for Str: C<$path, $req_cap, $resp_slots, $resp_size [,
$arena [, $mode]]>. For Int: C<$path, $req_cap, $resp_slots [, $mode]>.
C<$mode> is the octal backing-file permission (default C<0600>); see
L</SECURITY>. The descriptor you pass is duplicated (C<F_DUPFD_CLOEXEC>), so
it stays yours to close and closing it does not disturb the handle. The other
way round, a descriptor a handle returns (C<memfd>, C<eventfd>, C<fileno>,
C<ready_fd> and the like) stays the handle's: duplicate it with C<< +<& >>
rather than alias it with C<< +<&= >>, whose close closes it. C<new> on
a file that already holds a channel attaches to it with the sizes it was
created with. The sizes you pass are not compared with those, but they must
still be valid.

A handle cannot be copied. A copy made by Storable or Clone croaks when used,
and a new thread gets no usable handles; open the channel again instead.
Destroying a client handle while another thread of the process is sending can,
in a window of a few instructions, cancel the request that thread is sending
and hand its slot to another client; destroy per-thread clients once the
process's other threads have stopped sending. A process tells its handles on
one channel apart by a 31-bit tag, so the (2^31 - 1)-th handle it opens after
one still in use shares that one's identity: the second of the two to call
C<ready_fd> croaks, and destroying either with a request in flight cancels the
other's too. Reuse handles rather than open one per request.

=head2 Server API

    my ($data, $id) = $srv->recv;              # non-blocking
    my ($data, $id) = $srv->recv_wait;         # blocking
    my ($data, $id) = $srv->recv_wait($secs);  # with timeout

Returns C<($request_data, $id)> or empty list. For Int, C<$data> is
an integer. Call them in list context: in scalar context they return the id.

    my $ok = $srv->reply($id, $response);

Writes response and wakes the client. Returns false if the slot was
cancelled or recycled (generation mismatch), or if C<$id> names no slot.
Only the process that received the request can reply to it: a reply from any
other, such as a child forked after C<recv>, returns false.

B<Batch> (Str only):

    my @pairs = $srv->recv_multi($n);          # up to $n under one lock
    my @pairs = $srv->recv_wait_multi($n, $timeout);
    my @pairs = $srv->drain;
    my @pairs = $srv->drain($max);

Returns flat list C<($data1, $id1, $data2, $id2, ...)>. C<recv_wait_multi>
waits, up to C<$timeout>, for one request, then takes up to C<$n> of those
queued.

B<Management>:

    $srv->clear;       $srv->sync;        $srv->unlink;
    $srv->size;        $srv->capacity;    $srv->is_empty;
    $srv->resp_slots;  $srv->resp_size;   $srv->stats;
    $srv->path;        $srv->memfd;

C<path> returns the path as given, but as bytes: a character string comes back
UTF-8 encoded. A relative one is looked up again from the current directory:
C<unlink> after a C<chdir> misses the file, and treats a missing file as
already removed. C<< Data::ReqRep::Shared->unlink($path) >> removes a channel
file without opening it, while C<< $srv->unlink >> leaves a file alone that a
newer channel has put in its place. C<path> is undef for an anonymous or
memfd channel, where C<unlink> croaks, and C<memfd> is -1 for a file-backed
one.

C<stats> returns a hash reference with C<requests>, C<replies>, C<recoveries>,
C<send_full> and C<recv_empty>; the waiter counts C<recv_waiters>,
C<send_waiters> and C<slot_waiters>; C<size>, C<capacity>, C<resp_slots>,
C<resp_data_max> and C<mmap_size>; and for Str C<arena_cap> and
C<arena_used>. C<recoveries> counts what calls come across and take back from
dead processes (a queue mutex, response slots, Int queue positions); a client
giving up the request it was waiting for because its server died does not
count, and gets undef either way. C<send_full> and C<recv_empty> count the
times a call finds the queue full (on Str, or its arena short of room) or
empty, not the calls: a waiting call looks several times as it starts to wait
and again every two seconds, so both grow while callers wait idle. A send
refused for want of a free response slot counts in neither. C<recv_empty> and
C<recoveries> are 32-bit and wrap; the other counters are 64-bit. C<stats>
reads its values one at a time while the channel runs, C<requests> before
C<replies>, and Int counts a request just after queueing it, so under load, on
either variant, C<replies> can briefly exceed C<requests>.

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

Both return undef if no reply arrives: C<req_wait> on its timeout, and either
at once when C<clear> discards the request, or within two seconds of the server
that received the request dying before its reply is complete (for the
exceptions see L</CRASH SAFETY>).

Perl signal handlers, C<alarm> included, run while a call waits for a request,
a reply, a free slot, queue room or the Str queue mutex. A handler that dies
ends the call: C<req> and C<req_wait> cancel their request, while C<get_wait>
leaves it in flight as its timeout would. One that returns lets the call carry
on waiting. A call can return just as a handler is due, and if that handler
dies what the call took is lost: a server's request goes unreplied and its
client waits until its timeout, or for ever without one while that server
lives; a client's reply is gone and waiting for it again returns undef. A
constructor waiting for the file lock runs handlers only once that wait ends,
and if 120 signals arrive meanwhile Perl dies of them, leaving that signal
blocked. All this holds for Perl's default, deferred handlers: one installed
unsafely (C<POSIX::sigaction> without C<safe>, C<Sys::SigAction>,
C<PERL_SIGNALS=unsafe>) runs inside the module's C code, and if it dies there
it can leave a slot, arena room or the queue mutex held until the process
exits. While a constructor reserves the segment, every signal but C<SIGKILL>
and C<SIGSTOP> waits, about 0.2 seconds per GiB on tmpfs and the whole
write-out on a filesystem without C<fallocate>; one that then ends the process
leaves a file-backed channel's file as an interrupted create (see
L</CRASH SAFETY>) holding the reserved space, while a memfd or anonymous
channel's goes with the process.

Stop a server with a flag and a timed C<recv_wait> rather than a dying
handler, then answer what is queued with one C<drain>, as
F<eg/graceful_shutdown.pl> does, or on Int, which has no C<drain>, with at most
C<size> C<recv> calls: a C<recv> loop until the queue is empty keeps taking
new requests for as long as each arrives before the queue empties, which a few
clients sending in a loop keep up even when each waits for its reply. A
request sent after that last take waits for the next server to open the same
file (one that removes it and creates it again never sees it), and without a
timeout its client waits for ever: stop the senders first, and in a chain of
channels let each stage exit before stopping the one it sends to.

A timeout of 0, like the non-blocking calls, never waits for a request, a
reply, a slot or room: C<req_wait> with one still sends the request, then
gives it up at once. Such a call on a Str channel still waits for the queue
mutex, for two seconds at most when the process holding it is stopped, and
gives up as soon as a signal arrives; its handler runs once the call returns.
A timed call keeps its deadline behind a stopped holder, except that
C<recv_wait_multi> taking the rest of its batch, and a send giving back arena
room, its own as it times out or a dead process's, may each run up to two
seconds over. A negative timeout, or NaN, waits for ever like no timeout at
all, so clamp a computed remaining time at 0. C<req_wait> reads an undef
timeout as 0; the other waits read it as no timeout.

B<Asynchronous>:

    my $id   = $cli->send($data);               # non-blocking
    my $id   = $cli->send_wait($data, $secs);   # blocking
    my $resp = $cli->get($id);                   # non-blocking
    my $resp = $cli->get_wait($id, $secs);       # blocking
    $cli->cancel($id);                           # abandon request

A send returns undef when its request was not queued: C<send> and
C<send_notify> when the queue is full or no response slot is free,
C<send_wait> and C<send_wait_notify> when the timeout passes first.

C<cancel> releases the slot, dropping the reply if it has already arrived. It
does not take the request back: a server still receives a request whose client
cancelled it, gave up on it in C<req_wait> or was destroyed, does its work, and
gets false from C<reply>. A client that retries on timeout therefore adds work
to a server that is behind; carry a deadline in the request if servers should
skip stale ones. A reply still being copied in does not delay C<cancel>: the
responder frees the slot when its copy finishes. A C<get_wait> that times out
leaves the request in flight: wait again or C<cancel> it, or its slot stays
held until the client handle is destroyed. An undef sooner than the timeout, or
from a C<get_wait> without one, means no reply will come (its server died,
C<clear> ran, or another process took the reply), and waiting again returns
undef at once. An id that names no slot of the channel makes C<get> and
C<get_wait> croak and C<cancel> do nothing.

Destroying a client cancels its requests still in flight, freeing their slots;
a forked child destroying its copy of the parent's client leaves them alone.
Destroying a server handle gives back nothing it has received: the requests
stay with the process, which may still reply to them through another handle.

A reply is taken by whichever process reads it with the request's id: a forked
child that calls C<get> with its parent's id receives the reply and frees the
slot, and the parent then gets undef.

B<Convenience> (Str only):

    my $id = $cli->send_notify($data);          # send + eventfd signal
    my $id = $cli->send_wait_notify($data, $secs);

B<Status>:

    $cli->pending;     $cli->size;       $cli->capacity;
    $cli->is_empty;    $cli->resp_slots; $cli->resp_size;
    $cli->stats;       $cli->path;       $cli->memfd;

C<pending> counts the requests this process has in flight, from all its
handles on the channel.

B<eventfd> (see L</Event Loop Integration>):

    $cli->eventfd;             $cli->eventfd_set($fd);
    $cli->eventfd_consume;     $cli->fileno;
    $cli->notify;              # signal request eventfd
    $cli->req_eventfd_set($fd);  $cli->req_fileno;
    $cli->ready_fd;            $cli->ready;   # this client's own replies

=head2 Event Loop Integration

Two eventfds for bidirectional notification. Both are opt-in --
C<send>/C<reply> do not signal automatically. A client signals the request
eventfd only after C<req_eventfd_set>: without one, C<notify> does nothing and
C<send_notify> only sends. C<notify> returns nothing either way.
C<eventfd_consume> and C<reply_eventfd_consume> return the count of
notifications since the last consume, or undef when there were none or the
handle has no eventfd.

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

The C<*_eventfd_set> methods duplicate the descriptor, as C<new_from_fd> does:
the one you pass stays yours to close. They croak on a descriptor that is not
open or is not an eventfd, since C<notify> writes into it. One you consume
through must be non-blocking (C<EFD_NONBLOCK>, as the module's own are), or
C<eventfd_consume> blocks when another process has already drained it; one in
C<EFD_SEMAPHORE> mode gives its notifications one per consume.

Each eventfd is one counter for the whole channel, not one per client: an
C<eventfd_consume> in one client takes the notifications meant for all of
them. With more than one client, use C<ready_fd> instead, check every
outstanding id after each wakeup, or wait with C<get_wait> and a timeout. Even
a single client keeps a timeout of its own: a server that dies before its
C<reply_notify> never signals the eventfd.

B<Per-client reply notification>:

    my $fd = $cli->ready_fd;        # this client's own descriptor
    my $id = $cli->send($data);     # replies to requests sent from now on wake it
    my $w  = EV::io $fd, EV::READ, sub {
        handle($_, $cli->get($_)) for $cli->ready;
    };                             # and a timeout of your own per id

C<ready_fd> gives the client a descriptor of its own that becomes readable
when a reply to one of its requests is ready. Clients sharing a channel then
neither wake each other nor take each other's notifications, and no descriptor
has to pass between processes: C<reply> notifies the client without being
asked. It covers requests the client sends after the call, from the same
process; a forked child calls C<ready_fd> again for its own, and each keeps 4
bytes per response slot to remember what it has listed. C<ready> returns
the ids whose replies are ready and still unread, each once, a few thousand at
a time; while any are left over the descriptor stays readable. It lists replies
only: a request that will get none (its server died, or C<clear> ran) never
shows up, so keep a timeout of your own. At it C<get> the id, and C<cancel> it
only if that returns undef: a server killed as it replies can leave a reply
ready that was never announced.

The descriptor is an abstract Unix datagram socket, so clients and servers must
share a network namespace. A server that cannot open one (seccomp, or systemd's
C<RestrictAddressFamilies=> without C<AF_UNIX>) counts each notification as
lost, so the descriptor never wakes and the client's own timeout is what brings
it to C<ready>. A notification that finds the client's queue full
(C<net.unix.max_dgram_qlen>) is not lost: the next C<ready> reads every
response slot of the channel instead, about 1 ms per 64K small ones. The
kernel's default limit is only 10: a fresh network namespace such as a
container's has that, and so does a host unless something raised it (systemd
sets 512 at boot). A descriptor keeps the limit in force when C<ready_fd> made
it, so raise it before clients call C<ready_fd>, or keep a client's replies in
flight under it.

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
2 seconds (4 when it died unreaped, or its PID was reused, and signals keep
interrupting the waits), and a waiter already parked for a request, a slot or
room within one two-second tick more.

=item * B<Stale response slots> -- a slot held by a client that died, or
by a server that died before replying, is taken back when its client waits
for the reply, or when a later sender finds no free slot. A C<send_wait> or
C<req> waiting for a slot or for queue room looks again every two seconds, so
it notices when the holders are gone or a receiver that made room died before
saying so.

=item * B<ABA protection> -- response slot IDs carry a generation
counter. A cancelled-and-reacquired slot has a different generation,
so stale C<reply>/C<get>/C<cancel> calls are safely rejected.

=back

=head2 Tuning

=over

=item C<req_cap> -- request queue capacity, rounded up to a power of 2.
A request holds a response slot until its reply is read or it is given up, so
at most C<resp_slots> requests wait at once, beside given-up ones (cancelled,
C<req_wait> timing out included, or their client destroyed or killed), which
stay queued until a server receives them: set it above C<resp_slots> by as
many as clients may give up, and raise C<resp_slots> for bursts, on Str with an
C<arena> that holds their bytes, each rounded up to 8 (an empty one takes 8),
plus one of the largest, which the ring can leave unused at its end (the
default gives at least 256 bytes a position). Memory: 24 bytes/slot + arena
(Str) or 24 bytes/slot (Int), beside about 10 KB a channel carries whatever its
size (header, process records, counters).

=item C<resp_slots> -- max concurrent in-flight requests across all
clients. One slot per outstanding async request. For synchronous
C<req()>, one per client suffices. Memory: 64 bytes/slot (Int) or
(40 + C<resp_size>, rounded up to a multiple of 64) bytes/slot (Str), in a
segment that must stay under 4 GiB, and under about 2.5 GiB for a 32-bit perl
on a 64-bit kernel to map it.

=item C<resp_size> -- max response payload bytes (Str only). Fixed per slot. A
longer reply croaks in the responder and leaves the request unanswered: reply
again with a shorter one, or its client waits until its timeout, or for ever
without one while the responder lives. Size it for the largest reply you send,
not a typical one.

=item C<arena> -- request data arena bytes (Str only; 0 or undef gives the
default C<req_cap * 256>, a value under 4096 is raised to 4096, others are
rounded up to a multiple of 8, and C<arena_cap> in C<stats> gives the result).
Increase for large requests: one longer than the arena, or than 2 GiB - 1
bytes, can never be queued, and a send croaks on it (request too long) instead
of waiting for room. One longer than the arena croaks only once a response slot
and queue room are free: until then it returns undef, or waits, as for any
request. Monitor C<arena_used> in C<stats()>.
A waiting sender that does not fit holds the room it needs, if no other waiting
sender needs more: smaller requests use only what is left, so a large request
is not kept out by a stream of small ones. It keeps the room while its signal
handlers run (a send from one of them is not held back by it), and gives it
back when its call ends, a handler dying included. A sender stopped while it
waits keeps that room held until it continues, gives up, or C<clear> empties
the arena; one killed while it waits gives it back at the next send it holds
up, which fails that once unless it waits; from a handle that found it alive
in the last 10 ms, sends fail until those pass, and a waiting one takes up to
two seconds.

=back

=head2 Benchmarks

Linux x86_64. The single-process rows come from C<bench/bench_int.pl> and
C<bench/bench.pl 200000>, the cross-process rows from C<bench/vs.pl 50000>,
which caps Forks::Queue at 10K; run them with C<perl -Mblib>.

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
costs about two thirds of their throughput).


=head1 CRASH SAFETY

Response slots are recovered from dead owners, and the Str request queue
recovers a mutex held by a dead process. The Int request queue survives its
users being killed too. A receiver killed while taking a message is moved past
by the next sender or receiver. A sender killed between claiming a queue
position and publishing its message holds up the queue only until a receiver
finds that no live process holds the claim and skips the position; that
message is lost. A sender stopped there holds up the queue until it continues.

A process killed while it waits can stay counted among the waiters (the
C<*_waiters> in C<stats>) indefinitely: a count forgets its dead only when one
handle's wakes find nobody parked several times in a row, or, for
C<send_waiters> and C<slot_waiters>, when C<clear> finds nobody parked. Read
these counts as upper bounds.

A slot's generation counter is 32-bit. It guards against a stale id being
honoured after the slot is recycled, which it does for any realistic run;
after 2^32 re-acquisitions of the same slot an ancient id would compare equal
again.

Recovery tells a dead process from a live one by its PID and its start time,
which a channel records for up to 1024 processes that use it at once, so a PID
reused by another process does not keep what the dead one held. A process
beyond those 1024, or one whose F</proc/PID/stat> cannot be read, is known by
its PID alone: if that PID is reused before recovery runs, it is taken for the
process that died. So is any later holder of a PID whose next channel user was
killed while giving back what the dead one held. Once 1024 processes have used
a channel, a new one takes the record of one that has exited and whose PID is
free, and reads every response
slot as it opens the channel (a forked child using its parent's handle: at its
first call) to give back what that one held. That takes about 10 ms per
million slots with small replies, growing with C<resp_size> to about 0.1 s per
million 4 KB ones. If no record is free, the new process is known by its PID
alone, and each handle it opens looks at all 1024 records again, about 6 ms.

A process keeps its PID and start time across C<exec>, so recovery cannot see
the old program go. The new program's first open of the channel gives up what
the old one held there, so make that open before starting threads that use the
channel; a program that never opens it keeps that held until it exits, so
answer or cancel before an C<exec> into one.

A handle stays attached to the segment it opened. When a server removes the
file on shutdown, as the examples do, and its successor creates it again,
clients still attached keep using the old segment, which nobody serves: open
them again after a restart, which C<stat> on the path, taken before opening,
shows as a new inode. For the same reason keep a long-lived channel out of
directories cleaned by age, such as F</tmp> under systemd-tmpfiles. There a
channel loses its file once nothing has refreshed its times for the aging
period, and on tmpfs traffic through the mapping refreshes none of them: only
opening the file does, so a busy channel whose processes all opened it long ago
is removed too. Likewise systemd-logind's C<RemoveIPC> (on by default) deletes
a non-system user's files in F</dev/shm> when that user's last login session
ends: run long-lived channels as a system user, or with C<loginctl
enable-linger>, or set C<RemoveIPC=no>.

Every change to a response slot is one compare-and-swap on a word holding its
generation, its state and the pid of the process responsible for it: the
owner, or the server once it has received the request. A stale id or a stale
reading therefore never moves a slot, and recovery acts only on a named
process that is dead, never on elapsed time, so a process stopped by SIGSTOP,
a debugger or a paused container is not taken for dead however long it stays
stopped. When the server dies before its reply is complete, the client's
C<get_wait> or C<req> gives up within two seconds and frees the slot, or within
four when that server died unreaped, or its PID was reused, and signals keep
interrupting the wait. One exception: a server that took a request off the
queue but has not yet marked it received, a matter of a few instructions (for
C<recv_multi>, C<recv_wait_multi> and C<drain>, the whole batch), cannot be
named. It is taken for dead once a client waiting for the request has seen it
unmarked for four seconds; the client first looks at its next two-second check,
so that is up to six seconds after the take, or eight when signals keep
interrupting the wait. Each such request is timed from when its client first
waits for it, so waiting for several in turn takes about four seconds each. A
client times up to 16 such requests at once; any more are left to the caller's
timeout, and wait for ever without one.

C<clear> may run while clients and servers are working. It discards the
requests still queued, those a server has received but not answered (a later
C<reply> to them returns false), and replies not yet read: each gets undef. A
reply still being written is left to its responder, which frees the slot when
done. A request still being sent is not discarded, and on an Int channel
neither are the requests queued behind it.

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
and attaching from anywhere else croaks. Reading them needs C</proc>: without
it, or with its top-level files hidden (systemd's C<ProcSubset=pid>, a
C<subset=pid> mount), every constructor croaks unless the variable below is
set. The F</proc> a peer sees must be that of its own PID namespace: after
C<unshare -p> without C<--mount-proc>, or C<nsenter -p> without C<-m>,
F</proc/PID> names the host's processes and recovery judges the wrong ones.

B<All peers must therefore share a PID namespace> -- C<docker run
--pid=container:NAME>, or a Kubernetes pod with C<shareProcessNamespace: true>.
Sharing only the filesystem or the IPC namespace is not enough. The same check
rejects a file left over from a previous boot, whose recorded PIDs now name
unrelated processes. Peers must also see the same boot time: one in a time
namespace that offsets it (C<unshare --boottime>, a CRIU restore) reads every
other peer's start time shifted, and takes them all for dead within a tick.

Set C<DATA_REQREP_SHARED_UNSAFE_PIDNS=1> (any value but an empty one, a zero
number, C<false>, C<no> or C<off>) to attach anyway. Only do that if you do not
depend on recovery -- for example a fixed set of peers that never die
mid-request -- because the failure mode it re-enables is silent corruption.

For sharing across containers without a shared filesystem, create the segment
with C<new_memfd> and pass the descriptor over a unix socket with
C<SCM_RIGHTS>; a memfd needs no shared filesystem, though its peers still need
the one PID namespace. If you use a file, note that a container's default
C</dev/shm> is often only 64 MB. C<new> reserves the whole segment when it
creates one, memfd and anonymous channels too, so its memory is taken at once,
and croaks if a filesystem limit leaves no room (a memory cgroup limit gets the
process killed instead); a sparse segment would instead kill a process with
SIGBUS at the first write that could not be backed. Set
C<DATA_REQREP_SHARED_SPARSE=1> to skip the reservation: creation then takes
only the pages it writes (the header, the page holding each response slot's
header, the creator's process record and, on Int, the request queue: nearly all
of an Int segment), the rest as it is first used. The Str request queue and
arena are rings: the queue is used all the way round after C<req_cap> requests,
and the arena too once requests stay queued long enough (it starts over only
when the queue empties). What stays untaken is arena that a queue which often
empties never reaches, process records (8 KB in all) no process has used and,
when C<resp_size> is over about 4 KB, response data past each slot's first page
that no reply has reached. On a filesystem without
C<fallocate> (some FUSE mounts), glibc reserves the segment by writing it out
block by block, and musl leaves it sparse. Under
a user namespace, C<new>'s ownership checks compare uids I<as mapped in the
caller's namespace>, so peers need a common id mapping.

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
permissions. An empty file at the path that you own, as a create refused for
want of space leaves, is initialized like a new one, so it gets C<$mode> too;
one another user owns is refused. The file is opened with C<O_NOFOLLOW>, so a
symlink planted at the path is refused, and created with C<O_EXCL>; the on-disk
header is validated when the file is attached. Attaching refuses a
world-writable file owned by another user; share with a group mode such as
C<0660> instead. Any process that can open the file can hold its lock, so
C<new> waits for the lock for at most 10 seconds and then croaks. Any process
you grant write access to a shared mapping is trusted not to corrupt its
contents while other processes are using it.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
