package DBIO::PostgreSQL::EV::Pool;
# ABSTRACT: EV::Pg connection pool for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Storage::PoolBase';

use IO::Poll ();
use POSIX ();
use Scalar::Util ();
use Socket ();
use DBIO::Util ();
use DBIO::PostgreSQL::EV::ConnectInfo qw( conninfo_string with_connect_timeout );
use DBIO::PostgreSQL::EV::Future ();



sub _create_connection {
  my ($self, $conninfo) = @_;
  return $self->_create_ready_connection(conninfo => $conninfo);
}


sub _new_connection {
  my ($self, %args) = @_;
  require EV::Pg;
  return _pg_opened(_pg_new(%args)) unless ref $self;

  # Weak, like core's own on_connect / on_error: the handle keeps its handlers
  # for as long as it lives, and the pool holds the handle.
  my $on_error = $args{on_error};
  my $pid      = $$;
  my $weak_pg;
  Scalar::Util::weaken(my $weak_pool = $self);
  $args{on_error} = sub {
    my ($pool, $pg) = ($weak_pool, $weak_pg);
    $pool->_mark_connection_dead($pg) if $pool && $pg && $$ == $pid;
    $on_error->(@_) if $on_error;
    return;
  };
  my $pg = _pg_opened(_pg_new(%args));
  Scalar::Util::weaken($weak_pg = $pg);
  return $pg;
}

# EV::Pg->new, with no password in what it says (karr k78). What a handle
# says about its connection is libpq's text, and libpq quotes what it could
# not read: of a postgresql:// URI the whole of it, user:password@ included.
# That is the croak of the constructor -- libpq reads the conninfo before it
# connects -- which reaches the caller of a pooled statement and of listen;
# on_error hands on libpq's text as well. Both are masked here, the one place
# every handle of this distribution is made, the way core masks connect info
# in a message (DBIO::Util::mask_connect_secrets, core k297). The conninfo is
# not kept for it: on_error's text is masked by what is in it. An exception
# that is no string is rethrown as it came.
sub _pg_new {
  my (%args) = @_;
  $args{conninfo} = with_connect_timeout($args{conninfo}) if defined $args{conninfo};
  if (my $on_error = $args{on_error}) {
    $args{on_error} = sub {
      $on_error->(DBIO::Util::mask_connect_secrets($_[0]), @_[1 .. $#_]);
      return;
    };
  }
  my $pg;
  return $pg if eval { $pg = EV::Pg->new(%args); 1 };
  die DBIO::Util::mask_connect_secrets($@, [ $args{conninfo} ]);
}

# --- Fork safety (karr k45) ---------------------------------------------------
# See "Fork safety" in the POD. Private helpers are _pg_*: they share an
# inheritance chain with core's privates.
#
# Every handle _new_connection built that is alive in this process, by refaddr:
# [ the pid that opened it, the handle (weak) ]. The destructor removes its own
# entry. A plain hash rather than a per-pool list, so that the fork guard also
# reaches a handle the pool no longer counts -- one core dropped as inherited,
# say, which a statement still in flight keeps alive.
my %PG_OPENED;
# Cancel requests out on a handle, by refaddr: { pid, close }. See
# _shutdown_connection.
my %PG_CANCEL;
my $PG_FORK_GUARD;

sub _pg_opened {
  my ($pg) = @_;
  bless $pg, 'DBIO::PostgreSQL::EV::Pool::_Connection';
  my $entry = [ $$, $pg ];
  Scalar::Util::weaken($entry->[1]);
  $PG_OPENED{ Scalar::Util::refaddr($pg) } = $entry;
  $PG_FORK_GUARD ||= _pg_fork_guard();
  return $pg;
}

# One EV::fork watcher for every handle, armed with the first. EV runs fork
# watchers first thing when a child resumes the loop, before any I/O watcher,
# so the inherited handles are closed before they can read the parent's
# replies. keepalive(0): an active EV::fork watcher alone keeps EV::run from
# ever returning, and a guard must never be the reason the loop goes on
# running -- in the parent and in a child alike. It still fires after a fork.
sub _pg_fork_guard {
  my $w = EV::fork(\&_pg_finish_inherited);
  $w->keepalive(0);
  return $w;
}

sub _pg_finish_inherited {
  my @inherited = grep { $_->[0] != $$ } values %PG_OPENED;
  for my $entry (@inherited) {
    my $pg = $entry->[1] or next;
    local $@;
    eval { $pg->finish; 1 };
  }
  return;
}

# In a process other than the one that opened $pg, point the file descriptor
# of its socket at /dev/null. libpq's close then writes its Terminate there --
# send() fails on a non-socket -- and closes the child's descriptor only; the
# socket stays open in the parent, and the parent's session with it. /dev/null
# also keeps the descriptor number taken until libpq closes it, so nothing the
# child opens meanwhile can be closed in its place. Without /dev/null the
# descriptor is closed instead, which protects the parent all the same. A
# handle already closed has no socket (-1) and is left alone.
sub _pg_unshare {
  my ($pg) = @_;
  my $entry = $PG_OPENED{ Scalar::Util::refaddr($pg) };
  return if !$entry || $entry->[0] == $$;
  my $fd = $pg->socket;
  return if $fd < 0;
  local $!;
  my $null = POSIX::open('/dev/null', POSIX::O_RDWR());
  if (defined $null) {
    POSIX::dup2($null, $fd);
    POSIX::close($null);
  }
  else {
    POSIX::close($fd);
  }
  return;
}

# The fork-safe handle: EV::Pg with the two ways it closes a connection taken
# over. Defined without a package statement, like
# DBIO::PostgreSQL::EV::Future::_Frame, and naming EV::Pg's methods
# explicitly: SUPER:: would resolve against this file's package.
@DBIO::PostgreSQL::EV::Pool::_Connection::ISA = ('EV::Pg');

sub DBIO::PostgreSQL::EV::Pool::_Connection::finish {
  my ($pg) = @_;
  _pg_unshare($pg);
  $pg->EV::Pg::finish;
  return;
}

sub DBIO::PostgreSQL::EV::Pool::_Connection::DESTROY {
  my ($pg) = @_;
  _pg_unshare($pg);
  delete $PG_OPENED{ Scalar::Util::refaddr($pg) };
  delete $PG_CANCEL{ Scalar::Util::refaddr($pg) };
  # A stand-in EV::Pg in a test may have no destructor.
  $pg->EV::Pg::DESTROY if EV::Pg->can('DESTROY');
  return;
}


sub _new_waiter {
  my ($self) = @_;
  my $waiter = $self->SUPER::_new_waiter;
  $waiter->_queued_in($self) if $waiter->can('_queued_in');
  return $waiter;
}


sub _pg_held_by_callbacks {
  my ($self) = @_;
  return 0 if $self->available;
  my @held = grep { defined } @{ $self->{_connections} || [] };
  return 0 unless @held || $self->_pg_opening;
  for my $conn (@held) {
    DBIO::PostgreSQL::EV::Future->_held_by_callback($conn)
      or DBIO::PostgreSQL::EV::Future->_held_by_spawn($conn)
      or return 0;
  }
  return 1;
}


sub _pg_opening {
  my ($self) = @_;
  my $replaying = grep {
    defined && DBIO::PostgreSQL::EV::Future->_held_by_spawn($_)
  } @{ $self->{_connections} || [] };
  return $replaying + keys %{ $self->{_spawning} || {} };
}


sub _idle_connection_alive {
  my ($self, $pg) = @_;
  return 0 unless $pg->is_connected;
  return 1 if $pg->pending_count;
  return $self->_pg_peer_closed($pg) ? 0 : 1;
}


my $PG_POLL_BROKEN = IO::Poll::POLLHUP() | IO::Poll::POLLERR() | IO::Poll::POLLNVAL();

sub _pg_peer_closed {
  my ($self, $pg) = @_;
  my $fd = $pg->socket;
  return 0 unless defined $fd && $fd >= 0;
  my $rdhup = _pg_rdhup() or return 0;
  return _pg_poll($fd, $rdhup) & ($rdhup | $PG_POLL_BROKEN) ? 1 : 0;
}


my $PG_RDHUP;

sub _pg_rdhup { $PG_RDHUP //= _pg_measure_rdhup() }

sub _pg_measure_rdhup {
  my $bit = 0x2000;
  local ($@, $!);
  my $measured = eval {
    socketpair(my $near, my $far, Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or return 0;
    my $fd = fileno $near;
    syswrite $far, 'x';
    return 0 if _pg_poll($fd, $bit) & $bit;   # open, something to read
    close $far;
    _pg_poll($fd, $bit) & $bit;               # closed behind it
  };
  return $measured || 0;
}

# poll(2) on one descriptor, not waiting: the events it reports, 0 for none
# and when it failed. IO::Poll's XS half is called directly -- its object
# interface wants a filehandle, and all there is of libpq's socket is the
# descriptor. A zero timeout cannot wait, but the kernel answers EINTR for a
# pending signal when there is nothing to report, which says nothing about
# the socket: asked again.
sub _pg_poll {
  my ($fd, $events) = @_;
  local $!;
  my ($found, @ask);
  do {
    @ask   = ($fd, $events);
    $found = IO::Poll::_poll(0, @ask);
  } while ($found < 0 && $! == POSIX::EINTR());
  return $found > 0 ? $ask[1] : 0;
}


sub _shutdown_connection {
  my ($self, $conn) = @_;
  return unless defined $conn;
  return if !$self->{_shutdown} && _pg_close_after_cancel($conn);
  $conn->finish;
}

# A connection retired with a statement in flight -- core drops the connection
# of a transaction, a pipeline or a deploy whose Future was cancelled (core
# k274) -- is closed AFTER the server has been asked to stop the statement.
# EV::Pg's finish drops a cancel_async request that is not through yet
# (PQcancelFinish), unsent: the statement then ran to its end on the server,
# measured 3 s for a pg_sleep(3), against 13 ms with the request answered
# first (karr k75). Returns true when the close is left to the answer.
#
# %PG_CANCEL has an entry, by refaddr, from the moment a request is sent --
# by the statement's own cancel guard (Storage.pm _pg_cancel_guard), or here --
# until it is answered; `close` is set when a retirement is waiting for it.
# The answer's callback holds the handle until then, so a connection nobody
# else holds is not destroyed (and its request with it) before the request is
# through.
sub _pg_cancel_begin {
  my ($pg) = @_;
  $PG_CANCEL{ Scalar::Util::refaddr($pg) } = { pid => $$ };
  return;
}

# The request is answered, ($ok, $err) being what EV::Pg called back with: close
# the connection if a retirement asked for it meanwhile. A request that ended
# with the connection (EV::Pg's finish says "connection closed") has nothing
# left to close.
sub _pg_cancel_end {
  my ($pg, $ok, $err) = @_;
  return unless defined $pg;
  my $rec = delete $PG_CANCEL{ Scalar::Util::refaddr($pg) };
  return unless $rec && $rec->{close} && $rec->{pid} == $$;
  return if !$ok && defined $err && $err eq 'connection closed';
  local $@;
  eval { $pg->finish; 1 };
  return;
}

sub _pg_cancel_is_out {
  my ($pg) = @_;
  my $rec = $PG_CANCEL{ Scalar::Util::refaddr($pg) };
  return $rec && $rec->{pid} == $$ ? 1 : 0;
}

sub _pg_close_after_cancel {
  my ($pg) = @_;
  return 0 unless $pg->can('cancel_async') && $pg->is_connected && $pg->pending_count;
  # Not in pipeline mode: a request there stops the one statement the server
  # is on, and the rest of the batch runs on -- the guard sends none either,
  # and a pipeline whose exit failed is closed at once (t/64).
  return 0 if $pg->can('pipeline_status') && $pg->pipeline_status;
  my $addr = Scalar::Util::refaddr($pg);
  if (_pg_cancel_is_out($pg)) {
    $PG_CANCEL{$addr}{close} = 1;
    return 1;
  }
  _pg_cancel_begin($pg);
  my $sent = eval { $pg->cancel_async(sub { _pg_cancel_end($pg, @_) }); 1 };
  unless ($sent) {
    delete $PG_CANCEL{$addr};
    return 0;
  }
  $PG_CANCEL{$addr}{close} = 1;
  return 1;
}


sub _transform_conninfo { conninfo_string($_[1]) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::EV::Pool - EV::Pg connection pool for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  my $pool = DBIO::PostgreSQL::EV::Pool->new(
      conninfo => 'dbname=myapp',
      size     => 10,
      on_error => sub { warn $_[0] },
  );

  my $pg    = $pool->acquire;    # get idle connection
  my $lease = $pool->_lease($pg);  # the lease of this borrow
  $pool->release($pg, $lease);   # return to pool; a stale lease releases nothing
  my $pg = $pool->acquire_txn;   # pinned for transaction

=head1 DESCRIPTION

Connection pool for L<DBIO::PostgreSQL::EV::Storage>. Manages a pool of
L<EV::Pg> connections, dispatching queries to available connections
and queuing when all are busy.

The acquire / release / capacity / shutdown mechanics, including the
connection-readiness gate B<and its wiring>, are inherited from
L<DBIO::Storage::PoolBase>; this class supplies only the
EV::Pg seam — see L</_create_connection>, L</_new_connection>,
L</_shutdown_connection> and L</_transform_conninfo> — the fork safety its
connections need in a forked child (L</Fork safety>), and the report that one
of them died, so the pool retires it instead of handing it out again
(L</_new_connection>). That report comes when the L<EV> loop runs;
for a connection whose session ended while it sat idle and the loop did not,
this class answers core's question before the connection is handed out
(L</_idle_connection_alive>). It also marks the Future a queued caller
waits on (L</_new_waiter>) and answers whether every connection is held by a
callback that is running, or by a spawn that is (L</_pg_held_by_callbacks>,
L</_pg_opening>): what L<DBIO::PostgreSQL::EV::Future/await> needs to refuse a
blocking wait for a connection that cannot come back while it lasts.

EV::Pg is a B<callback-shaped> transport, which is why no readiness override
is needed here: C<EV::Pg::new> installs C<on_error> and C<on_connect> and only
B<then> starts the connect (C<connect> / C<connect_params>), so the callbacks
are armed before any connect event can fire and core's
L<DBIO::Storage::PoolBase/_create_ready_connection> can express this
transport's readiness. A B<poll-shaped> transport — one with no connect
callbacks, whose readiness is a probe plus a poll, as in L<DBIO::Async> — must
still override the seam; see core's C<_connection_ready_future> POD.

=head2 Fork safety

A forked child shares the socket of every connection the pool had opened, and
L<EV::Pg> knows nothing of C<fork> (0.02 and 0.07 alike). Two things went wrong
in the child, both measured against PostgreSQL 18.6 with EV::Pg 0.07:

=over 4

=item * Closing its copy of a connection ended the parent's session. EV::Pg's
C<finish> and its destructor both call libpq's C<PQfinish>, which sends the
server a Terminate message on the shared socket, and the backend exits. The
destructor runs on its own when the child exits, so a child that did nothing
but C<exit> left the parent with I<"server closed the connection
unexpectedly"> on every pooled connection.

=item * A child that resumed the L<EV> loop read the parent's replies. EV
re-arms the default loop in a child and EV::Pg's watchers stay armed on the
shared sockets, so the child took the reply to a statement that was in flight
when it forked; the parent's statement never completed, and the pool of one it
ran on stayed checked out.

=back

Every connection L</_new_connection> builds is therefore closed fork-safe --
the pooled ones, and the storage's dedicated LISTEN connection, which
L<DBIO::PostgreSQL::EV::Storage/_listen_open> builds here too. It remembers
the process that opened it, and in any other process its C<finish> and its
destructor first point the connection's file descriptor at F</dev/null>, so
C<PQfinish> sends its Terminate nowhere and closes the child's descriptor
only; the parent's session is left as it was. That is the counterpart of
DBD::Pg's C<InactiveDestroy>, which EV::Pg does not have: a handle cannot be
dropped without being closed, so the close is made harmless instead. It covers
every way the child lets go of a connection -- C<exit>, dropping the pool, a
C<finish> or retirement in the child -- and it is the half of core's fork
guard (L<DBIO::Storage::PoolBase/_verify_pid>) that core leaves to the
transport.

For a child that resumes the loop, the first connection also arms one
L<EV/fork> watcher. The first thing the child's loop does is run it, and it
closes that way every connection opened by another process that is still
alive in the child -- idle, checked out for a query or pinned for a
transaction alike, and also one the pool no longer counts -- before any of
them can read. C<finish> calls back every statement in flight with a
I<"connection finished"> error; the callbacks of
L<DBIO::PostgreSQL::EV::Storage> return at once outside the process that
issued the statement, so no release, no Future and no caller's callback runs
in the child. A callback you handed to a connection yourself (through
C<txn_pg>, say) does get that error in the child. The watcher never keeps the
loop running: an active L<EV/fork> watcher alone keeps C<EV::run> from ever
returning, so it is armed with C<keepalive(0)>.

Connections the child opens itself are its own and are left alone. That a
child which queries through the pool gets connections of its own rather than
the parent's is core's side of the guard, L<DBIO::Storage::PoolBase/_verify_pid>.

=head1 METHODS

=head2 _create_connection

Builds one L<EV::Pg> connection from the (already-transformed) conninfo
string, delegating to L<DBIO::Storage::PoolBase/_create_ready_connection> so
the per-connection readiness Future is wired to C<on_connect> / C<on_error>
and registered for us. The pool tracks the returned connection —
do not push it onto C<_connections> yourself.

C<EV::Pg-E<gt>new> returns before its async connect finishes, so a pool that
skipped this gating would hand back a brand-new handle whose C<on_connect> has
not fired, and the very first query on a cold pool would throw C<not
connected>. Calling C<_create_ready_connection> is how this driver
B<opts in> to core's gate; the gate itself is core's.

=head2 _new_connection

Constructs the underlying L<EV::Pg> handle from the named arguments
L<DBIO::Storage::PoolBase/_create_ready_connection> passes (the conninfo plus
the C<on_connect> / C<on_error> of the readiness wiring), and makes it one that
closes fork-safe (L</Fork safety>): the handle is an L<EV::Pg> of a private
subclass that remembers the process that opened it. The registration is core's.

Core makes this a B<named method> rather than a coderef precisely so a test can
subclass the pool and return a fake connection, exercising the readiness wiring
with no event loop and no database (F<t/04-pool-readiness.t>). This driver had
cut the same seam by hand as C<_new_ev_pg> before core named it.
A fake connection bypasses the fork safety along with EV::Pg.

It is also the constructor of the storage's dedicated LISTEN connection:
L<DBIO::PostgreSQL::EV::Storage/_listen_open> calls it as a class method with
that connection's own handlers and C<keep_alive>, so the LISTEN connection
closes fork-safe exactly like a pooled one. It is not registered with any
pool.

No message of a handle built here quotes a password. L<EV::Pg>
speaks in libpq's words, and libpq quotes what it could not read of a
conninfo -- a C<postgresql://> URI whole, C<user:password@> included. The
constructor croaks with that when libpq refuses the conninfo, which fails the
C<acquire> of a pooled statement and the open of the LISTEN connection; this
method rethrows it, and hands every C<on_error> its text, with the passwords
shown as C<***> (C<DBIO::Util::mask_connect_secrets>). What it
cannot see is a piece of a password libpq quotes on its own: a hand-written
conninfo string with an unquoted blank in the password leaves libpq
complaining about the word behind the blank.

Called on a pool, it also makes the connection report its own death: its
C<on_error> first tells the pool the connection is dead
(L<DBIO::Storage::PoolBase/_mark_connection_dead>), then runs the C<on_error>
core's readiness wiring passed in. L<EV::Pg> calls C<on_error> only when the
connection is gone -- the connect failed, or the server closed it, the socket
broke, the protocol went out of step -- and always before it fails the
statements queued on it, so a statement error the session survives never gets
there. An idle connection whose backend dies is retired as soon as the L<EV>
loop reads the end of the connection, and the next C<acquire> spawns a fresh
one; a checked-out one is retired when it is handed back (see
L<DBIO::PostgreSQL::EV::Storage/_dispatch_query>). C<on_error> comes from
EV::Pg's read watcher, so only while the loop runs: an idle connection whose
session ended with nobody running the loop is still listed idle, and is found
when it is next borrowed (L</_idle_connection_alive>). The handler holds the
pool and the connection weakly, so neither is kept alive by it, and it reports
nothing in a process other than the one that opened the connection (L</Fork
safety>). The LISTEN connection gets none of this: it is not the pool's, and
core heals it (L<DBIO::Storage::Async/_listen_lost>).

=head2 _new_waiter

The waiter seam of L<DBIO::Storage::PoolBase/acquire>: the pending Future a
caller waits on that had to be queued, because no connection is idle and the
pool has no room to open one. That is a pool at its size -- or one below it
whose remaining slots are taken by a spawn in flight: a spawn holds its slot
from before it asks for the conninfo, so a caller that comes in from inside it
is queued behind it, in a pool of one with no connection open yet
(L<DBIO::Storage::PoolBase/acquire>). Core's, of the pool's C<future_class>,
and told which pool queued it (L<DBIO::PostgreSQL::EV::Future/_queued_in>) --
everything chained off it, the Future a blocking call finally waits on
included, carries that along. It is what lets
L<DBIO::PostgreSQL::EV::Future/await> see that it waits for a queued caller,
and refuse the wait when no connection can come back while it lasts
(L</_pg_held_by_callbacks>). A C<future_class> that is not a
L<DBIO::PostgreSQL::EV::Future> is left as core made it.

=head2 _pg_held_by_callbacks

  my $stuck = $pool->_pg_held_by_callbacks;

Is every connection of the pool held by something on the call stack right
now -- a callback that is running, or a spawn that is -- so that none of them
can come back before that has returned? Asked about a caller that is queued
(L</_new_waiter>). True when no connection is idle and each slot the pool has
taken is held in one of two ways:

=over 4

=item * B<by a callback>: the connection has a callback of this transport on
the call stack and nothing but that callback's statement pending
(L<DBIO::PostgreSQL::EV::Future/_held_by_callback>). That is a pooled
statement whose Future is being settled -- its C<then> callbacks run before
the connection is handed back -- or a transaction whose coderef, or a C<then>
on one of its statements, is running: it gives its connection back only after
C<COMMIT> or C<ROLLBACK>, and the answer to either cannot be delivered before
the callback has returned.

=item * B<by a spawn> (L</_pg_opening>): the pool is opening the
connection, synchronously, inside the C<acquire> that found room for it, and
that C<acquire> has not returned. Whatever asks this question while it lasts
runs above the spawn on the call stack -- in the AccessBroker's answer, or in
a callback the L<EV> loop ran while the broker's client, or the replay of a
connect statement, waited -- and the connection is handed out only after the
spawn has returned.

=back

A caller queued for a connection is not served while that lasts, and a
blocking wait for it would never end (L<DBIO::PostgreSQL::EV::Future/await>).
A spawn is looked at: a pool with nothing but a spawn in flight -- no
connection yet, in a pool of one -- counts as held, so the wait is refused
instead of hanging or dying of a loop that has run dry
(F<t/77-blocking-behind-spawn-mock.t>, F<t/78-blocking-behind-spawn-live.t>).

False as soon as one connection could still come back: one that is idle or
still connecting for a caller whose C<acquire> has returned, one checked out
by a statement that is in flight -- its answer releases it -- and one none of
whose callbacks is running, whatever holds it. False too for a pool that
holds nothing at all, neither a connection nor a spawn. Room to open another
connection is not looked at: a caller is queued only when the pool has none.

=head2 _pg_opening

  my $count = $pool->_pg_opening;

How many of the pool's slots are held by a spawn that is running: a
connection the pool is opening inside an C<acquire> that has not returned.
A spawn holds its slot in two stretches, and both are counted:

=over 4

=item * from before the pool asks for the conninfo until the handle exists
(L<DBIO::Storage::PoolBase/acquire>): the C<conninfo_provider> --
an AccessBroker's answer --, L</_transform_conninfo> and
L</_create_connection>. The slot is reserved and no connection is counted
yet; this is where a pool of one with no connection is full;

=item * while a connect statement is replayed on the new connection
(L<DBIO::PostgreSQL::EV::Storage/_run_pool_connect_statement>): the connection
is counted by then, and the replay runs the L<EV> loop until the statement is
answered (L<DBIO::PostgreSQL::EV::Future/_held_by_spawn>).

=back

Every spawn it counts is a frame on the call stack below whoever asks, since
a spawn is synchronous through both stretches. Not counted: a connection
whose spawn has returned and that is still connecting -- the loop brings that
one up --, and a connect action that runs the loop by a way of its own, not
through the connect statement seam.

=head2 _idle_connection_alive

  my $alive = $pool->_idle_connection_alive($pg);

The borrow-time liveness seam of L<DBIO::Storage::PoolBase/acquire>: asked
about every idle connection the pool is about to hand out. One it does not
vouch for is retired by core, which then takes the next idle connection, or
opens one. So a session that ended while its connection sat idle --
C<pg_terminate_backend>, C<idle_session_timeout>, a server restart -- costs no
caller a failed statement, also in a program that only ever blocks and so
never runs the L<EV> loop between two calls. Before that the pool learned of
such an end from L<EV::Pg>'s C<on_error> alone (L</_new_connection>), which
reaches as far as the loop does: the first call after it was handed the dead
connection, and failed.

A connection is taken for dead only where that is certain, in this order:

=over 4

=item 1. L<EV::Pg/is_connected> is false: dead. The handle has no connection
any more and nobody told the pool -- a caller called C<finish> on it, or
EV::Pg lost it with a caller's C<on_error> in place of the pool's.

=item 2. A statement is queued or in flight on it (L<EV::Pg/pending_count>):
vouched for, without a look at the socket. A statement of this transport's
own is answered before its connection goes back to the pool, but a caller
that kept the handle can leave one on an idle connection
(L<DBIO::PostgreSQL::EV::TransactionContext/txn_pg>). Retiring the connection
would call that statement's callback from inside C<acquire>; its own read
reports a lost connection instead.

=item 3. The server's end of the socket is closed (L</_pg_peer_closed>): dead.

=back

Everything else is vouched for. That the socket has something to B<read> says
nothing here, and is not asked: a PostgreSQL server writes to a live idle
session too -- a notification on a channel the session listens on, a notice, a
parameter change, a TLS session ticket -- and such a session keeps its
connection; what was sent stays on the socket for the loop to read.

It answers and does nothing else. Nothing is sent, nothing is read, no
callback runs, the L<EV> loop is not run, and it does not wait: what it costs
a borrow is three accessors of the handle and one C<poll> with a zero timeout.
The pool is not told either -- core retires the connection it asked about,
quietly: its C<on_error> does not hear of a session found ended here, and the
server's last words (I<"FATAL:  terminating connection due to administrator
command">) are never read.

It narrows the window; it does not close it. Not seen:

=over 4

=item * a session that ends after the look -- its statement fails, and the
connection is retired on the way back
(L<DBIO::PostgreSQL::EV::Storage/_pg_report_if_dead>);

=item * a session that is ending. A backend sends its last message and then
exits, and its end of the socket closes when the process is gone: 5 to 7
milliseconds after C<pg_terminate_backend> had returned, measured against
PostgreSQL 18.6. A borrow in between finds a readable, open socket and vouches;

=item * a peer that went without closing -- a partition, a host that is gone.
The kernel reports that only once it has given up on the connection (TCP
keepalive, which libpq turns on);

=item * anything, on a platform whose C<poll> has no flag for a closed peer
(L</_pg_peer_closed>): there step 3 vouches for every connection, as the pool
did before.

=back

B<Measured> against PostgreSQL 18.6 with EV::Pg 0.07 on libpq 17, over plain
TCP (F<t/63-idle-liveness-live.t>): the idle session terminated and its
backend gone, or ended by C<idle_session_timeout> -- the next call completes on
a new session, without the loop having run; a live idle session with
notifications waiting, with the unread answer of a statement, a notice among
it, or 4 MB of one -- vouched for every time, and nothing of it lost. The look
took 6 microseconds asked back to back, 15 to 20 as part of a borrow, where a
statement's round trip took 2100. B<Not measured>: TLS (the server at hand had
C<ssl = off>; the look is at the TCP connection underneath, where a TLS record
is data like any other and the close is the same close), a server restart
(its backends exit as a terminated one does), EV::Pg 0.02 (its
C<is_connected>, C<pending_count> and C<socket> are the same code), and a
Unix-domain socket to a server (the kernel answers the same for a socket pair
of that kind, F<t/57-idle-liveness-mock.t>).

It is asked only about connections of the process that owns the pool: a
forked child's first C<acquire> drops the connections it inherited before any
of them is looked at (L</Fork safety>).

=head2 _pg_peer_closed

  my $closed = $pool->_pg_peer_closed($pg);

Has the other end of C<$pg>'s socket been closed? One C<poll> with a zero
timeout on L<EV::Pg/socket>, asking for the one thing the kernel knows without
anything being read: that the peer has closed, or shut down its sending side
(C<POLLRDHUP>), that the connection is broken (C<POLLERR>, C<POLLHUP>), or
that the descriptor is not open (C<POLLNVAL>). C<POLLRDHUP> is reported for a
socket with unread data in front of the close as well -- a backend's last
message, a TLS alert -- which is what tells a session that ended from one that
was merely sent something: C<POLLIN> is not asked for.

False -- not known to be closed -- for a handle without a socket, when C<poll>
fails, and on a platform where a closed peer cannot be asked for. Perl has no
name for C<POLLRDHUP> and its value is the platform's, so the bit (Linux:
0x2000) is not taken on trust: L</_pg_rdhup> measures it. Where there is none,
nothing is polled.

=head2 _pg_rdhup

  my $bit = DBIO::PostgreSQL::EV::Pool::_pg_rdhup();

The C<poll> event bit that says the peer of a stream socket has closed
(C<POLLRDHUP>), or 0 where this platform's C<poll> has none that behaves so.
A function, measured once per process on a socket pair of its own: the bit
counts only if C<poll> reports it for a peer that closed behind unread data,
and does not report it for an open socket that has something to read.

=head2 _shutdown_connection

Closes one L<EV::Pg> connection during L<DBIO::Storage::PoolBase/shutdown>.
Errors are swallowed by the caller. The base class clears the connection's
readiness Future from its side table — this override never has
to.

A connection with a statement in flight that is retired is closed only once
the server has answered a cancel request for it: a core that retires the
connection of a cancelled transaction, pipeline or deploy would otherwise have
EV::Pg drop the request unsent, and the statement would run to its end. Not so
during shutdown, nor in pipeline mode (a request stops the one statement the
server is on, and the batch runs on), which close at once. See
L<DBIO::PostgreSQL::EV::Storage/Cancelling a statement>.

=head2 _transform_conninfo

  my $string = $pool->_transform_conninfo($conninfo);

The libpq conninfo string one new connection is opened with -- this driver's
side of L<DBIO::Storage::PoolBase/_transform_conninfo>, which core calls for
every spawn with the pool's C<conninfo> or with what its C<conninfo_provider>
answered. Rendered by L<DBIO::PostgreSQL::EV::ConnectInfo/conninfo_string>, it
takes the two things L<DBIO::PostgreSQL::EV::Storage/pool> gives the pool:

=over 4

=item * B<a hashref of libpq connection parameters> -- what
L<DBIO::PostgreSQL::EV::Storage/_async_broker_conninfo> makes of an
AccessBroker's answer -- becomes C<keyword=value> pairs, quoted where libpq
needs it, an undefined value left out;

=item * B<a libpq conninfo string> -- the static conninfo, or a broker's answer
that was one -- comes back unchanged.

=back

An arrayref is not taken: it dies, with Perl's own complaint about the
reference, which holds nothing of what was in it. An arrayref here would be
connect info nobody has read -- the DBI form
C<[ $dsn, $user, $password, \%attrs ]>, or a C<[ \%conninfo, \%opts ]> pair --
and reading those is the storage's
(L<DBIO::PostgreSQL::EV::Storage/connect_info>,
L<DBIO::PostgreSQL::EV::Storage/_async_broker_conninfo>), where the rules about
them are kept; the storage never hands the pool one. A spawn that dies here
fails its C<acquire>, and no connection is constructed.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
