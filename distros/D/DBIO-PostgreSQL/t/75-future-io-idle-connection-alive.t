use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k90: the future_io transport answers the borrow-time
# seam _idle_connection_alive (dbio-async k28, core k241), so the pool retires
# an idle connection whose backend ended while it sat idle, before a caller's
# statement goes out on it.
#
# WHY: pg_socket alone cannot tell. libpq notices a lost connection only when
# it reads, and nothing reads from an idle pool connection -- after
# pg_terminate_backend the handle still shows an open socket (measured, see
# the POD of _idle_connection_alive). Without the seam the first caller after
# the kill gets "server closed the connection unexpectedly", and after a
# server restart one caller per idle connection does. What the dying server
# leaves is on the socket: its FATAL message, then end of file. But a live
# idle session can also be written to (a notification on a channel it
# LISTENs to), so "readable" must not be taken as "dead" -- the transport lets
# libpq read what arrived and asks the socket verdict again.
#
# What this file claims:
#   1. the verdict: dead for a handle whose libpq socket is gone (pg_socket -1)
#      and for a connection without a handle -- without reading; alive for a
#      socket with nothing on it -- without reading either (one select is all
#      an ordinary borrow costs);
#   2. readable and dead: a server that sent its FATAL message and closed takes
#      two reads (the message, then end of file) and is answered dead, quietly
#      -- no throw, so the pool does not report it as a broken check; end of
#      file alone takes one read;
#   3. readable and alive: a notification, or a notice, on a live session is
#      read and the connection answered alive, its socket still open;
#   4. bounded: a connection that keeps receiving is read at most four times
#      and answered alive -- it is a live one, and must not hold the acquire;
#   5. a read that dies while the socket stays open is rethrown (core reports it
#      to on_error and retires the connection);
#   6. it never blocks and never sends: no prepare / do / ping / pg_ping, no
#      byte reaches the server, and libpq's read runs with the socket in
#      O_NONBLOCK mode, the previous mode restored afterwards;
#   7. through the real pool acquire (DBIO::Async::Pool on core's PoolBase):
#      an idle connection whose server ended is retired and the call runs on a
#      fresh connection without an error or a pool-error report; one that got
#      a notification is reused; and -- the control that shows 7 tests the
#      seam -- with the default answer (no check) the same call fails.
#
# WHAT IS REAL: the pool, core's acquire / _idle_connection_usable /
# _retire_connection, dbio-async's _query_async, _conn_poll_fh and this dist's
# _idle_connection_alive / _pg_nonblocking / _submit_query / _collect_result.
# Each connection's socket is a real socketpair, so select and O_NONBLOCK are
# the kernel's. THE SUBSTITUTIONS: DBI->connect hands out fake DBD::Pg handles
# whose pg_notifies / pg_result do what libpq does with what the "server" end
# of the pair wrote -- lines standing in for protocol messages -- and
# _await_readable resolves at once.

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
  plan skip_all => 'the installed dbio-async predates the _idle_connection_alive seam (dbio-async k28)'
    unless DBIO::Async::Storage->can('_idle_connection_alive')
        && DBIO::Async::Pool->can('_idle_connection_alive');
}

use Future;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use IO::Handle;

# Every wait in this file is a zero-timeout select: a hang is a failure.
$SIG{ALRM} = sub { die "k90 test: something blocked\n" };
alarm 30;

# --- the fake DBD::Pg -----------------------------------------------------------

our (@CONNECTS, @SENT);
my $next_pid = 9500;

{
  package FakeIdle::DBH;

  sub new {
    socketpair(my $client, my $server, Socket::AF_UNIX(), Socket::SOCK_STREAM(),
      Socket::PF_UNSPEC()) or die "socketpair: $!";
    $_->autoflush(1) for $client, $server;
    $client->blocking(1);       # as Future::IO's built-in impl leaves it
    return bless {
      Active    => 1,
      client    => $client,
      server    => $server,
      pg_socket => fileno($client),
      pg_pid    => ++$next_pid,
      read_size => 65536,
      inbuf     => '',
      queue     => [],
      reads     => [],
      sqlstate  => '',
    }, shift;
  }

  # --- the "server" end ---
  sub server_says { my ($self, $line) = @_; print { $self->{server} } "$line\n"; return }
  sub server_ends {
    my ($self) = @_;
    $self->server_says('E FATAL:  terminating connection due to administrator command');
    close $self->{server};
    return;
  }
  sub server_received {
    my ($self) = @_;
    return '' unless $self->{server}->opened;
    $self->{server}->blocking(0);
    my $n = sysread $self->{server}, my $buf, 65536;
    $self->{server}->blocking(1);
    return $n ? $buf : '';
  }

  # libpq's PQconsumeInput: read what the socket holds, never wait for more.
  # End of file drops the socket (pg_socket -1) and fails, as measured.
  sub _consume {
    my ($self, $method) = @_;
    my $n = sysread $self->{client}, my $buf, $self->{read_size};
    if (defined $n && $n == 0) {
      $self->{pg_socket} = -1;
      $self->{sqlstate} = '08000';
      die "DBD::Pg::db $method failed: server closed the connection unexpectedly\n";
    }
    return unless $n;            # EAGAIN: nothing there
    $self->{inbuf} .= $buf;
    while ($self->{inbuf} =~ s/^([NE]) ([^\n]*)\n//) {
      my ($type, $body) = ($1, $2);
      if ($type eq 'N') { push @{ $self->{queue} }, [ split / /, $body, 3 ] }
      else              { warn "$body\n" }      # a notice, via DBD::Pg's pg_warn
    }
    return;
  }

  sub pg_notifies {
    my ($self) = @_;
    push @{ $self->{reads} }, { nonblocking => !$self->{client}->blocking };
    die "DBD::Pg::db pg_notifies failed: lost synchronization with server\n"
      if $self->{die_open};
    $self->_consume('pg_notifies');
    my $n = shift @{ $self->{queue} } or return undef;
    return [ $n->[0], $n->[2], $n->[1] ];      # [ channel, pid, payload ]
  }

  # Anything that would talk to the server is recorded.
  sub prepare {
    my ($self, $sql) = @_;
    push @main::SENT, "prepare: $sql";
    return bless { dbh => $self, sql => $sql }, 'FakeIdle::STH';
  }
  sub do      { push @main::SENT, "do: $_[1]"; 1 }
  sub ping    { push @main::SENT, 'ping';      1 }
  sub pg_ping { push @main::SENT, 'pg_ping';   1 }

  sub pg_ready { 1 }

  # The statement's result: what the server sent is read first, so a closed
  # server fails the statement -- the failure the seam is there to spare.
  sub pg_result {
    my ($self) = @_;
    my $sth = delete $self->{in_flight} or die "no async query is running\n";
    die "DBD::Pg::db pg_result failed: no connection to the server\n"
      if $self->{pg_socket} < 0;
    my $was = $self->{client}->blocking(0);
    # Twice: what the server sent, then -- if it closed -- the end of file.
    my $ok = eval { $self->_consume('pg_result') for 1 .. 2; 1 };
    my $err = $@;
    $self->{client}->blocking(1) if $was;
    die $err unless $ok;
    $self->{sqlstate} = '';
    $sth->{NUM_OF_FIELDS} = 1;
    return 1;
  }

  sub state { $_[0]{sqlstate} }

  sub disconnect {
    my ($self) = @_;
    $self->{Active} = 0;
    $self->{disconnected}++;
    return 1;
  }

  our $AUTOLOAD;
  sub AUTOLOAD {
    my $m = $AUTOLOAD =~ s/.*:://r;
    return if $m eq 'DESTROY';
    push @main::SENT, "unexpected: $m";
    die "FakeIdle::DBH: unexpected call $m\n";
  }
}

{
  package FakeIdle::STH;

  sub execute {
    my ($self) = @_;
    die "DBD::Pg::st execute failed: no connection to the server\n"
      if $self->{dbh}{pg_socket} < 0;
    $self->{dbh}{in_flight} = $self;
    return 1;
  }

  # Every row names the "backend" it ran on, like pg_backend_pid().
  sub fetchall_arrayref { [ [ $_[0]{dbh}{pg_pid} ] ] }
}

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my $dbh = FakeIdle::DBH->new;
    push @CONNECTS, $dbh;
    return $dbh;
  };
}

{
  package FakeIdle::Transport;
  use base 'DBIO::PostgreSQL::Storage::Async';
  sub _await_readable { Future->done }
}

{
  # The control for section 7: the transport without its check, i.e. the
  # seam's default answer.
  package FakeIdle::Unchecked;
  use base 'FakeIdle::Transport';
  sub _idle_connection_alive { 1 }
}

my $T = 'FakeIdle::Transport';

sub with_warnings (&) {
  my ($code) = @_;
  my @w;
  local $SIG{__WARN__} = sub { push @w, $_[0] };
  my @r = $code->();
  return (\@w, @r);
}

sub reads { scalar @{ $_[0]{reads} } }

# ---------------------------------------------------------------------------
# 1. Without reading: gone, no handle, nothing on the socket.
# ---------------------------------------------------------------------------

{
  my $dbh = FakeIdle::DBH->new;
  $dbh->{pg_socket} = -1;
  ok !$T->_idle_connection_alive({ dbh => $dbh }),
    'pg_socket -1 (libpq gave up the connection): dead';
  is reads($dbh), 0, '... answered without a read';
  ok !$T->_idle_connection_alive({}), 'a connection without a handle: dead';

  my $idle = FakeIdle::DBH->new;
  ok $T->_idle_connection_alive({ dbh => $idle }),
    'an idle connection with nothing on its socket: alive';
  is reads($idle), 0, '... answered by the select alone, without a read';
}

# ---------------------------------------------------------------------------
# 2. Readable and dead.
# ---------------------------------------------------------------------------

{
  my $dbh  = FakeIdle::DBH->new;
  my $conn = { dbh => $dbh };
  $dbh->server_ends;

  my ($w, $alive, $threw);
  ($w, $alive) = with_warnings {
    my $a = eval { $T->_idle_connection_alive($conn) };
    $threw = $@;
    $a;
  };
  ok !$alive, 'a server that sent its FATAL message and closed: dead';
  is $threw, '', '... answered, not thrown -- a dead connection is no broken check';
  is reads($dbh), 2, '... after two reads: the message, then end of file';
  is $dbh->{pg_socket}, -1, '... which dropped the socket';
  like join('', @$w), qr/FATAL:  terminating connection/,
    '... and the server\'s message reached DBD::Pg as a notice';
}

{
  my $dbh = FakeIdle::DBH->new;
  close $dbh->{server};
  ok !$T->_idle_connection_alive({ dbh => $dbh }), 'end of file alone: dead';
  is reads($dbh), 1, '... after one read';
}

# ---------------------------------------------------------------------------
# 3. Readable and alive.
# ---------------------------------------------------------------------------

{
  my $dbh = FakeIdle::DBH->new;
  $dbh->server_says('N jobs 4711 wake up');
  ok $T->_idle_connection_alive({ dbh => $dbh }),
    'a notification on a live idle session: alive';
  is reads($dbh), 1, '... after one read';
  cmp_ok $dbh->{pg_socket}, '>=', 0, '... its socket still open';
  is_deeply $dbh->{queue}, [], '... and the notification taken off the queue';
}

{
  my $dbh = FakeIdle::DBH->new;
  my ($w, $alive) = with_warnings {
    $dbh->server_says('E NOTICE:  something harmless');
    $T->_idle_connection_alive({ dbh => $dbh });
  };
  ok $alive, 'a notice on a live idle session: alive';
  is reads($dbh), 1, '... after one read';
}

# ---------------------------------------------------------------------------
# 4. Bounded.
# ---------------------------------------------------------------------------

{
  my $dbh = FakeIdle::DBH->new;
  $dbh->{read_size} = 4;                      # libpq gets a little per read
  $dbh->server_says('N jobs 4711 ' . ('x' x 200));
  ok $T->_idle_connection_alive({ dbh => $dbh }),
    'a connection that keeps receiving: alive';
  is reads($dbh), 4, '... after at most four reads';
}

# ---------------------------------------------------------------------------
# 5. A read that dies with the socket open is rethrown.
# ---------------------------------------------------------------------------

{
  my $dbh = FakeIdle::DBH->new;
  $dbh->{die_open} = 1;
  $dbh->server_says('N jobs 4711 x');
  my $alive = eval { $T->_idle_connection_alive({ dbh => $dbh }) };
  like $@, qr/lost synchronization/, 'a read failing with the socket open throws its error';
}

# ---------------------------------------------------------------------------
# 6. Never sends, never blocks.
# ---------------------------------------------------------------------------

{
  @SENT = ();
  my @dbh = map { FakeIdle::DBH->new } 1 .. 4;
  $dbh[1]->server_says('N jobs 4711 x');
  $dbh[2]->server_ends;
  close $dbh[3]{server};
  with_warnings { $T->_idle_connection_alive({ dbh => $_ }) for @dbh };

  is_deeply \@SENT, [], 'no prepare, do, ping or pg_ping -- idle, notified, ended, closed';
  is $dbh[$_]->server_received, '', "... and no byte reached server $_" for 0 .. 1;
  my @reads = map { @{ $_->{reads} } } @dbh;
  ok @reads, 'the reads that happened ...';
  ok !(grep { !$_->{nonblocking} } @reads), '... all ran with the socket in O_NONBLOCK mode';
  ok $dbh[1]{client}->blocking, '... and the socket is back in its previous (blocking) mode';
}

# ---------------------------------------------------------------------------
# 7. Through the real pool acquire.
# ---------------------------------------------------------------------------

sub fresh {
  my ($class) = @_;
  my $s = $class->new(undef);
  $s->connect_info([ 'dbi:Pg:dbname=idle_test', 'u', 'p', { pool_size => 1 } ]);
  @CONNECTS = ();
  return $s;
}

sub outcome {
  my ($f) = @_;
  die 'the fake transport is synchronous; the Future should be ready'
    unless $f->is_ready;
  return $f->is_done ? (1, $f->get) : (0, scalar $f->failure);
}

sub pool_state { [ $_[0]->pool->size, $_[0]->pool->available ] }

{
  my $s = fresh('FakeIdle::Transport');
  my ($ok, @r) = outcome($s->_query_async('SELECT 1', []));
  ok $ok, 'pool: a statement resolves';
  my $pid = $r[0][0];
  is_deeply pool_state($s), [ 1, 1 ], '... and its connection goes back idle';

  $CONNECTS[0]->server_ends;                  # killed while idle
  my $w;
  ($w, $ok, @r) = with_warnings { outcome($s->_query_async('SELECT 1', [])) };
  ok $ok, 'the next statement after an idle kill resolves' or diag "it failed: $r[0]";
  ok $ok && $r[0][0] != $pid, '... on a freshly spawned connection';
  is scalar(@CONNECTS), 2, '... opened for it';
  ok $CONNECTS[0]{disconnected}, '... the dead one closed';
  is_deeply pool_state($s), [ 1, 1 ], '... and the pool has its one connection, idle';
  ok !(grep { /pool error|liveness check failed/ } @$w),
    '... retired quietly: no pool-error report'
    or diag explain $w;
}

{
  my $s = fresh('FakeIdle::Transport');
  my ($ok, @r) = outcome($s->_query_async('SELECT 1', []));
  my $pid = $r[0][0];

  $CONNECTS[0]->server_says("N jobs 4711 x");
  ($ok, @r) = outcome($s->_query_async('SELECT 1', []));
  is $ok && $r[0][0], $pid, 'pool: a connection that got a notification is reused';
  is scalar(@CONNECTS), 1, '... no connection opened for the call';
}

{
  my $s = fresh('FakeIdle::Unchecked');
  outcome($s->_query_async('SELECT 1', []));
  $CONNECTS[0]->server_ends;
  my (undef, $ok, @r) = with_warnings { outcome($s->_query_async('SELECT 1', [])) };
  ok !$ok, 'control: without the check the statement after an idle kill fails';
  like "$r[0]", qr/server closed the connection unexpectedly|terminating connection/,
    '... on the dead connection';
}

alarm 0;
done_testing;
