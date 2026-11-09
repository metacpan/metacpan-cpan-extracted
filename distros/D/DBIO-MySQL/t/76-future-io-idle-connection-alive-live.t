use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use Scalar::Util ();
use Socket qw( MSG_PEEK MSG_DONTWAIT );

# LIVE proof of karr k63: a pool connection whose session the server ended
# while it sat idle is not handed out -- the next call runs on a fresh one and
# returns no error -- and a healthy idle connection is handed out again.
#
# WHY IT MATTERS. The borrow-time check _idle_connection_alive takes "the idle
# socket is readable" for "the session is over": MySQL's protocol is request
# and response, so a server writes to an idle connection only as it ends it.
# t/69 pins the check offline, on socketpairs whose other end the test plays.
# What only a server can show is the premise on both sides:
#
#   - that a real server, ending an idle session, does leave the socket
#     readable -- or the check would never catch anything;
#   - that a healthy idle connection's socket stays quiet -- or the check
#     would retire every connection on every borrow and the pool would be no
#     pool. TLS is where that could break: under TLS 1.3 a server may send
#     records that carry no MySQL data after the handshake (session tickets),
#     and a readable socket is all the check looks at.
#
# What this file claims, on a pool of one, once over a plain connection and
# once over TLS where the server offers it and the DBD can be made to use it:
#   1. healthy: an idle socket is quiet, and three calls with idle time in
#      between run on the SAME session -- the check was asked at each borrow
#      and answered alive;
#   2. KILL from another session: the server ends the idle session, the socket
#      turns readable, and the next call returns NO error, on another session.
#      The check answered dead, the pool retired the handle, no statement
#      failed on the way (_conn_error_is_fatal, which retires a connection
#      after a failed statement, is never asked), and nothing was warned;
#   3. wait_timeout: the same when the server ends the session by itself.
#
# NO BLIND WAITING. Between the KILL and the next call the test does not
# sleep: it waits, bounded, for the two things the claim rests on and asserts
# each -- the server no longer lists the session, and the client's socket is
# readable (one select on the DBD's fd, by the test, which reads nothing). A
# server that ended a session without the socket turning readable would fail
# there, by name, and not as a flaky "the next call failed". Until the close
# has reached the client no check could know; that window is not this file's
# subject (_conn_error_is_fatal covers it, t/77).
#
# What the server sent ahead of the close is noted, not asserted: the check
# does not care (readable is dead), but k65 does.
#
# Runs through whichever DBD the DSN names. Gated like the other live tests:
# needs DBIO_TEST_MYSQL_DSN, _USER and _PASS. Creates nothing on the server;
# the sessions it kills are its own pool's.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    1;
  } or plan skip_all =>
    'Future::IO::Impl::IOAsync + IO::Async required for the live future_io roundtrip';
}

use DBI;
use DBIO::Test;

eval { require DBIO::MySQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
plan skip_all => 'the installed DBIO core predates PoolBase::_idle_connection_alive (core k241)'
  unless DBIO::Storage::PoolBase->can('_idle_connection_alive');
plan skip_all => 'the installed dbio-async predates the _idle_connection_alive seam (dbio-async k28)'
  unless DBIO::Async::Storage->can('_idle_connection_alive');

# The transport has no session reset (core ADR 0079): the pool retires its
# connection at the end of every borrow, so none sits idle and the check made
# when an idle connection is lent again never runs. This file asks what a real
# server does to an idle socket, which needs an idle connection. So the pool gets
# the reset a server with a session reset would give, done at once: the
# statements of this file set no session state. The server and the DBD stay real.
{
  no warnings 'redefine';
  *DBIO::MySQL::Storage::Async::_reset_pool_connection = sub { Future->done };
}

# Each DBD's own names, spelled out here: the expectation must not be derived
# from the table under test.
my %API = (
  mysql   => { fd => 'mysql_fd',       ssl => 'mysql_ssl',   ssl_optional => 'mysql_ssl_optional' },
  MariaDB => { fd => 'mariadb_sockfd', ssl => 'mariadb_ssl', ssl_optional => 'mariadb_ssl_optional' },
);
my ($dbd) = $dsn =~ /\Adbi:(\w+):/;
plan skip_all => 'DBIO_TEST_MYSQL_DSN names neither dbi:mysql: nor dbi:MariaDB:'
  unless defined $dbd && $API{$dbd};
my $api = $API{$dbd};

# A schema always declares its driver (core ADR 0067), and DBIO::Test::Schema
# keeps none in its class: declare the storage class the DSN's DBD is
# registered for -- DBIO::MySQL::Storage::MariaDB for a dbi:MariaDB: DSN.
my $test_schema = DBIO::Test::Schema->clone;
$test_schema->storage_type(
  $dsn =~ /\Adbi:MariaDB:/i ? '+DBIO::MySQL::Storage::MariaDB' : '+DBIO::MySQL::Storage'
);

my $loop = IO::Async::Loop->new;

sub wait_until {
  my ($cond, $timeout) = @_;
  my $deadline = Time::HiRes::time() + ($timeout // 10);
  until ($cond->()) {
    return 0 if Time::HiRes::time() > $deadline;
    $loop->loop_once(0.05);
  }
  return 1;
}

sub idle_for {
  my ($seconds) = @_;
  my $deadline = Time::HiRes::time() + $seconds;
  $loop->loop_once(0.05) while Time::HiRes::time() < $deadline;
  return;
}

# Is there something to read on $fd within $timeout seconds? One select, which
# reads nothing.
sub socket_readable {
  my ($fd, $timeout) = @_;
  my $rin = '';
  vec($rin, $fd, 1) = 1;
  my $found;
  do { $found = select(my $rout = $rin, undef, undef, $timeout) }
    while $found < 0 && $!{EINTR};
  return $found;
}

# What is waiting on $fd, without taking it off the socket: for the note.
sub socket_peek {
  my ($fd) = @_;
  open my $fh, '<&', $fd or return "cannot dup the fd: $!";
  my $buf = '';
  defined recv($fh, $buf, 4096, MSG_PEEK | MSG_DONTWAIT) or return "recv failed: $!";
  return 'nothing, only the close' unless length $buf;
  return sprintf 'error packet %d (%s), then the close', unpack('v', substr $buf, 5, 2), substr($buf, 13)
    if length $buf >= 13 && ord(substr $buf, 4, 1) == 0xFF;
  return length($buf) . ' bytes';
}

# The other session: it kills, and it is asked what the server still lists.
my $killer = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
my $version = $killer->selectrow_array('SELECT VERSION()');
note "server $version, DBD::$dbd " . "DBD::$dbd"->VERSION;

sub session_gone {
  my ($id) = @_;
  return !$killer->selectrow_array(
    'SELECT 1 FROM information_schema.PROCESSLIST WHERE ID = ?', undef, $id,
  );
}

# What the two seams were asked and answered. The wrappers only watch: each
# calls the method it wraps, so a transport whose check is wrong fails here.
my (@alive, @fatal);
{
  my $alive = \&DBIO::MySQL::Storage::Async::_idle_connection_alive;
  my $fatal = \&DBIO::MySQL::Storage::Async::_conn_error_is_fatal;
  no warnings 'redefine';
  *DBIO::MySQL::Storage::Async::_idle_connection_alive = sub {
    my $answer = $alive->(@_) ? 1 : 0;
    push @alive, $answer;
    return $answer;
  };
  *DBIO::MySQL::Storage::Async::_conn_error_is_fatal = sub {
    push @fatal, $_[2] // 'no message';
    return $fatal->(@_);
  };
}

sub session_id { my @rows = $_[0]->_query_async('SELECT CONNECTION_ID()', [])->get; $rows[0][0] }
sub pool_connections { grep { defined } @{ $_[0]->pool->{_connections} } }

# The server is ending $conn's session $id: assert that it does and that this
# reaches the socket within $timeout seconds, then that the next call does not
# notice. Returns the session that call ran on.
sub next_call_is_fresh {
  my ($label, $async, $conn, $id, $timeout, $warnings) = @_;
  my $fd = $conn->{dbh}->${\ $api->{fd} };

  is socket_readable($fd, $timeout), 1, "$label: the idle socket turns readable"
    or die "the socket stayed quiet -- the check has nothing to see\n";
  note "$label: the server sent " . socket_peek($fd) if $label =~ /^plain/;
  ok wait_until(sub { session_gone($id) }, 5), '... and the server no longer lists the session';

  @alive = @fatal = @$warnings = ();
  my $next = eval { session_id($async) };
  is $@, '', "$label: the next call returns no error";
  ok defined $next && $next != $id, '... on another session'
    or diag 'session ' . ($next // 'none') . " after $id";
  is_deeply \@alive, [0], '... because the borrow-time check answered dead for the ended one';
  is_deeply \@fatal, [], '... and no statement failed on the way';
  ok !$conn->{dbh}{Active}, '... the ended connection\'s handle was retired';
  my @conns = pool_connections($async);
  ok @conns == 1 && $conns[0] != $conn, '... and the pool holds one connection, a new one';
  is_deeply $warnings, [], '... quietly';
  return $next;
}

sub scenario {
  my ($label, $attrs, $want_tls) = @_;

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  my $schema = $test_schema->connect(
    $dsn, $user, $pass, { async => 'future_io', pool_size => 1, %$attrs },
  );
  my $async = $schema->storage->async;

  my $done = eval {
    @alive = ();
    my $id = session_id($async);
    my ($conn) = pool_connections($async);
    if ($want_tls) {
      # The first borrow after the handshake: where a TLS 1.3 session ticket
      # read too late would show. Counted with the rest below.
      my @status = $async->_query_async(q{SHOW SESSION STATUS LIKE 'Ssl_version'}, [])->get;
      like $status[0][1], qr/\ATLS/, "$label: the pool session is encrypted ($status[0][1])"
        or die "not a TLS session -- nothing below would be about TLS\n";
      $label = $status[0][1];
    }

    # -- 1. healthy
    my $fd = $conn->{dbh}->${\ $api->{fd} };
    my @ids;
    for (1 .. 3) {
      idle_for(0.2);
      is socket_readable($fd, 0), 0, "$label: a healthy idle socket is quiet";
      push @ids, session_id($async);
    }
    is_deeply \@ids, [ ($id) x 3 ], "$label: three calls with idle time between run on the same session";
    is_deeply \@alive, [ (1) x ($want_tls ? 4 : 3) ],
      '... the borrow-time check asked at every borrow since the connect, and answering alive';
    my @conns = pool_connections($async);
    ok @conns == 1 && $conns[0] == $conn, '... on the one pool connection';
    is_deeply \@warnings, [], '... quietly';

    # -- 2. KILL from another session
    $killer->do('KILL ' . int $id);
    $id = next_call_is_fresh("$label, KILL", $async, $conn, $id, 5, \@warnings);
    # Had that call failed, the next one says whether the pool recovered at
    # all; the wait_timeout case is shown either way.
    $id //= session_id($async);

    # -- 3. wait_timeout. Set on the pool's one session, which the call after
    #       confirms; from then on it sits idle.
    $async->_query_async('SET SESSION wait_timeout = 1', [])->get;
    is session_id($async), $id, "$label, wait_timeout: set on the pool's session";
    ($conn) = pool_connections($async);
    next_call_is_fresh("$label, wait_timeout", $async, $conn, $id, 10, \@warnings);
    1;
  };
  ok $done, "$label: ran to its end" or diag $@;

  eval { $async->disconnect };
  return;
}

scenario('plain', {}, 0);

# TLS, where it can be had. Asked for without verification of the server's
# certificate: a test server's is self-signed, and what matters here is the
# record layer, which the pool session's own Ssl_version confirms.
SKIP: {
  my %tls = ( $api->{ssl} => 1, $api->{ssl_optional} => 1 );
  my $probe = eval { DBI->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0, %tls }) };
  my $tls_version = $probe && ($probe->selectrow_array(q{SHOW SESSION STATUS LIKE 'Ssl_version'}))[1];
  $probe->disconnect if $probe;
  skip "no TLS session to be had from this server through DBD::$dbd -- the TLS half is not shown", 1
    unless $tls_version;
  scenario('TLS', \%tls, 1);
}

$killer->disconnect;

done_testing;
