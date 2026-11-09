use strict;
use warnings;
use Test::More;
use Socket qw( AF_UNIX SOCK_STREAM PF_UNSPEC );
use Errno ();
use POSIX ();
use Time::HiRes ();

# karr k63 -- the future_io transport answers the pool's borrow-time question
# _idle_connection_alive (dbio-async k28, core k241): is the server session
# behind this idle connection still there?
#
# WHY IT MATTERS. The pool cannot see a connection die while it sits idle. A
# server restart, wait_timeout, an administrator's KILL: the handle looks as it
# did, the pool hands it out, and the caller's statement fails with "server has
# gone away". k65 (_conn_error_is_fatal) then retires it, so the failure is not
# repeated -- but one caller has paid, and after a server restart one caller
# per idle connection does. This seam is asked BEFORE the connection is handed
# out, so that caller gets a fresh connection instead of an error.
#
# It is asked on EVERY borrow of an idle connection, from inside acquire. So
# the answer must cost nothing and touch nothing: no round trip (no ping, no
# statement), no wait, nothing sent, and nothing taken off the socket. What it
# reads is the handle's Active flag, the DBD's socket fd, and one select with
# a zero timeout: MySQL's protocol is request and response, so a server writes
# to an idle connection only as it ends it. Readable while idle is dead.
#
# The opposite mistake costs as much as the one being fixed: a check that
# calls a healthy connection dead turns every borrow into a reconnect, and the
# pool into no pool. So "alive" is claimed as carefully here as "dead".
#
# What this file claims:
#   1. alive: an idle connection whose server is there and has sent nothing.
#      It costs ONE select, with a zero timeout, on the read set only, and one
#      call on the handle -- the DBD's fd method. Nothing reaches the server;
#   2. dead: the server closed the connection; it sent something and closed;
#      it sent something and has not closed yet (its error packet travels
#      ahead of the close). Quietly: no throw, no warning -- a dead connection
#      is an answer, not a broken check;
#   3. nothing is consumed: what the server sent is still on the socket after
#      the question, byte for byte, however often it is asked;
#   4. a handle that is not Active is dead without looking at any socket: no
#      fd asked for, no select;
#   5. a connection without a handle, and a handle without a usable fd (undef
#      is what both DBDs answer once the client library has no socket; -1; an
#      fd number that is not open): dead, no throw, no warning;
#   6. select interrupted by a signal (EINTR) is asked again, not taken for an
#      answer either way; any other select error is dead -- never "nothing to
#      read";
#   7. it does not wait: 200 questions about a quiet connection return at once;
#   8. an fd above 1023 is answered like any other (Perl's select takes a bit
#      vector of any length; nothing here is an fd_set);
#   9. through the real pool: a healthy idle connection is REUSED -- the same
#      one, for the price of that one select; one whose server ended it is
#      retired before it is handed out, the call runs on a FRESH connection and
#      returns no error, and the pool reports nothing; after a "restart" every
#      idle connection is retired by ONE call, which still succeeds. And the
#      control: with the seam at its default (no check) the same call fails;
#  10. both DBDs under both schema components, by one implementation: each
#      connection is asked through its own DBD's fd method.
#
# WHAT IS REAL. Every connection sits on a real socketpair, so "readable",
# "closed" and "not open" are the kernel's verdicts, not a fake's. The pool
# (DBIO::Async::Pool on core's PoolBase), core's acquire and
# _idle_connection_usable, dbio-async's delegation and _query_async, and this
# dist's _idle_connection_alive / _submit_query / _collect_result run for real.
#
# THE SUBSTITUTIONS. DBI->connect hands out a fake handle of the DBD the DSN
# names, with only that DBD's methods; its "server" is the other end of the
# pair, which answers a statement by making the socket readable and is closed
# or written to by the test. And select, as the transport calls it, goes
# through a hook that records the call and can fail it with an errno, then
# hands it to the real select -- for claims 1, 4 and 6, which no socket can
# show.
#
# NOT PROVEN HERE (live only): that a real server leaves an idle connection's
# socket readable when it ends the session (KILL, wait_timeout, shutdown), on
# MySQL and on MariaDB, and that a healthy idle one -- over TLS too -- is
# never readable. t/76 shows it for KILL and wait_timeout, plain and over TLS;
# a shutdown is not shown anywhere. The POD of _idle_connection_alive says
# what was measured.

# select as DBIO::MySQL::Storage::Async calls it. Installed before that module
# is compiled; every other caller, and every other form of select, passes
# straight through.
our (@SELECTS, @SELECT_FAILS);
BEGIN {
  no warnings 'once';
  *CORE::GLOBAL::select = sub {
    return CORE::select()      if @_ == 0;
    return CORE::select($_[0]) if @_ == 1;
    if ((caller)[0] eq 'DBIO::MySQL::Storage::Async') {
      push @SELECTS, { timeout => $_[3], write => $_[1], except => $_[2] };
      if (my $errno = shift @SELECT_FAILS) {
        $! = $errno;
        return -1;
      }
    }
    return CORE::select($_[0], $_[1], $_[2], $_[3]);
  };
}

BEGIN {
  eval {
    require DBIO::MySQL::Storage::Async;
    require DBIO::MySQL::Storage::MariaDB::Async;
    1;
  } or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
  plan skip_all => 'the installed DBIO core predates PoolBase::_idle_connection_alive (core k241)'
    unless DBIO::Storage::PoolBase->can('_idle_connection_alive');
  plan skip_all => 'the installed dbio-async predates the _idle_connection_alive seam (dbio-async k28)'
    unless defined &DBIO::Async::Storage::_idle_connection_alive
        && defined &DBIO::Async::Pool::_idle_connection_alive;
}

use DBI;

# A question that waits would hang this file at its first quiet connection.
# The watchdog turns the hang into a failure.
$SIG{ALRM} = sub {
  fail 'a question about an idle connection did not return (watchdog, 120s)';
  done_testing;
  exit 1;
};
alarm 120;

# Each DBD's own names, spelled out here: the expectation must not be derived
# from the table under test.
my %API = (
  mysql => {
    fd     => 'mysql_fd',
    ready  => 'mysql_async_ready',
    result => 'mysql_async_result',
  },
  MariaDB => {
    fd     => 'mariadb_sockfd',
    ready  => 'mariadb_async_ready',
    result => 'mariadb_async_result',
  },
);

# What MySQL 8.0.24 and later send an idle session as wait_timeout ends it,
# just before the close: an ERR packet, error 4031.
my $ERR_PACKET = do {
  my $payload = "\xFF" . pack('v', 4031) . '#HY000'
    . 'The client was disconnected by the server because of inactivity.';
  substr(pack('V', length $payload), 0, 3) . "\x00" . $payload;
};

# --- the fake DBDs -----------------------------------------------------------

our @CONNECTS;
my $next_id = 100;

for my $dbd (sort keys %API) {
  my $api = $API{$dbd};
  no strict 'refs';

  *{"K63::${dbd}::DBH::new"} = sub {
    socketpair(my $client, my $server, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
      or die "socketpair: $!";
    $_->blocking(0) for $client, $server;   # the test's own reads never wait
    return bless {
      Driver => { Name => $dbd },
      Active => 1,
      id     => ++$next_id,
      client => $client,     # the connection's socket, whose fd the DBD reports
      server => $server,     # the server's end of it
      calls  => [],          # every method called on the handle, in order
    }, "K63::${dbd}::DBH";
  };

  # The connection's socket fd. undef once the client library has no socket,
  # as both DBDs answer then.
  *{"K63::${dbd}::DBH::$api->{fd}"} = sub {
    my ($self) = @_;
    push @{ $self->{calls} }, $api->{fd};
    return $self->{fd_answer} if exists $self->{fd_answer};
    return fileno $self->{client};
  };

  # The round trips. The seam must make none of them.
  for my $method (qw( ping do )) {
    *{"K63::${dbd}::DBH::$method"} = sub { push @{ $_[0]{calls} }, $method; 1 };
  }
  *{"K63::${dbd}::DBH::prepare"} = sub {
    my ($self, $sql) = @_;
    push @{ $self->{calls} }, 'prepare';
    return bless { dbh => $self, sql => $sql, NUM_OF_FIELDS => 0 }, "K63::${dbd}::STH";
  };
  *{"K63::${dbd}::DBH::err"} = sub { $_[0]{err} };
  *{"K63::${dbd}::DBH::disconnect"} = sub {
    my ($self) = @_;
    push @{ $self->{calls} }, 'disconnect';
    $self->{Active}    = 0;
    $self->{fd_answer} = undef;
    $self->{disconnected}++;
    return 1;
  };

  # A statement sent on a connection the server has closed fails as the client
  # library finds out: 2006. On a live one the result arrives, and the socket
  # turns readable -- the only time a live server writes.
  *{"K63::${dbd}::STH::execute"} = sub {
    my ($self) = @_;
    my $dbh = $self->{dbh};
    $dbh->{err} = undef;
    if ($dbh->{server_closed}) {
      $dbh->{err} = 2006;
      die "DBD::${dbd}::st execute failed: MySQL server has gone away\n";
    }
    syswrite $dbh->{server}, 'R';
    return 1;
  };
  *{"K63::${dbd}::STH::$api->{ready}"} = sub {
    my $rin = '';
    vec($rin, fileno $_[0]{dbh}{client}, 1) = 1;
    return CORE::select($rin, undef, undef, 0) > 0 ? 1 : 0;
  };
  # Collecting the result takes it off the socket: idle again, quiet again.
  *{"K63::${dbd}::STH::$api->{result}"} = sub {
    my ($self) = @_;
    my $dbh = $self->{dbh};
    unless (sysread $dbh->{client}, my $byte, 1) {
      $dbh->{err} = 2013;
      die "DBD::${dbd}::st $api->{result} failed: Lost connection to MySQL server during query\n";
    }
    $self->{NUM_OF_FIELDS} = 1 if $self->{sql} =~ /^SELECT/;
    return 1;
  };
  # Every row names the connection it ran on, like CONNECTION_ID().
  *{"K63::${dbd}::STH::fetchall_arrayref"} = sub { [ [ $_[0]{dbh}{id} ] ] };
  *{"K63::${dbd}::STH::more_results"} = sub { 0 };   # one result set (karr k73)
}

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn) = @_;
    my ($dbd) = ($dsn // '') =~ /^dbi:(\w*)/i;
    die "fake DBI: no fake for DBD::$dbd\n" unless $API{$dbd};
    my $dbh = "K63::${dbd}::DBH"->new;
    push @CONNECTS, $dbh;
    return $dbh;
  };
}

# The transport has no session reset (core ADR 0079): the pool retires its
# connection at the end of every borrow, so no connection ever sits idle. This
# file is about the check made when an idle connection is lent again, and that
# needs one that survived its last borrow. So the pool gets the reset a server
# with a session reset would give: done at once, the fake's session having
# nothing to reset. What retires a connection here is the idle check and nothing
# else.
{
  no warnings 'redefine';
  *DBIO::MySQL::Storage::Async::_reset_pool_connection = sub { Future->done };
}

{
  package K63::MySQLSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');

  package K63::MariaDBSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');
}

# --- what the server does to an idle connection ------------------------------

# It ends the session: KILL, a restart, wait_timeout.
sub server_closes {
  my ($dbh) = @_;
  close $dbh->{server};
  $dbh->{server_closed} = 1;
  return;
}

# It writes to the connection.
sub server_says {
  my ($dbh, $bytes) = @_;
  syswrite $dbh->{server}, $bytes;
  return;
}

# --- what the test looks at --------------------------------------------------

# Everything the connection's socket holds, read without waiting.
sub on_the_wire {
  my ($dbh) = @_;
  my $got = '';
  while (sysread $dbh->{client}, my $buf, 4096) { $got .= $buf }
  return $got;
}

# What reached the server from the client: the bytes, or undef for nothing.
sub reached_server {
  my ($dbh) = @_;
  my $buf;
  return sysread($dbh->{server}, $buf, 4096) ? $buf : undef;
}

# One question, and everything it did.
sub ask {
  my ($class, $conn) = @_;
  @SELECTS = ();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $answer = eval { $class->_idle_connection_alive($conn) ? 'alive' : 'dead' };
  return {
    answer   => $answer // "THREW: $@",
    warnings => \@warnings,
    selects  => [@SELECTS],
  };
}

sub is_quiet {
  my ($r, $label) = @_;
  is_deeply $r->{warnings}, [], "$label -- and no warning";
}

my @CLASSES = qw( DBIO::MySQL::Storage::Async DBIO::MySQL::Storage::MariaDB::Async );

# ---------------------------------------------------------------------------
# 1 - 8. The verdict, asked directly. Both classes, a handle of either DBD:
#        each fake has only its own DBD's fd method, so an answer at all means
#        the connection was asked through its own (karr k60).
# ---------------------------------------------------------------------------

for my $class (@CLASSES) {
  for my $dbd (sort keys %API) {
    my $api   = $API{$dbd};
    my $new   = sub { "K63::${dbd}::DBH"->new };
    my $label = "$class, DBD::$dbd";

    # -- 1. the ordinary borrow: the server is there and has nothing to say
    {
      my $dbh  = $new->();
      my $conn = { dbh => $dbh };
      my $r    = ask($class, $conn);

      is $r->{answer}, 'alive', "$label: idle, the server there, nothing sent";
      is_quiet $r, '...';
      is scalar @{ $r->{selects} }, 1, '... for the price of one select';
      my $select = $r->{selects}[0] || {};
      ok defined $select->{timeout} && $select->{timeout} == 0,
        '... with a zero timeout: it cannot wait';
      ok !defined $select->{write} && !defined $select->{except},
        '... on the read set only';
      is_deeply $dbh->{calls}, [ $api->{fd} ],
        "... and one call on the handle, $api->{fd}: no ping, no statement";
      is reached_server($dbh), undef, '... nothing reached the server';

      is ask($class, $conn)->{answer}, 'alive', '... and asked again: still alive';
    }

    # -- 2. the server ended the session and closed
    {
      my $dbh = $new->();
      server_closes($dbh);
      my $r = ask($class, { dbh => $dbh });
      is $r->{answer}, 'dead', "$label: the server closed the idle connection";
      is_quiet $r, '...';
      is_deeply $dbh->{calls}, [ $api->{fd} ], '... told from the socket alone';
    }

    # -- 2 + 3. it said why first: its error packet, then the close
    {
      my $dbh = $new->();
      server_says($dbh, $ERR_PACKET);
      server_closes($dbh);
      my $conn = { dbh => $dbh };
      my $r    = ask($class, $conn);
      is $r->{answer}, 'dead', "$label: the server sent its error packet and closed";
      is_quiet $r, '...';
      is ask($class, $conn)->{answer}, 'dead', '... and dead again when asked again';
      is on_the_wire($dbh), $ERR_PACKET,
        '... the packet is still on the socket, whole: looked at, not read';
    }

    # -- 2 + 3. the packet is there, the close has not arrived yet. An idle
    #    connection has no statement in flight, so nothing is due on it:
    #    whatever this is, it is not an answer to anything.
    {
      my $dbh = $new->();
      server_says($dbh, $ERR_PACKET);
      my $conn = { dbh => $dbh };
      my $r    = ask($class, $conn);
      is $r->{answer}, 'dead', "$label: the server wrote to the idle connection and has not closed yet";
      is_quiet $r, '...';
      is ask($class, $conn)->{answer}, 'dead', '... and dead again when asked again';
      is on_the_wire($dbh), $ERR_PACKET, '... the packet is still on the socket, whole';
      is reached_server($dbh), undef, '... and nothing was sent back';
    }

    # -- 3. one byte is enough, and one byte stays
    {
      my $dbh = $new->();
      server_says($dbh, 'x');
      is ask($class, { dbh => $dbh })->{answer}, 'dead', "$label: a single unread byte";
      is on_the_wire($dbh), 'x', '... which is still there';
    }

    # -- 4. the handle itself says it is disconnected. Nothing else is asked:
    #    both DBDs answer undef for the fd of a closed handle, and the flag is
    #    DBI's own, in memory.
    {
      my $dbh = $new->();
      $dbh->{Active} = 0;
      my $r = ask($class, { dbh => $dbh });
      is $r->{answer}, 'dead', "$label: a handle that is not Active";
      is_quiet $r, '...';
      is_deeply $r->{selects}, [], '... without a select';
      is_deeply $dbh->{calls}, [], '... and without a call on the handle';
    }

    # -- 5. no usable fd. undef is what $api->{fd} answers once the client
    #    library has no socket; none of these may reach vec or select, which
    #    warn about undef and die on a negative offset.
    for my $case (
      [ undef, 'undef' ],
      [ -1,    '-1' ],
      [ '',    'an empty string' ],
    ) {
      my ($fd, $what) = @$case;
      my $dbh = $new->();
      $dbh->{fd_answer} = $fd;
      my $r = ask($class, { dbh => $dbh });
      is $r->{answer}, 'dead', "$label: $api->{fd} answers $what";
      is_quiet $r, '...';
      is_deeply $r->{selects}, [], '... without a select';
    }

    # -- 5. an fd number that is not open: the kernel says so (EBADF)
    #    The number is taken after the handle's own sockets are open, and
    #    nothing is opened between its close and the question, so it is free.
    {
      my $dbh = $new->();
      socketpair(my $one, my $other, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
      my $closed = fileno $one;
      close $one;
      close $other;
      $dbh->{fd_answer} = $closed;
      my $r = ask($class, { dbh => $dbh });
      is $r->{answer}, 'dead', "$label: $api->{fd} answers an fd that is not open";
      is_quiet $r, '...';
    }

    # -- 6. a signal arrives during the select: EINTR says nothing about the
    #    socket. Asked again until select answers.
    {
      my $dbh = $new->();
      @SELECT_FAILS = (Errno::EINTR) x 3;
      my $r = ask($class, { dbh => $dbh });
      is $r->{answer}, 'alive', "$label: select interrupted three times, then quiet";
      is_quiet $r, '...';
      is scalar @{ $r->{selects} }, 4, '... asked again each time';
      is_deeply \@SELECT_FAILS, [], '... (every interruption was delivered)';

      server_closes($dbh);
      @SELECT_FAILS = (Errno::EINTR);
      is ask($class, { dbh => $dbh })->{answer}, 'dead',
        "$label: select interrupted, then readable -- an interruption is not 'alive' either";
      @SELECT_FAILS = ();
    }

    # -- 6. any other select error: the socket could not be looked at. That is
    #    not "nothing to read"; the transport could not wait for a result on
    #    this fd either.
    {
      my $dbh = $new->();
      @SELECT_FAILS = (Errno::ENOMEM);
      my $r = ask($class, { dbh => $dbh });
      is $r->{answer}, 'dead', "$label: select fails with ENOMEM on a healthy connection";
      is_quiet $r, '...';
      is scalar @{ $r->{selects} }, 1, '... not asked again';
      @SELECT_FAILS = ();
    }

    # -- 7. it does not wait. A select with any timeout at all would hold every
    #    borrow for that long; a quiet socket is the common case and the one a
    #    wait would sit on. (One that never returns is the watchdog's.)
    {
      my $dbh   = $new->();
      my $conn  = { dbh => $dbh };
      my $alive = 0;
      my $t0    = [Time::HiRes::gettimeofday];
      $alive += $class->_idle_connection_alive($conn) ? 1 : 0 for 1 .. 200;
      my $took = Time::HiRes::tv_interval($t0);
      is $alive, 200, "$label: 200 questions about a quiet connection, each answered alive";
      cmp_ok $took, '<', 2, '... at once (' . sprintf('%.4f', $took) . 's for all of them)';
    }

    # -- 8. an fd above 1023. A C fd_set ends there; Perl's select takes a bit
    #    vector as long as the fd needs.
    SKIP: {
      my $dbh  = $new->();
      my $high = 1500;
      skip "fd $high cannot be opened here: $!", 3
        unless defined POSIX::dup2(fileno $dbh->{client}, $high);
      $dbh->{fd_answer} = $high;
      my $r = ask($class, { dbh => $dbh });
      is $r->{answer}, 'alive', "$label: a quiet connection on fd $high";
      is_quiet $r, '...';
      server_says($dbh, 'x');
      is ask($class, { dbh => $dbh })->{answer}, 'dead', '... and dead once the server wrote to it';
      POSIX::close($high);
    }
  }

  # -- 5. no handle, no connection: nothing to send a statement on
  for my $case (
    [ {},               'a connection without a handle' ],
    [ { dbh => undef }, 'a connection whose handle is undef' ],
    [ undef,            'no connection at all' ],
    [ 'conn',           'a connection that is not a hashref' ],
  ) {
    my ($conn, $what) = @$case;
    my $r = ask($class, $conn);
    is $r->{answer}, 'dead', "$class: $what";
    is_quiet $r, '...';
    is_deeply $r->{selects}, [], '... without a select';
  }
}

# ---------------------------------------------------------------------------
# 9. Through the real pool, for every schema component over every DBD (karr
#    k60: the component pins the transport class for every DSN, so each class
#    meets each DBD).
# ---------------------------------------------------------------------------

# A future_io backend. The schema is kept: the backend holds its owning sync
# storage weakly.
my @schemas;
sub backend {
  my ($schema_class, $dbd, $pool_size) = @_;
  my $schema = $schema_class->connect(
    "dbi:$dbd:database=t", 'u', 'p', { async => 'future_io', pool_size => $pool_size },
  );
  push @schemas, $schema;
  my $async = $schema->storage->async;
  @CONNECTS = ();
  return $async;
}

# (1, results...) or (0, error) of a Future, waited for. The fake's result is
# on the socket as soon as its statement is sent, so the wait is one turn of
# Future::IO's built-in poll.
sub outcome {
  my ($f) = @_;
  $f->await;
  return $f->is_done ? (1, $f->get) : (0, scalar $f->failure);
}

# The id of the connection a statement ran on, or a diagnosis.
sub ran_on {
  my ($ok, @r) = outcome($_[0]);
  return $ok ? $r[0][0] : "FAILED: $r[0]";
}

sub pool_state {
  my ($async) = @_;
  return [ $async->pool->size, $async->pool->available ];
}

sub statements_on { scalar grep { $_ eq 'prepare' } @{ $_[0]{calls} } }

# The ways a server ends an idle session, as the socket shows them.
my @DEATHS = (
  [ 'closed it (KILL, a restart)',
    sub { server_closes($_[0]) } ],
  [ 'sent its error packet and closed it (wait_timeout on MySQL 8.0.24+)',
    sub { server_says($_[0], $ERR_PACKET); server_closes($_[0]) } ],
);

for my $combo (
  [ 'K63::MySQLSchema',   'mysql'   ],
  [ 'K63::MySQLSchema',   'MariaDB' ],
  [ 'K63::MariaDBSchema', 'MariaDB' ],
  [ 'K63::MariaDBSchema', 'mysql'   ],
) {
  my ($schema_class, $dbd) = @$combo;
  my $label = "$schema_class + dbi:$dbd:";

  # -- a healthy idle connection is reused. The reason a pool exists: a check
  #    that called it dead would open a connection per statement.
  {
    my $async = backend($schema_class, $dbd, 1);
    my $first = ran_on($async->_query_async('SELECT 1', []));
    like $first, qr/^\d+$/, "$label: a pooled statement runs";

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    @SELECTS = ();
    my $second = ran_on($async->_query_async('SELECT 1', []));
    is $second, $first, "$label: the next call runs on the SAME connection";
    is scalar(@CONNECTS), 1, '... no connection was opened for it';
    is scalar(@SELECTS), 1, '... and the pool asked about it on the way out: one select';
    ok !$CONNECTS[0]{disconnected}, '... which left it open';
    is ran_on($async->_query_async('SELECT 1', [])), $first, '... and a third call reuses it too';
    is_deeply \@warnings, [], '... nothing warned';
  }

  # -- the server ended the idle session: the caller gets a fresh connection
  #    instead of the error
  for my $death (@DEATHS) {
    my ($how, $die) = @$death;
    my $async = backend($schema_class, $dbd, 1);
    my $first = ran_on($async->_query_async('SELECT 1', []));
    $die->($CONNECTS[0]);

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my ($ok, @r) = outcome($async->_query_async('SELECT 1', []));
    ok $ok, "$label: the server $how -- the next call returns NO error"
      or diag $r[0];
    my $next = $ok ? $r[0][0] : 'none';
    like $next, qr/^\d+$/, '... it ran';
    isnt $next, $first, '... on a FRESH connection';
    is scalar(@CONNECTS), 2, '... opened for it';
    is $CONNECTS[0]{disconnected}, 1, '... the dead one was closed, once';
    is statements_on($CONNECTS[0]), 1, '... and no statement was sent on it after it died';
    is_deeply pool_state($async), [ 1, 1 ], '... the pool holds the fresh one, idle again';
    is_deeply \@warnings, [],
      '... and reports nothing: a dead connection is an answer, not a failed check';

    is ran_on($async->_query_async('SELECT 1', [])), $next,
      "$label: the call after that reuses the fresh connection";
  }

  # -- the control: this is the seam's doing. At the default answer -- true,
  #    without looking -- the same death reaches the caller, as it did before
  #    k63 (k65 then retires the connection, so the call after it succeeds).
  {
    my $async = backend($schema_class, $dbd, 1);
    my $first = ran_on($async->_query_async('SELECT 1', []));
    server_closes($CONNECTS[0]);

    no warnings 'redefine';
    local *DBIO::MySQL::Storage::Async::_idle_connection_alive = sub { 1 };
    my ($ok, $error) = outcome($async->_query_async('SELECT 1', []));
    ok !$ok, "$label: control, no check -- the same call FAILS";
    like "$error", qr/server has gone away/, '... with the dead connection\'s error';
    is statements_on($CONNECTS[0]), 2, '... its statement went out on the dead connection';
  }

  # -- a server restart: every idle connection is dead at once. Without the
  #    seam each is handed out and fails once -- one failed call per idle
  #    connection. With it, one call retires them all and still succeeds.
  {
    my $async = backend($schema_class, $dbd, 3);
    my @held  = map { $async->pool->acquire->get } 1 .. 3;
    $async->pool->release($_) for @held;
    is_deeply pool_state($async), [ 3, 3 ], "$label: three idle connections";
    server_closes($_) for @CONNECTS;

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my ($ok, @r) = outcome($async->_query_async('SELECT 1', []));
    ok $ok, "$label: after a restart the next call returns NO error" or diag $r[0];
    is scalar(@CONNECTS), 4, '... on a fresh connection';
    is_deeply [ map { $_->{disconnected} } @CONNECTS[ 0 .. 2 ] ], [ 1, 1, 1 ],
      '... and all three dead ones are retired by that one call';
    is_deeply [ map { statements_on($_) } @CONNECTS[ 0 .. 2 ] ], [ 0, 0, 0 ],
      '... none of them was sent a statement';
    is_deeply pool_state($async), [ 1, 1 ], '... the pool holds the fresh one';
    is_deeply \@warnings, [], '... and reports nothing';
  }
}

# ---------------------------------------------------------------------------
# 10. One implementation. The MariaDB convention class answers with the base's
#     method -- a class cannot know which DBD its connections run on (karr
#     k60) -- and it is this dist's answer, not dbio-async's default "alive
#     without looking".
# ---------------------------------------------------------------------------
{
  my $ours    = DBIO::MySQL::Storage::Async->can('_idle_connection_alive');
  my $mariadb = DBIO::MySQL::Storage::MariaDB::Async->can('_idle_connection_alive');
  my $default = DBIO::Async::Storage->can('_idle_connection_alive');
  ok $ours && $default && $ours != $default,
    'the transport fills the seam -- it is not the default of DBIO::Async::Storage';
  ok $mariadb && $ours && $mariadb == $ours,
    'the MariaDB convention class resolves to the same method -- no class decides the DBD';
}

alarm 0;
done_testing;
