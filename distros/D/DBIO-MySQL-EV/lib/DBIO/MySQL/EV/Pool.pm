package DBIO::MySQL::EV::Pool;
# ABSTRACT: EV::MariaDB connection pool for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Storage::PoolBase';

use Carp ();
use Scalar::Util ();
use IO::Handle ();
use DBIO::Util ();
use DBIO::MySQL::EV::QueryExecutor ();




sub _create_connection {
  my ($self, $conninfo) = @_;
  $self->_mysql_refuse_unconnectable($conninfo);
  $self->{_mysql_fork} ||= _mysql_pool_fork_watcher($self);
  return $self->_create_ready_connection(%$conninfo);
}


sub _mysql_connectable {
  my ($class, $conninfo) = @_;
  return 0 unless ref $conninfo eq 'HASH';
  return (defined $conninfo->{host} || defined $conninfo->{user}) ? 1 : 0;
}


sub _mysql_refuse_unconnectable {
  my ($class, $conninfo) = @_;
  return if $class->_mysql_connectable($conninfo);
  my $shape = !defined $conninfo      ? 'nothing (undef)'
            : ref $conninfo ne 'HASH' ? (ref $conninfo ? 'a ' . ref($conninfo) . ' ref' : 'a plain string')
            : !%$conninfo             ? 'an empty hashref'
            :                           sprintf 'a hashref with keys (%s)', join ', ', sort keys %$conninfo;
  Carp::croak("MySQL ev cannot connect from the connect info: $shape. "
    . 'It takes a hashref of EV::MariaDB connection parameters that names a '
    . 'host or a user -- EV::MariaDB opens no connection without one of them, '
    . 'and takes no connection string');
}

# The pool's fork guard: one EV::fork watcher for all its connections, armed in
# the process that creates the first one. When it fires, the parent's handles
# are in one of two places, and it finishes both, with no bookkeeping per
# connection:
#   - _connections, as long as this process neither armed the watcher nor
#     owns the pool: everything the pool holds is then inherited -- idle,
#     checked out and pinned alike, since checked-out and pinned ones stay in
#     _connections and a retired one has left it. The process that armed the
#     watcher opened the pool's first connection (a parent that ever opened
#     one armed it already), so the pool holds nothing it inherited -- k46's
#     check. Once this process owns the pool (core karr k233), _connections
#     holds its OWN connections and must be left working. With k233 the first
#     check never changes an outcome: a process opens a connection only
#     through acquire, whose _verify_pid made it the owner. With a core before
#     k233 the owner never changes, and the two checks together are exactly
#     k46's.
#   - the weak stash our _verify_pid fills just before core drops the inherited
#     connections on takeover. Only a handle something else keeps alive is
#     still there -- a statement in flight, a pinned transaction -- and it
#     still has its watchers on the parent's socket (karr k54).
# The pool's own state is left as it is. Private helpers are _mysql_*: they
# share an inheritance chain with core's privates, as in
# DBIO::MySQL::EV::Storage.
#
# keepalive(0): an active EV::fork watcher alone keeps EV::run from ever
# returning. A guard must never be the reason the loop goes on running -- a
# program that runs the loop until its queries are done would hang on it, in
# the parent and in a child alike. It still fires after a fork.
sub _mysql_pool_fork_watcher {
  my ($pool) = @_;
  require EV;
  my $w = EV::fork(_mysql_pool_fork_cb($pool, $$));
  $w->keepalive(0);
  return $w;
}

sub _mysql_pool_fork_cb {
  my ($pool, $pid) = @_;
  Scalar::Util::weaken(my $weak_pool = $pool);
  return sub {
    my $pool = $weak_pool or return;
    my @parents = grep { defined } @{ delete $pool->{_mysql_inherited} || [] };
    push @parents, grep { defined } @{ $pool->{_connections} || [] }
      if $$ != $pid && _mysql_pool_inherited($pool);
    # A child resumed the event loop. Its copies of the parent's handles must
    # not read the parent's sockets: finish them, which in a forked process
    # drops the watchers and the client state without sending COM_QUIT or
    # shutting the shared sockets down.
    for my $mdb (@parents) {
      local $@;
      eval { $mdb->finish; 1 };
      DBIO::MySQL::EV::QueryExecutor->forget($mdb);   # karr k82
    }
    return;
  };
}

# Does this process NOT own the pool -- are the pool's connections still the
# ones it inherited across a fork? Exactly the test core's _verify_pid acts on
# (karr core k233), so our _verify_pid and the fork watcher agree with core on
# which connections are the parent's. Deliberately not the negation of core's
# _teardown_belongs_here: that counts a pool with no recorded owner as not
# ours, the safe side for closing and the unsafe one here, where finish in the
# process that opened a handle is a real close. A pool with no recorded owner
# is left alone, as core's _verify_pid leaves it.
sub _mysql_pool_inherited {
  my ($pool) = @_;
  my $owner = $pool->{_owner_pid};
  return defined $owner && $owner != $$ ? 1 : 0;
}


sub _verify_pid {
  my ($self) = @_;
  if (_mysql_pool_inherited($self)) {
    my $stash = $self->{_mysql_inherited} ||= [];
    push @$stash, grep { defined } @{ $self->{_connections} || [] };
    Scalar::Util::weaken($_) for @$stash;
  }
  return $self->SUPER::_verify_pid(@_);
}


sub _new_connection {
  my ($self, %args) = @_;

  # Weak, like core's own on_connect / on_error: the handle keeps its handlers
  # for as long as it lives, and the pool holds the handle.
  my $on_error = $args{on_error};
  my $weak_mdb;
  Scalar::Util::weaken(my $weak_pool = $self);
  $args{on_error} = sub {
    my ($pool, $mdb) = ($weak_pool, $weak_mdb);
    $pool->_mysql_report_if_gone($mdb) if $pool && $mdb;
    $on_error->(@_) if $on_error;
    return;
  };
  my $mdb = $self->_mysql_new_handle(%args);
  Scalar::Util::weaken($weak_mdb = $mdb);
  return $mdb;
}


sub _mysql_new_handle {
  my ($class, %args) = @_;
  require EV::MariaDB;

  # CLIENT_FOUND_ROWS on, as both DBDs have it: an UPDATE reports the rows it
  # matched, not only those it changed (karr k80). Off only when the connect
  # info says found_rows => 0 (mysql_client_found_rows=0 in a DSN).
  $args{found_rows} = 1 unless defined $args{found_rows};

  if (my $on_error = $args{on_error}) {
    $args{on_error} = sub {
      $on_error->(DBIO::Util::mask_connect_secrets($_[0]), @_[1 .. $#_]);
      return;
    };
  }
  # Over TLS libmariadb leaves the socket blocking, and a blocking socket holds
  # the loop for every statement (karr k85). Once the connect is done -- and
  # after every reconnect, on_connect fires again -- the socket is made
  # non-blocking, so the handle suspends on EAGAIN as it does over plain TCP.
  # For every handle, not only one with ssl_* parameters (karr k95): the connect
  # info does not say whether TLS was negotiated, and over plain TCP the flag
  # was measured to change nothing (MySQL 8.0, MariaDB 11.8).
  my $weak_mdb;
  my $on_connect = $args{on_connect};
  $args{on_connect} = sub {
    _mysql_socket_nonblocking($weak_mdb) if $weak_mdb;
    return $on_connect ? $on_connect->(@_) : ();
  };
  my ($mdb, $died);
  {
    local $@;   # the caller's $@ is left alone when the handle is made
    eval { $mdb = EV::MariaDB->new(%args); 1 } or $died = $@ || 'EV::MariaDB->new died';
  }
  Scalar::Util::weaken($weak_mdb = $mdb) if defined $mdb;
  return $mdb unless defined $died;
  die DBIO::Util::mask_connect_secrets($died, [ undef, $args{user}, $args{password} ]);
}


sub _mysql_socket_nonblocking {
  my ($mdb) = @_;
  my $fd = $mdb->socket;
  return 0 unless defined $fd && $fd =~ /\A[0-9]+\z/;
  open(my $dup, '+<&', $fd) or return 0;
  $dup->blocking(0);
  close $dup;
  return 1;
}


sub _mysql_connection_gone {
  my ($self, $mdb) = @_;

  # Guarded before vec, which dies on a negative offset.
  my $fd = $mdb->socket;
  return 1 unless defined $fd && $fd =~ /\A[0-9]+\z/;

  return 0 if $mdb->pending_count;

  # select only reports: what the server sent stays on the socket. A zero
  # timeout cannot wait, but it can be interrupted -- the kernel answers EINTR
  # for a pending signal when nothing is readable -- which says nothing about
  # the socket, so ask again.
  my $rin = '';
  vec($rin, $fd, 1) = 1;
  my $found;
  do { $found = select(my $rout = $rin, undef, undef, 0) }
    while $found < 0 && $!{EINTR};

  # Readable (> 0) is gone; so is a select that failed (< 0, the fd is not
  # open). Only "nothing to read" is a session that is still there.
  return $found == 0 ? 0 : 1;
}


sub _mysql_report_if_gone {
  my ($self, $mdb) = @_;
  $self->_mark_connection_dead($mdb) if $self->_mysql_connection_gone($mdb);
  return;
}


sub _idle_connection_alive {
  my ($self, $mdb) = @_;
  return $self->_mysql_connection_gone($mdb) ? 0 : 1;
}


sub _new_waiter {
  my ($self) = @_;
  my $waiter = $self->SUPER::_new_waiter;
  $waiter->_queued_in($self) if $waiter->can('_queued_in');
  return $waiter;
}


sub _mysql_held_by_callbacks {
  my ($self) = @_;
  return 0 if $self->available;
  return 0 if keys %{ $self->{_spawning} || {} };
  my @held = grep { defined } @{ $self->{_connections} || [] } or return 0;
  DBIO::MySQL::EV::QueryExecutor->_waits_for_callback($_) or return 0 for @held;
  return 1;
}


sub _shutdown_connection {
  my ($self, $mdb) = @_;
  return unless defined $mdb;
  local $@;
  # Before finish: it calls back the statement in flight, which would start
  # the waiting ones on the finished handle (karr k98).
  DBIO::MySQL::EV::QueryExecutor->_fail_waiting($mdb);
  eval { $mdb->finish; 1 };
  my $err = $@;
  DBIO::MySQL::EV::QueryExecutor->forget($mdb);
  die $err if $err;
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::EV::Pool - EV::MariaDB connection pool for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  my $pool = DBIO::MySQL::EV::Pool->new(
      conninfo     => { host => 'localhost', database => 'myapp', user => 'myapp' },
      size         => 10,
      future_class => 'DBIO::MySQL::EV::Future',
      on_error     => sub { warn $_[0] },
  );

  # acquire returns a Future, not a connection: it resolves with a
  # connected EV::MariaDB handle -- an idle one, a freshly connected one,
  # or the next one released while the pool has no room for another -- and
  # fails if the connect is refused.
  $pool->acquire->then(sub {
      my $mdb = shift;
      $mdb->query('SELECT 1', sub {
          my ($rows, $err) = @_;
          $pool->release($mdb);     # back to the pool, or to the next waiter
          ...
      });
      return;
  })->retain;

  # acquire_txn: the same Future; the handle stays yours until you release it
  $pool->acquire_txn->then(sub {
      my $mdb = shift;
      ...
  })->retain;

L<DBIO::MySQL::EV::Storage/pool> builds this pool for you, wired to the
storage; constructing one yourself is for tests and tooling.

=head1 DESCRIPTION

Connection pool for L<DBIO::MySQL::EV::Storage>. Manages a pool of
L<EV::MariaDB> connections, dispatching queries to available connections
and queuing when all are busy.

The acquire / release / capacity / shutdown mechanics B<and> the
connection-readiness gate are inherited from L<DBIO::Storage::PoolBase>;
this class supplies only the EV::MariaDB seam — see L</_create_connection>,
L</_new_connection> and L</_shutdown_connection> — the fork guard its
connections need in a child that resumes the EV loop (I<Fork safety> under
L</_create_connection>, and L</_verify_pid>), and the answer to whether a
connection's session is gone (L</_mysql_connection_gone>), with which a gone
connection is reported to the pool so that it is retired, never handed out
again (L</_mysql_report_if_gone>), and with which an idle connection
is vouched for, or not, before the pool hands it out
(L</_idle_connection_alive>). It also marks the Future a queued
caller waits on (L</_new_waiter>) and answers whether every connection is held
by a settling that is running (L</_mysql_held_by_callbacks>): what
L<DBIO::MySQL::EV::Future/await> needs to refuse a blocking wait for a
connection that cannot come back while it lasts.

=head1 METHODS

=head2 _create_connection

Builds one L<EV::MariaDB> connection from the (already-transformed)
connect info: a hashref of L<EV::MariaDB> named parameters. Anything else
croaks, and so does a hashref that names neither C<host> nor C<user>
(L</_mysql_refuse_unconnectable>): L<EV::MariaDB> takes no
C<conninfo> string, and starts no connect without one of the two, so the
handle would never call back and the C<acquire> waiting for it never resolve.
The croak reaches that C<acquire> as its failure. The pool tracks the returned
connection -- do not push it onto the pool's C<_connections> list yourself.

Delegates to L<DBIO::Storage::PoolBase/_create_ready_connection>, which
wires the connection's readiness Future for us: C<on_connect> resolves it
with the connection, an error before connect fails it, and the Future is
registered so the inherited L<DBIO::Storage::PoolBase/_connection_ready_future>
finds it. A dependent L<DBIO::Storage::PoolBase/acquire> Future therefore
resolves only on a connected handle, and fails rather than hanging when the
connect is refused (core's wiring).

This driver B<opts into> that wiring; it no longer implements it. Choosing
it is still explicit — core's C<_create_connection> is a required hook
precisely so a pool whose connections are usable the moment the constructor
returns does not get the async gate by accident.

B<Fork safety.> EV::MariaDB closes nothing when a forked child exits or drops
its copy of a handle, so the parent's sessions survive the child. A child that
B<resumes the EV loop>, though, still has every inherited handle's watchers
armed on the sockets it shares with the parent, and would read the reply to a
statement that was in flight when it forked -- the parent's statement then
never completes. The first connection therefore arms one L<EV/fork> watcher
for the pool. In a child it runs before the child's loop runs anything else,
and C<finish>es the child's copy of every handle the child inherited from the
parent -- idle ones, and those checked out for a query or pinned for a
transaction alike: EV::MariaDB's fork-aware close, which leaves the parent's
sessions alone.

It finishes nothing in the process that armed it: that process opened the
pool's first connection, so the pool holds nothing it inherited -- also when a
child opens the first connection of a pool its parent built but never used.

With a current core it never finishes a connection the child opened itself. A
child that uses the pool takes it over (L<DBIO::Storage::PoolBase/_verify_pid>):
its first C<acquire> drops the parent's connections from the pool, and the
child spawns connections of its own. When that happens before the watcher
runs -- a child whose first C<*_async> call comes before its loop does, and
whose loop then runs inside that call's C<get> -- the pool's connections are
the child's, and the watcher leaves them working. The parent's handles the
pool dropped are finished all the same: L</_verify_pid> keeps a weak reference
to each before core lets go of them, and the watcher finishes whichever of
them are still alive when it runs -- held by a statement that was in flight,
say, or by a transaction. Until the child takes the pool over, the
pool's connections are the parent's, and the watcher finishes them.

C<finish> calls back every statement in flight with a "connection finished"
error; the callbacks of L<DBIO::MySQL::EV::QueryExecutor> return at once
outside the process that issued the statement, so no release, no Future and no
caller's callback runs in the child. A callback you passed to a handle yourself
(through C<txn_mdb>, say) does get that error in the child. A child that does
not run the loop never fires the watcher and needs nothing. The watcher holds
the pool weakly and goes away with it, and it never keeps the loop running: an
active L<EV/fork> watcher alone would keep C<EV::run> from ever returning, so it
is armed with C<keepalive(0)> (ADR 0010).

=head2 _mysql_connectable

  my $ok = DBIO::MySQL::EV::Pool->_mysql_connectable(\%conninfo);

Class or instance method. True when C<$conninfo> is a hashref that gives a
C<host> or a C<user>. L<EV::MariaDB>C<< ->new >> starts a connect only then;
otherwise its handle stays unconnected and calls back neither C<on_connect>
nor C<on_error> (EV::MariaDB 0.08). The one test the pool, the listen
connection and a broker's answer share.

=head2 _mysql_refuse_unconnectable

  DBIO::MySQL::EV::Pool->_mysql_refuse_unconnectable($conninfo);

Croaks unless L</_mysql_connectable> holds, loudly instead of leaving a handle
that never calls back. The message names the shape and the keys,
never a value -- connect info carries the password.

=head2 _verify_pid

Extends L<DBIO::Storage::PoolBase/_verify_pid> and changes
nothing of what core does there. In a process that does not own the pool -- a
forked child that inherited it -- it first keeps a B<weak> reference to each
connection the pool holds, all of them the parent's, and then lets core drop
them. The pool's fork watcher finishes those still alive when the child's loop
runs (I<Fork safety> under L</_create_connection>); an idle one
nothing else holds is simply freed, as core intends.

Nothing is finished here. Core also calls this from C<shutdown>, and so from
the pool's C<DESTROY> at a child's global destruction, where EV::MariaDB's
callbacks must not run; finishing belongs to the watcher, which runs only in a
child that resumes the loop.

=head2 _new_connection

Raw-handle seam called by L<DBIO::Storage::PoolBase/_create_ready_connection>:
constructs the L<EV::MariaDB> handle from named arguments (ours, plus the
C<on_connect> / C<on_error> the readiness wiring supplies) and returns it,
tracking nothing. The handle is made by L</_mysql_new_handle>, which keeps
passwords out of what it says.

The handle's C<on_error> first reports the connection to the pool when it is
gone (L</_mysql_report_if_gone>), then runs the C<on_error> the readiness
wiring passed in. It asks rather than assumes: L<EV::MariaDB> calls
C<on_error> for a connect that failed, and for the error of a secondary result
set of a multi-statement query -- which may be the connection lost while those
were read, or a statement error on a session that is still there. An idle
connection reported gone is retired at once, a checked-out one when it is
handed back. EV::MariaDB 0.08 does not watch an idle connection's socket --
the pool looks at it when it is about to hand the connection out
(L</_idle_connection_alive>) -- and it reports a connection lost by a
statement through that statement's callback only, never here; those are
L<DBIO::MySQL::EV::Storage/_query_async>'s to report. The handler holds the
pool and the handle weakly, so it keeps neither alive.

Being a named method is what lets a test subclass the pool and hand back a
fake connection, exercising the readiness wiring with no event loop and no
database (C<t/08-pool-readiness.t>).

=head2 _mysql_new_handle

  my $mdb = DBIO::MySQL::EV::Pool->_mysql_new_handle(%named);

C<< EV::MariaDB->new(%named) >>, with no password in what the handle says
about its connection. The one place every L<EV::MariaDB> handle of
this distribution is made: L</_new_connection> calls it for a pooled
connection, L<DBIO::MySQL::EV::Storage/_listen_open> for the listen
connection -- as a class method, nothing of a pool is used.

Every handle is made with C<< found_rows => 1 >> unless the connect info says
otherwise: CLIENT_FOUND_ROWS is on, as both DBDs have it, so an
C<UPDATE> reports the rows it matched and not only those it changed.
C<mysql_client_found_rows=0> in the DSN (C<found_rows =E<gt> 0>) turns it off.

What a handle says is the client library's text, or the server's, and both
quote what they were given: the name of the database they do not know, the
host they cannot resolve, the socket they cannot open. A password does not
belong in any of those, and ends up in one all the same -- a DSN with a
separator gone wrong puts C<password=...> into the name of the database, and
the server answers C<Unknown database '...'> with it. So every text the handle
hands its C<on_error> is passed on with the passwords shown as C<***>, the way
core masks connect info in a message (C<DBIO::Util::mask_connect_secrets>):
the value of a C<password>, C<passwd>, C<pwd> or C<pass> key and the password
of a URI. That text is what fails the C<acquire> of a pooled statement and the
open of the listen connection, and what the pool's C<on_error> is given. A
croak of the constructor is rethrown masked the same way, and there the
password the handle was to connect with is masked wherever the text repeats
it. The connect info is not kept for it: C<on_error>'s text is masked by what
is in it. An exception that is no string is rethrown as it came.

What it cannot see is a secret under another name, and a password that is
quoted without a key in front of it.

=head2 _mysql_socket_nonblocking

  DBIO::MySQL::EV::Pool::_mysql_socket_nonblocking($mdb);

Sets C<O_NONBLOCK> on the socket of the connected L<EV::MariaDB> handle
C<$mdb>, through a duplicate of the descriptor (the flag belongs to the open
file description, so the duplicate is closed again and the handle's socket
stays open). Returns true when the flag was set, false when the handle has no
socket. Called from L</_mysql_new_handle> for every handle, in its
C<on_connect>: over TLS it is what keeps the event loop running, over plain
TCP it changes nothing observable.

=head2 _mysql_connection_gone

  my $gone = $pool->_mysql_connection_gone($mdb);

Is the session behind the L<EV::MariaDB> handle C<$mdb> gone? Answered from
the handle and its socket alone -- nothing is sent, nothing is read, and it
never blocks:

=over 4

=item * B<no socket>: gone. L<EV::MariaDB/socket> is -1 for a handle that never
connected or was closed (C<finish>, C<close_async>), and from the moment an
operation found the server gone: the client library gives its socket up then.

=item * B<an operation queued or in flight> (L<EV::MariaDB/pending_count>): not
gone. Its reply is due on the socket, so a readable socket says nothing, and
that operation reports a dead connection itself.

=item * otherwise the idle socket must have B<nothing to read>, asked with a
zero-timeout C<select>. A MySQL server never speaks unasked, so a readable
idle socket is the server hanging up -- a C<KILL>, a restart, C<wait_timeout>
-- and means gone.

=back

Two things are deliberately not consulted. L<EV::MariaDB/is_connected> stays
true after the server ended the session, and after an operation failed on it
(ADR 0010, fact 3). And the error message of a failed statement: its wording
is the client library's, or the server's in its C<lc_messages>, and a
statement error leaves the session where it was.

Not seen: a peer that vanished without closing its end (a partition). The next
statement on the connection meets that, bounded by the TCP stack or a
C<read_timeout> in the connect info.

=head2 _mysql_report_if_gone

  $pool->_mysql_report_if_gone($mdb);

Report C<$mdb> to the pool as dead
(L<DBIO::Storage::PoolBase/_mark_connection_dead>) when
L</_mysql_connection_gone> says its session is gone, so the pool retires it
instead of handing it out again: at once when it is idle, when it is handed
back when it is checked out or pinned. Called for a failed statement, before
its connection is released (L<DBIO::MySQL::EV::Storage/_query_async>), and from
the handle's C<on_error> (L</_new_connection>). A handle the pool does not hold
-- one it already retired, or one that was never its own -- is ignored, and the
report may be made any number of times.

=head2 _idle_connection_alive

  my $alive = $pool->_idle_connection_alive($mdb);

The borrow-time liveness seam of L<DBIO::Storage::PoolBase/acquire>: asked
about every idle connection the pool is about to hand out. The answer is
L</_mysql_connection_gone>'s, the other way round. A connection it does not
vouch for is retired by core, which then takes the next idle connection, or
opens one. So a session the server ended while its connection sat idle -- a
C<KILL>, a restart, C<wait_timeout> -- costs no caller a failed call.

It answers and does nothing else: no report to the pool -- core retires the
connection it asked about -- and no operation on the handle. What it costs a
borrow is L<EV::MariaDB/socket>, L<EV::MariaDB/pending_count> and one
C<select> with a zero timeout; nothing is sent and nothing is read, so what
the server sent stays on the socket.

An idle connection with an operation still queued or in flight is vouched
for. Nothing of this transport leaves one behind -- a statement's Future
settles only once its last operation was answered -- but a caller that kept
the handle can (L<DBIO::MySQL::EV::TransactionContext/txn_mdb>). Its reply is
due on the socket, so nothing there says the session is gone, and retiring
the connection would end that operation.

B<What is measured.> The same question is asked of the listen connection
(L<DBIO::MySQL::EV::Storage/_listen_probe>): the socket of an idle connection
the server C<KILL>ed is readable at once (MariaDB 10.11, ADR 0010). On pooled
connections it was run against MySQL 8.0.30 and MariaDB 11.8.8 and 11.8.9, over
plain TCP and over TLS 1.3 (C<TLS_AES_256_GCM_SHA384>; TLS 1.2 and a Unix socket were not
reachable) -- C<t/32-pool-dead-connection-live.t>. A C<KILL> of an idle
connection and a C<wait_timeout> are found by this seam on both servers, in both
modes: the next call runs without an error on a new session and the pool keeps
its size. A healthy idle connection was never taken for gone: its socket was
not readable in 12 calls separated by pauses and after 4 s idle, nor when the
next call was chained in the callback of the previous C<SELECT>, C<INSERT> or
C<insert_async>, or of a C<CALL> with bind values.

B<A session that is still there can be taken for gone> when its idle socket
has something to read and C<pending_count> is 0: the call that borrows then
runs on a newly opened connection, a reconnect and no error from this seam.
What left such a state was a C<CALL> sent as EV::MariaDB's C<query>: for a
C<query>, EV::MariaDB 0.08 runs the callback with the first result and reads
the rest of the answer -- the closing C<OK> packet, further result sets --
only after that callback returned, and neither C<pending_count> nor any
accessor says so. The Future was settled in the callback, so the connection
was back in the pool with the rest unread; a call chained in the callback
found a readable socket (11 to 19 of 20 behind a load balancer, 1 of 20 in a
LAN, over plain TCP, never over TLS 1.3, where libmariadb had read the whole
answer before C<query> returned). A statement with bind values after such a
C<CALL> failed outright.

The executor sends a C<CALL> without bind values through
prepare/execute/close_stmt, where the whole answer is read before the Future
settles (L<DBIO::MySQL::EV::QueryExecutor>), and the state is gone: measured
again 2026-10-22 (ADR 0010, I<Measured again (2026-10-22)>), the
check said "gone" for no healthy connection in any section of
C<t/32-pool-dead-connection-live.t>, on MySQL 8.0.30 and MariaDB 11.8.9, plain
TCP and TLS. The reachable remainder is a statement a session prepared itself
with C<PREPARE ... FROM 'CALL ...'> and ran with C<EXECUTE> as a C<query>: over
plain TCP its first chained call took the session for gone (the ADR has the
numbers). That remainder is a decided limit and is not built: the maintainer
decided on 2026-10-24 not to route the C<PREPARE>/C<EXECUTE> of a
hand-written C<CALL> through prepare/execute; the cost is one reconnect of a
healthy idle connection, never an error. A multi-statement text cannot get there: the connection does not
enable multi statements and both servers refuse it with a syntax error. A
C<CALL>, or any statement, the transport builds is not affected.

It narrows the window and does not close it: a session can end after the
check, or without the server saying so (L</_mysql_connection_gone>). The
statement that finds it so fails, and reports the connection
(L<DBIO::MySQL::EV::Storage/_mysql_execute>).

It is asked only about connections of the process that owns the pool: a
forked child's first C<acquire> drops the connections it inherited before any
of them is looked at (L</_verify_pid>).

=head2 _new_waiter

The waiter seam of L<DBIO::Storage::PoolBase/acquire>: the pending Future a
caller waits on that had to be queued, because no connection is idle and the
pool has no room for another: it is at its size, or what it has left is taken
by a connection it is opening right now. Core's, of the pool's
C<future_class>, and told which pool queued it
(L<DBIO::MySQL::EV::Future/_queued_in>) -- everything chained off it, the
Future a blocking call finally waits on included, carries that along. It is
what lets L<DBIO::MySQL::EV::Future/await> see that it waits for a queued
caller, and refuse the wait when no connection can come back while it lasts
(L</_mysql_held_by_callbacks>). A C<future_class> that is not a
L<DBIO::MySQL::EV::Future> is left as core made it.

=head2 _mysql_held_by_callbacks

  my $stuck = $pool->_mysql_held_by_callbacks;

Is every connection of the pool held by a callback that is running right now,
so that none of them can come back before one of those callbacks returns? True
when no connection is idle and each one the pool holds has a callback of its
own on the call stack and no statement in flight
(L<DBIO::MySQL::EV::QueryExecutor/_waits_for_callback>). That is a transaction
whose coderef, or a C<then> on one of its statements, is running: it gives its
connection back only after C<COMMIT> or C<ROLLBACK>, which cannot be sent
before the callback has returned. A caller queued for a connection is not
served while that lasts, and a blocking wait for it inside those callbacks
would never end (L<DBIO::MySQL::EV::Future/await>).

False as soon as one connection could still come back: a spawn in flight (the
pool counts it against its size, so a caller can be queued behind it although
the pool holds fewer connections than its size; the connection it makes may
serve that caller), one that is idle or still connecting, one checked out by a
statement that is in flight -- its answer releases it -- and one none of whose
callbacks is running, whatever holds it.

=head2 _shutdown_connection

Closes one L<EV::MariaDB> connection during L<DBIO::Storage::PoolBase/shutdown>
and when core retires one, then has L<DBIO::MySQL::EV::QueryExecutor/forget>
drop what the executor kept for it. Errors are swallowed by the
caller.

It uses C<finish>, not C<close_async>: C<close_async> croaks without a callback
(I<Usage: EV::MariaDB::close_async(self, cb)>, EV::MariaDB 0.08) and with
I<not connected> on a handle that is still connecting, and core hands this seam
connections the pool never counted as connected. C<finish> is
synchronous, takes a handle in any state, can be called again, and calls back
the statements still in flight with an error.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
