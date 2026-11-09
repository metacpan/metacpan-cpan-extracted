use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k92: the future_io transport answers dbio-async's
# driver seam _conn_error_is_fatal (dbio-async k26), and a connection a failed
# statement left dead is retired through it -- by the base's query path, not
# by anything of this transport's own.
#
# WHY: the pool cannot see a connection die (core k230). Until k92 this
# transport reported a dead connection itself, from eval wrappers around every
# DBD::Pg call in _submit_query and _collect_result (karr k79). dbio-async k26
# moved the asking into _query_async / _query_async_pinned, which every query
# of this transport goes through, so the transport now only answers. If the
# answer is wrong, the pool either hands a dead handle to the next caller
# (answer "alive" for a lost connection) or throws healthy connections away on
# every statement error (answer "dead" for one the session survives).
#
# What this file claims:
#   1. the verdict: dead for a handle whose libpq socket is gone (pg_socket
#      -1), for a connection without a handle, and for one whose pg_socket is
#      unknown; alive for an open socket -- whatever the error says: the
#      message is not read, the same text gets both answers;
#   2. the base asks it once for every failed query -- a die in _submit_query
#      (before the Future had a chance to exist), a die of pg_result, and the
#      57014 cancellation _collect_result fails itself -- with the connection
#      and the query's error, and never for a query that succeeded;
#   3. through the real _query_async: a statement that loses its connection
#      fails with DBD::Pg's error, the connection is retired, and the next call
#      runs on a freshly spawned one; a division by zero and a cancellation
#      fail too, but the connection goes back idle and the next call reuses it;
#   4. through the real _query_async_pinned (a transaction's connection): the
#      lost connection is reported, so its one hand-back retires it.
#
# t/64-future-io-pool.t pins the same retire-or-keep behaviour end to end
# through select_async and txn_do_async; this file pins the seam itself and
# that the base is the one asking. WHAT RUNS FOR REAL: the pool
# (DBIO::Async::Pool on core's PoolBase), dbio-async's _query_async /
# _query_async_pinned / _mark_dead_on_fail, and this dist's _submit_query /
# _collect_result / _conn_error_is_fatal. THE SUBSTITUTIONS: DBI->connect hands
# out fake DBD::Pg handles, _await_readable resolves at once, and the
# borrow-time check _idle_connection_alive answers its default (t/75).

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
  plan skip_all => 'the installed DBIO core predates PoolBase::_mark_connection_dead (core k230)'
    unless DBIO::Storage::PoolBase->can('_mark_connection_dead');
  plan skip_all => 'the installed dbio-async predates the _conn_error_is_fatal seam (dbio-async k26)'
    unless DBIO::Async::Storage->can('_conn_error_is_fatal');
}

use Future;

# --- the fake DBD::Pg -----------------------------------------------------------

our @CONNECTS;
my $next_pid = 9000;

{
  package FakeFatal::DBH;

  sub new {
    return bless {
      Active    => 1,
      pg_socket => 42,
      pg_pid    => ++$next_pid,
      sqlstate  => '',
    }, shift;
  }

  sub prepare {
    my ($self, $sql) = @_;
    return bless { dbh => $self, sql => $sql }, 'FakeFatal::STH';
  }

  # libpq concluded the connection is gone: it drops the socket. DBD::Pg
  # leaves Active alone.
  sub lose { $_[0]{pg_socket} = -1; return }

  sub pg_ready { 1 }

  # As measured on PostgreSQL 18.6 / DBD::Pg 3.20.2: the state is set from
  # the result read; a terminated backend and a division by zero die, a
  # cancellation returns 0E0 and leaves only 57014.
  sub pg_result {
    my ($self) = @_;
    my $sth = delete $self->{in_flight} or die "no async query is running\n";
    my $sql = $sth->{sql};
    if ($sql =~ /terminate_me/) {
      $self->lose;
      $self->{sqlstate} = '08000';
      die "DBD::Pg::db pg_result failed: FATAL:  terminating connection due to "
        . "administrator command\n";
    }
    if ($sql =~ m{1/0}) {
      $self->{sqlstate} = '22012';
      die "DBD::Pg::db pg_result failed: ERROR:  division by zero\n";
    }
    if ($sql =~ /pg_sleep/) {
      $self->{sqlstate} = '57014';
      $sth->{NUM_OF_FIELDS} = undef;
      return '0E0';
    }
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
}

{
  package FakeFatal::STH;

  # A handle whose socket is gone refuses at once, as DBD::Pg does.
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
    my $dbh = FakeFatal::DBH->new;
    push @CONNECTS, $dbh;
    return $dbh;
  };
}

{
  package FakeFatal::Transport;
  use base 'DBIO::PostgreSQL::Storage::Async';

  our @ASKED;

  sub _await_readable { Future->done }

  # The borrow-time check _idle_connection_alive (karr k90) is held at the
  # seam's default here: this file pins the statement path, the net that still
  # catches a death the check cannot see -- one after the check, or one the
  # server never announced on the socket. The fake's pg_socket is no real fd
  # to select on; t/75 pins the check itself, over real sockets.
  sub _idle_connection_alive { 1 }

  # Record every question the base asks, and the answer the transport gives.
  sub _conn_error_is_fatal {
    my ($self, $conn, $error) = @_;
    my $answer = $self->next::method($conn, $error);
    push @ASKED, { conn => $conn, error => $error, answer => $answer };
    return $answer;
  }
}

# --- helpers --------------------------------------------------------------------

sub fresh {
  my $s = FakeFatal::Transport->new(undef);
  $s->connect_info([ 'dbi:Pg:dbname=fatal_test', 'u', 'p', { pool_size => 1 } ]);
  @CONNECTS = ();
  @FakeFatal::Transport::ASKED = ();
  return $s;
}

sub outcome {
  my ($f) = @_;
  die 'the fake transport is synchronous; the Future should be ready'
    unless $f->is_ready;
  return $f->is_done ? (1, $f->get) : (0, scalar $f->failure);
}

sub pool_state {
  my ($s) = @_;
  return [ $s->pool->size, $s->pool->available ];
}

my $T = 'DBIO::PostgreSQL::Storage::Async';

# ---------------------------------------------------------------------------
# 1. The verdict. The same error text is given to a dead and a live handle:
#    only the socket decides.
# ---------------------------------------------------------------------------

{
  my $error = "DBD::Pg::db pg_result failed: FATAL:  terminating connection\n";
  my $live  = FakeFatal::DBH->new;
  my $gone  = FakeFatal::DBH->new;
  $gone->lose;
  my $unknown = FakeFatal::DBH->new;
  delete $unknown->{pg_socket};

  ok $T->_conn_error_is_fatal({ dbh => $gone }, $error),
    'pg_socket -1 (libpq gave up the connection): dead';
  ok $T->_conn_error_is_fatal({}, $error),
    'a connection without a handle: dead';
  ok $T->_conn_error_is_fatal({ dbh => $unknown }, $error),
    'a handle with no pg_socket at all: dead -- there is no socket to poll';
  ok !$T->_conn_error_is_fatal({ dbh => $live }, $error),
    'an open socket: alive, although the error text says FATAL';
  ok !$T->_conn_error_is_fatal({ dbh => $live }, "ERROR:  division by zero\n"),
    '... and alive for a statement error';
  $live->{Active} = 0;
  ok !$T->_conn_error_is_fatal({ dbh => $live }, $error),
    '{Active} is not read: DBD::Pg leaves it true on a lost connection, so the '
    . 'socket is the only verdict';
}

# ---------------------------------------------------------------------------
# 2 + 3. Through the real _query_async: who asks, and what the pool does.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my ($ok, @r) = outcome($s->_query_async('SELECT 1', []));
  ok $ok, 'a pooled statement resolves';
  my $pid = $r[0][0];
  is scalar(@FakeFatal::Transport::ASKED), 0, '... and the seam is not asked about it';

  ($ok, @r) = outcome($s->_query_async('SELECT terminate_me()', []));
  ok !$ok, 'a statement whose backend is terminated fails';
  like "$r[0]", qr/terminating connection/, '... with DBD::Pg\'s error';
  is scalar(@FakeFatal::Transport::ASKED), 1, '... the base asked the seam once';
  my ($asked) = @FakeFatal::Transport::ASKED;
  is $asked->{conn}{dbh}, $CONNECTS[0], '... about the connection the statement ran on';
  like $asked->{error}, qr/terminating connection/, '... with the query\'s error';
  ok $asked->{answer}, '... which the transport answered dead';
  is_deeply pool_state($s), [ 0, 0 ], 'the connection was retired on its way back';
  ok $CONNECTS[0]{disconnected}, '... and closed';

  ($ok, @r) = outcome($s->_query_async('SELECT 1', []));
  ok $ok, 'the next statement resolves' or diag "it failed: $r[0]";
  ok $ok && $r[0][0] != $pid, '... on a freshly spawned connection';
  is scalar(@CONNECTS), 2, '... opened for it';
}

{
  # The dead handle is handed to _submit_query: execute dies there, before the
  # dispatch returned a Future. The base's eval / Future->call turns it into a
  # failed Future, and the seam is asked about it all the same.
  my $s = fresh();
  my ($ok, @r) = outcome($s->_query_async('SELECT 1', []));
  my $pid = $r[0][0];
  $CONNECTS[0]->lose;                     # died while idle, past the k90 check

  my $f = eval { $s->_query_async('SELECT 1', []) };
  ok $f, 'a die in _submit_query does not escape _query_async' or diag $@;
  ($ok, @r) = outcome($f);
  ok !$ok, '... the call fails';
  like "$r[0]", qr/no connection to the server/, '... with execute\'s error';
  is scalar(@FakeFatal::Transport::ASKED), 1, '... the seam was asked';
  ok $FakeFatal::Transport::ASKED[0]{answer}, '... and answered dead';
  is_deeply pool_state($s), [ 0, 0 ], '... so the connection was retired';

  ($ok, @r) = outcome($s->_query_async('SELECT 1', []));
  ok $ok && $r[0][0] != $pid, 'the next statement runs on a freshly spawned connection';
}

for my $case (
  [ 'division by zero', 'SELECT 1/0',         qr/division by zero/ ],
  [ 'cancellation',     'SELECT pg_sleep(1)', qr/SQLSTATE 57014 query_canceled/ ],
) {
  my ($label, $sql, $error_re) = @$case;
  my $s = fresh();
  my ($ok, @r) = outcome($s->_query_async('SELECT 1', []));
  my $pid = $r[0][0];

  ($ok, @r) = outcome($s->_query_async($sql, []));
  ok !$ok, "$label: the statement fails";
  like "$r[0]", $error_re, "$label: with its own error";
  is scalar(@FakeFatal::Transport::ASKED), 1, "$label: the seam was asked";
  ok !$FakeFatal::Transport::ASKED[0]{answer}, "$label: and answered alive";
  is_deeply pool_state($s), [ 1, 1 ], "$label: the connection is back in the pool, idle";

  ($ok, @r) = outcome($s->_query_async('SELECT 1', []));
  is $ok && $r[0][0], $pid, "$label: the next statement runs on the SAME connection";
  is scalar(@CONNECTS), 1, "$label: no connection was opened for it";
}

# ---------------------------------------------------------------------------
# 4. A pinned connection: reported on failure, retired on its hand-back.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my $conn = $s->pool->acquire->get;

  my ($ok, @r) = outcome($s->_query_async_pinned($conn, 'SELECT terminate_me()', []));
  ok !$ok, 'pinned: the statement whose backend is terminated fails';
  is scalar(@FakeFatal::Transport::ASKED), 1, '... the seam was asked';
  ok $FakeFatal::Transport::ASKED[0]{answer}, '... and answered dead';
  is_deeply pool_state($s), [ 1, 0 ], '... the connection is still out with its holder';

  $s->pool->release($conn);
  is_deeply pool_state($s), [ 0, 0 ], 'its hand-back retires it instead of idling it';
}

done_testing;
