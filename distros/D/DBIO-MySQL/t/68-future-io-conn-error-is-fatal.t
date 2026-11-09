use strict;
use warnings;
use Test::More;
use Socket qw( AF_UNIX SOCK_STREAM PF_UNSPEC );

# karr k65 -- the future_io transport answers dbio-async's driver seam
# _conn_error_is_fatal (dbio-async k26, core k230): did the statement that just
# failed take its connection with it?
#
# WHY IT MATTERS. The pool cannot see a connection die. Until this seam was
# filled it answered its default, false, for every failure: a connection whose
# server session was gone -- a server restart, an idle timeout, an
# administrator's KILL, a network drop -- went back on the idle list, and the
# next caller was handed it and failed the same way, and the one after that.
# The opposite mistake costs as much: answering "dead" for an error the session
# survives throws a healthy connection away on every duplicate key, and inside
# a transaction it makes the base refuse every statement queued behind the
# failed one. That is why the answer is a LIST of error numbers and not "any
# error": a statement error leaves the session where it was.
#
# The answer is read from the handle's error number, $dbh->err -- the number
# the client library reported for the failure -- and from nothing else: no
# ping, no round trip (the seam runs in the failure path of a query, inside the
# event loop), and not the error text, which carries no number and differs
# between the client libraries.
#
# What this file claims:
#   1. the verdict: dead for 2006, 2013, 2026 and 2055, alive for an ordinary
#      statement error and for a failure the DBD did not report; dead for a
#      connection that holds no handle; the text is not read; no throw;
#   2. the number is where the seam reads it: with a REAL DBI handle, an error
#      raised on the statement handle is on the database handle, and stays
#      there until the next DBI method call on that connection;
#   3. through the real _query_async and the real pool: a statement that fails
#      with one of those is retired before its release, and the next call
#      runs on a FRESH connection; one that fails with a statement error goes
#      back idle, and the next call runs on the SAME connection;
#   4. the same for a connection that died while it sat idle, whose next
#      statement fails when it is sent rather than when it is collected;
#   5. a pinned connection: reported on failure, retired by its one hand-back
#      -- directly, and as the connection of a txn_do_async;
#   6. the dedicated listen connection, which the pool does not hold: a dead
#      answer changes nothing and warns about nothing;
#   7. both DBDs under both schema components, by ONE implementation: the
#      MariaDB convention class has none of its own.
#
# FULLY OFFLINE. The one substitution is the DBD: DBI->connect hands out a fake
# handle of the DBD the DSN names. Each fake has only its own DBD's methods,
# and keeps its error number the way DBI does: every method call resets it,
# reading an attribute or the number itself does not. So a transport that
# called anything on the handle between the failure and the question would
# find the number gone here, as it would on a real handle. The socket is one
# end of a real socketpair, readable exactly while a result is waiting on it:
# the fake's server writes when a statement is sent, and collecting the result
# reads that off. So Future::IO's poll settles at once without an event loop,
# and an idle connection is quiet, as a real one is -- which the borrow-time
# check _idle_connection_alive (karr k63, t/69) reads on every borrow. Until
# k63 the fd was a temp file's, always readable; with the check in place that
# reads as "the server wrote to an idle connection", and every connection this
# file expects to be reused was retired instead. Schema component, storage,
# async resolution, the pool (DBIO::Async::Pool on core's PoolBase),
# dbio-async's _query_async / _query_async_pinned / _mark_dead_on_fail, core's
# txn_do_async and this dist's _submit_query / _collect_result /
# _conn_error_is_fatal / _idle_connection_alive run for real.
#
# NOT PROVEN HERE (live only): which number a real server and a real client
# library produce for which death. t/77 measures it for a KILL on a borrowed
# connection, a connection killed while idle and wait_timeout, plain and over
# TLS -- which is where 2026 on the list comes from -- and the POD of
# _conn_error_is_fatal has the table. A server shutdown (1053, 1927) is not
# measured anywhere.

BEGIN {
  eval {
    require DBIO::MySQL::Storage::Async;
    require DBIO::MySQL::Storage::MariaDB::Async;
    1;
  } or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
  plan skip_all => 'the installed DBIO core predates PoolBase::_mark_connection_dead (core k230)'
    unless DBIO::Storage::PoolBase->can('_mark_connection_dead');
  plan skip_all => 'the installed dbio-async predates the _conn_error_is_fatal seam (dbio-async k26)'
    unless DBIO::Async::Storage->can('_conn_error_is_fatal');
}

use DBI;
use DBIO::MySQL::Util ();

# The real DBI->connect, for section 2; everything else gets the fake below.
my $real_connect = \&DBI::connect;

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

# What each error is, spelled out here for the same reason: its message, and
# whether the connection is gone afterwards. The first four are the client
# library's own numbers for a lost connection (errmsg.h: CR_SERVER_GONE_ERROR,
# CR_SERVER_LOST, CR_SERVER_LOST_EXTENDED, CR_SSL_CONNECTION_ERROR -- the last
# is what the same loss arrives as over TLS, measured live in t/77). The rest
# are server errors for one statement; the session that got them runs the next
# statement as if nothing had happened.
my %ERROR = (
  2006 => [ 'MySQL server has gone away',                                         1 ],
  2013 => [ 'Lost connection to MySQL server during query',                       1 ],
  2026 => [ 'TLS/SSL error: unexpected eof while reading',                        1 ],
  2055 => [ "Lost connection to MySQL server at 'reading initial communication "
          . "packet', system error: 104",                                         1 ],
  1062 => [ "Duplicate entry '1' for key 'PRIMARY'",                              0 ],
  1064 => [ 'You have an error in your SQL syntax; check the manual',             0 ],
  1205 => [ 'Lock wait timeout exceeded; try restarting transaction',             0 ],
  1213 => [ 'Deadlock found when trying to get lock; try restarting transaction', 0 ],
  1317 => [ 'Query execution was interrupted',                                    0 ],
);
my @FATAL    = grep {  $ERROR{$_}[1] } sort keys %ERROR;
my @ORDINARY = grep { !$ERROR{$_}[1] } sort keys %ERROR;

# --- the fake DBDs -----------------------------------------------------------
#
# A statement fails where its SQL says: "... /* fail:submit:N */" when it is
# sent (execute), "... /* fail:collect:N */" when its result is read.

our @CONNECTS;
my $next_id = 100;

for my $dbd (sort keys %API) {
  my $api = $API{$dbd};
  no strict 'refs';

  # DBI resets a handle's err before a method runs, except for the handful of
  # methods that are there to read it. Statement and database handle share it.
  my $reset = sub { $_[0]{err} = undef };

  # Fail as the DBD does under RaiseError: number on the handle, text in the
  # exception -- "DBD::x::st METHOD failed: MESSAGE", which carries no number.
  my $fail = sub {
    my ($dbh, $method, $code) = @_;
    my ($message, $gone) = @{ $ERROR{$code} };
    $dbh->{err}  = $code;
    $dbh->{gone} = 1 if $gone;
    die "DBD::${dbd}::st $method failed: $message\n";
  };

  *{"K65::${dbd}::DBH::new"} = sub {
    socketpair(my $client, my $server, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
      or die "socketpair: $!";
    return bless {
      Driver => { Name => $dbd },
      Active => 1,
      id     => ++$next_id,
      client => $client,   # the connection's socket
      server => $server,   # the server's end of it
    }, "K65::${dbd}::DBH";
  };
  *{"K65::${dbd}::DBH::err"}     = sub { $_[0]{err} };
  *{"K65::${dbd}::DBH::prepare"} = sub {
    my ($self, $sql) = @_;
    $reset->($self);
    return bless { dbh => $self, sql => $sql, NUM_OF_FIELDS => 0 }, "K65::${dbd}::STH";
  };
  *{"K65::${dbd}::DBH::$api->{fd}"} = sub { $reset->($_[0]); fileno $_[0]{client} };
  *{"K65::${dbd}::DBH::do"} = sub { 1 };   # the session statement of every connection (karr k121)
  *{"K65::${dbd}::DBH::disconnect"} = sub {
    $reset->($_[0]);
    $_[0]{Active} = 0;
    $_[0]{disconnected}++;
    return 1;
  };

  # A connection the client library has given up refuses the next statement as
  # it is sent: 2006.
  *{"K65::${dbd}::STH::execute"} = sub {
    my ($self) = @_;
    my $dbh = $self->{dbh};
    $reset->($dbh);
    $fail->($dbh, 'execute', 2006) if $dbh->{gone};
    $fail->($dbh, 'execute', $1) if $self->{sql} =~ m{/\* fail:submit:(\d+) \*/};
    syswrite $dbh->{server}, 'R';   # the statement is out: its result arrives
    return 1;
  };
  *{"K65::${dbd}::STH::$api->{ready}"} = sub { $reset->($_[0]{dbh}); 1 };
  *{"K65::${dbd}::STH::$api->{result}"} = sub {
    my ($self) = @_;
    my $dbh = $self->{dbh};
    $reset->($dbh);
    sysread $dbh->{client}, my $result, 1;   # collected: the socket is quiet again
    $fail->($dbh, $api->{result}, $1) if $self->{sql} =~ m{/\* fail:collect:(\d+) \*/};
    $self->{NUM_OF_FIELDS} = 1 if $self->{sql} =~ /^SELECT/;
    return 1;
  };
  # Every row names the connection it ran on, like CONNECTION_ID().
  *{"K65::${dbd}::STH::fetchall_arrayref"} = sub { [ [ $_[0]{dbh}{id} ] ] };
  *{"K65::${dbd}::STH::more_results"} = sub { 0 };   # one result set (karr k73)
}

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn) = @_;
    my ($dbd) = ($dsn // '') =~ /^dbi:(\w*)/i;
    die "fake DBI: no fake for DBD::$dbd\n" unless $API{$dbd};
    my $dbh = "K65::${dbd}::DBH"->new;
    push @CONNECTS, $dbh;
    return $dbh;
  };
}

# The transport has no session reset (core ADR 0079): the pool retires its
# connection at the end of every borrow. This file asks something else -- which
# failures take the connection with them, and which leave it to be used again --
# and that is only visible on a connection that survives a borrow. So here the
# pool gets the reset a server with a session reset would give: done at once,
# the fake's session having nothing to reset. What retires a connection in this
# file is therefore the verdict of _conn_error_is_fatal and nothing else.
{
  no warnings 'redefine';
  *DBIO::MySQL::Storage::Async::_reset_pool_connection = sub { Future->done };
}

{
  package K65::MySQLSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');

  package K65::MariaDBSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');
}

# --- helpers -----------------------------------------------------------------

# A future_io backend with a pool of ONE connection, so "the next call" has
# exactly one connection it could be handed again. The schema is kept: the
# backend holds its owning sync storage weakly.
my @schemas;
sub backend {
  my ($schema_class, $dbd) = @_;
  my $schema = $schema_class->connect(
    "dbi:$dbd:database=t", 'u', 'p', { async => 'future_io', pool_size => 1 },
  );
  push @schemas, $schema;
  my $async = $schema->storage->async;
  @CONNECTS = ();
  return $async;
}

# (1, results...) or (0, error) of a Future, waited for: the fake's result is
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

sub failing { "SELECT 1 /* fail:$_[0]:$_[1] */" }

my @CLASSES = qw( DBIO::MySQL::Storage::Async DBIO::MySQL::Storage::MariaDB::Async );

# ---------------------------------------------------------------------------
# 1. The verdict, asked directly. Both classes, a handle of either DBD: the
#    number is DBI's, so neither the class nor the DBD has a say.
# ---------------------------------------------------------------------------

for my $class (@CLASSES) {
  for my $dbd (sort keys %API) {
    my $dbh   = "K65::${dbd}::DBH"->new;
    my $conn  = { dbh => $dbh };
    my $label = "$class, DBD::$dbd";

    for my $code (@FATAL) {
      $dbh->{err} = $code;
      ok $class->_conn_error_is_fatal($conn, "DBD::${dbd}::st execute failed: $ERROR{$code}[0]\n"),
        "$label: $code ($ERROR{$code}[0]) -- the connection is gone";
    }

    # The reason the answer is a list: after these the session is where it
    # was, and the next statement on it runs.
    for my $code (@ORDINARY) {
      $dbh->{err} = $code;
      ok !$class->_conn_error_is_fatal($conn, "DBD::${dbd}::st execute failed: $ERROR{$code}[0]\n"),
        "$label: $code ($ERROR{$code}[0]) -- a statement error, the connection is kept";
    }

    # 2000 is what both DBDs report for their own misuse errors ("Calling a
    # synchronous function on an asynchronous handle"): the caller's mistake,
    # nothing the server did.
    $dbh->{err} = 2000;
    ok !$class->_conn_error_is_fatal($conn, 'Calling a synchronous function on an asynchronous handle'),
      "$label: 2000, the DBD's own misuse error -- kept";

    # 4031 is two different errors. MySQL 8.0.24+: ER_CLIENT_INTERACTION_TIMEOUT,
    # the server closed an idle session. MariaDB: ER_REFERENCED_TRG_DOES_NOT_EXIST,
    # a statement error on a healthy one. The server product decides (karr k72):
    # the handshake's version string, kept on the connection.
    my $info_attr = lc($dbd) . '_serverinfo';
    $dbh->{err} = 4031;
    for my $case (
      [ '8.0.30',                 1, 'MySQL 8.0.30'             ],
      [ '8.0.24',                 1, 'MySQL 8.0.24'             ],
      [ '8.4.0',                  1, 'MySQL 8.4.0'              ],
      [ '8.0.23',                 0, 'MySQL 8.0.23, before the error'  ],
      [ '5.7.44',                 0, 'MySQL 5.7.44'             ],
      [ '11.8.8-MariaDB-ubu2404', 0, 'MariaDB 11.8.8'           ],
      [ '10.11.2-MariaDB',        0, 'MariaDB 10.11.2'          ],
      [ undef,                    0, 'a server that did not say' ],
    ) {
      my ($info, $fatal, $what) = @$case;
      local $dbh->{$info_attr} = $info;
      my $c = { dbh => $dbh };
      my $got = $class->_conn_error_is_fatal($c, 'The client was disconnected by the server because of inactivity.');
      is $got, $fatal, "$label: 4031 on $what -- " . ($fatal ? 'the session is gone' : 'a statement error, kept');
    }

    # A failure the DBD did not report -- the transport's own croak, a socket
    # fd that could not be dup'ed for the poll -- leaves no number.
    $dbh->{err} = undef;
    ok !$class->_conn_error_is_fatal($conn, 'Cannot dup async connection fd'),
      "$label: no error number on the handle -- nothing says the connection is gone";

    # The text is not read. It carries no number, and its wording is the client
    # library's: the same loss reads differently with another one.
    $dbh->{err} = 1062;
    ok !$class->_conn_error_is_fatal($conn, 'Lost connection to MySQL server during query'),
      "$label: the text of a lost connection over a duplicate-key number -- kept";
    $dbh->{err} = 2013;
    ok $class->_conn_error_is_fatal($conn, "Duplicate entry '1' for key 'PRIMARY'"),
      "$label: the text of a duplicate key over 2013 -- gone";
    ok $class->_conn_error_is_fatal($conn),
      "$label: ... and with no error text at all";

    # Answered without touching the connection: the fake resets its number on
    # every method call, so a ping -- or any other call -- would show here.
    is $dbh->{err}, 2013, "$label: asking leaves the handle as it was -- no ping, no call on it";
  }

  # No handle, no connection. The pool's _shutdown_pool_connection copes with
  # it, and a connection like that fails every statement before it is sent.
  for my $case (
    [ {},               'a connection without a handle' ],
    [ { dbh => undef }, 'a connection whose handle is undef' ],
    [ undef,            'no connection at all' ],
    [ 'conn',           'a connection that is not a hashref' ],
  ) {
    my ($conn, $what) = @$case;
    my $answer = eval { $class->_conn_error_is_fatal($conn, 'boom') };
    is $@, '', "$class: $what does not make the seam throw";
    ok $answer, '... and is dead: there is nothing to send a statement on';
  }
}

# ---------------------------------------------------------------------------
# 2. Where the number is, on a REAL DBI handle. The seam reads the database
#    handle, but a failed statement raises its error on the STATEMENT handle
#    -- and when the send fails, the transport holds no statement handle at
#    all (_submit_query died before keeping it). DBI shares the error between
#    a statement handle and its database handle, so the number is on $dbh
#    either way. It stays there through the statement handle's DESTROY and
#    through reading attributes, and is gone with the next method call on the
#    connection: the seam has to be asked before anything else runs on it,
#    which the base does -- it asks from the failed Future's own callbacks.
#    DBD::Sponge ships with DBI; set_err is how a DBD records an error.
# ---------------------------------------------------------------------------

SKIP: {
  my $dbh = eval {
    DBI->$real_connect('dbi:Sponge:', '', '', { RaiseError => 1, PrintError => 0 });
  } or skip "DBD::Sponge is not available: $@", 6;
  my $conn = { dbh => $dbh };
  my $T    = 'DBIO::MySQL::Storage::Async';

  my $sth = $dbh->prepare('SELECT 1', { rows => [], NAME => [] });
  ok !eval { $sth->set_err(2013, 'Lost connection to MySQL server during query'); 1 },
    'real DBI: an error recorded on a statement handle raises';
  unlike "$@", qr/2013/, '... and the exception text does not carry the number';
  ok $T->_conn_error_is_fatal($conn, "$@"),
    '... the seam finds it on the database handle';

  my $driver = $dbh->{Driver}{Name};   # what _mysql_binding reads
  undef $sth;                          # what a failed _submit_query leaves behind
  ok $T->_conn_error_is_fatal($conn, 'x'),
    '... still there after an attribute read and the statement handle\'s DESTROY';

  $sth = $dbh->prepare('SELECT 1', { rows => [], NAME => [] });
  ok !$T->_conn_error_is_fatal($conn, 'x'),
    '... and gone with the next method call on the connection';

  eval { $sth->set_err(1062, "Duplicate entry '1' for key 'PRIMARY'") };
  ok !$T->_conn_error_is_fatal($conn, "$@"),
    'real DBI: a statement error on the statement handle keeps the connection';
}

# ---------------------------------------------------------------------------
# 3 - 6. End to end, for every schema component over every DBD (karr k60: the
#        component pins the transport class for every DSN, so each class
#        meets each DBD).
# ---------------------------------------------------------------------------

for my $combo (
  [ 'K65::MySQLSchema',   'mysql'   ],
  [ 'K65::MySQLSchema',   'MariaDB' ],
  [ 'K65::MariaDBSchema', 'MariaDB' ],
  [ 'K65::MariaDBSchema', 'mysql'   ],
) {
  my ($schema_class, $dbd) = @$combo;
  my $label = "$schema_class + dbi:$dbd:";

  # -- 3. a statement loses its connection while its result is awaited
  for my $code (@FATAL) {
    my $async = backend($schema_class, $dbd);
    my $first = ran_on($async->_query_async('SELECT 1', []));
    is scalar(@CONNECTS), 1, "$label: a pooled statement runs on the pool's one connection";

    my ($ok, $error) = outcome($async->_query_async(failing(collect => $code), []));
    ok !$ok, "$label: a statement that fails with $code fails";
    like "$error", qr/\Q@{[ DBIO::MySQL::Util::mask_error_details($ERROR{$code}[0]) ]}\E/,
      '... with the DBD\'s own error, a value in it masked (ADR 0075)';
    is_deeply pool_state($async), [ 0, 0 ],
      '... and its connection is retired on the way back, not idled';
    ok $CONNECTS[0]{disconnected}, '... and closed';

    my $next = ran_on($async->_query_async('SELECT 1', []));
    like $next, qr/^\d+$/, "$label: the next call after $code succeeds";
    isnt $next, $first, '... on a FRESH connection';
    is scalar(@CONNECTS), 2, '... opened for it';
  }

  # -- 3. a statement error: the session survives it, so does the connection
  for my $code (@ORDINARY) {
    my $async = backend($schema_class, $dbd);
    my $first = ran_on($async->_query_async('SELECT 1', []));

    my ($ok, $error) = outcome($async->_query_async(failing(collect => $code), []));
    ok !$ok, "$label: a statement that fails with $code fails";
    like "$error", qr/\Q@{[ DBIO::MySQL::Util::mask_error_details($ERROR{$code}[0]) ]}\E/,
      '... with the DBD\'s own error, a value in it masked (ADR 0075)';
    is_deeply pool_state($async), [ 1, 1 ], '... and its connection is back in the pool, idle';
    ok !$CONNECTS[0]{disconnected}, '... not closed';

    my $next = ran_on($async->_query_async('SELECT 1', []));
    is $next, $first, "$label: the next call after $code runs on the SAME connection";
    is scalar(@CONNECTS), 1, '... no connection was opened for it';
  }

  # -- 4. the connection died while it sat idle: the next statement fails as
  #       it is SENT, in _submit_query, before the dispatch returned a Future
  {
    my $async = backend($schema_class, $dbd);
    my $first = ran_on($async->_query_async('SELECT 1', []));
    $CONNECTS[0]{gone} = 1;   # the server ended the idle session

    my $f = eval { $async->_query_async('SELECT 1', []) };
    ok $f, "$label: a send that dies does not escape _query_async" or diag $@;
    my ($ok, $error) = outcome($f);
    ok !$ok, '... the call fails';
    like "$error", qr/server has gone away/, '... with 2006, the send\'s error';
    is_deeply pool_state($async), [ 0, 0 ], '... and the connection is retired';

    my $next = ran_on($async->_query_async('SELECT 1', []));
    like $next, qr/^\d+$/, "$label: the call after it succeeds";
    isnt $next, $first, '... on a FRESH connection: one caller paid, not every one';
  }

  # -- 4. a statement error raised as the statement is sent keeps it
  {
    my $async = backend($schema_class, $dbd);
    my $first = ran_on($async->_query_async('SELECT 1', []));
    my ($ok) = outcome($async->_query_async(failing(submit => 1064), []));
    ok !$ok, "$label: a statement refused as it is sent fails";
    is_deeply pool_state($async), [ 1, 1 ], '... and its connection is back in the pool';
    is ran_on($async->_query_async('SELECT 1', [])), $first, '... and is used again';
  }

  # -- 5. pinned: the holder keeps it until its one hand-back
  {
    my $async = backend($schema_class, $dbd);
    my $conn  = $async->pool->acquire->get;

    my ($ok) = outcome($async->_query_async_pinned($conn, failing(collect => 2013), []));
    ok !$ok, "$label: pinned, a statement that loses the connection fails";
    is_deeply pool_state($async), [ 1, 0 ], '... the connection is still out with its holder';
    $async->pool->release($conn);
    is_deeply pool_state($async), [ 0, 0 ], '... and its hand-back retires it';
    ok $CONNECTS[0]{disconnected}, '... closed';
  }
  {
    my $async = backend($schema_class, $dbd);
    my $conn  = $async->pool->acquire->get;

    my ($ok) = outcome($async->_query_async_pinned($conn, failing(collect => 1062), []));
    ok !$ok, "$label: pinned, a duplicate key fails";
    $async->pool->release($conn);
    is_deeply pool_state($async), [ 1, 1 ], '... and its hand-back puts the connection back idle';
  }

  # -- 5. a transaction whose connection dies under it: the transaction fails
  #       with the statement's error, and its connection is not handed out
  #       again -- core's finalizer releases it, and the release retires it
  {
    my $async = backend($schema_class, $dbd);
    my ($ok, $error) = outcome($async->txn_do_async(sub {
      my ($txn) = @_;
      return $txn->_query_async(failing(collect => 2013), []);
    }));
    ok !$ok, "$label: a transaction whose connection is lost fails";
    like "$error", qr/Lost connection/, '... with the statement\'s error';
    is_deeply pool_state($async), [ 0, 0 ], '... and its connection is retired';
    my $in_txn = $CONNECTS[0]{id};

    my $next = ran_on($async->_query_async('SELECT 1', []));
    like $next, qr/^\d+$/, "$label: the call after the transaction succeeds";
    isnt $next, $in_txn, '... on a FRESH connection';
  }

  # -- 5. a deadlock ends the transaction, not the session: the server rolled
  #       it back and the connection takes the next one
  {
    my $async = backend($schema_class, $dbd);
    my ($ok, $error) = outcome($async->txn_do_async(sub {
      my ($txn) = @_;
      return $txn->_query_async(failing(collect => 1213), []);
    }));
    ok !$ok, "$label: a transaction that deadlocks fails";
    like "$error", qr/Deadlock found/, '... with the statement\'s error';
    is_deeply pool_state($async), [ 1, 1 ], '... and its connection is back in the pool';
    is ran_on($async->_query_async('SELECT 1', [])), $CONNECTS[0]{id},
      '... and runs the next call';
    is scalar(@CONNECTS), 1, '... no connection was opened for it';
  }

  # -- 6. the listen connection is not the pool's. Its statements go through
  #       _query_async_pinned, so the seam is asked about it too; the report
  #       must change nothing and say nothing -- core's listen machinery sees
  #       the death through the failed poll and rebuilds the connection itself
  {
    my $async = backend($schema_class, $dbd);
    my $lconn = $async->_listen_open->get;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my ($ok, $error) = outcome($async->_query_async_pinned($lconn, failing(collect => 2013), []));
    ok !$ok, "$label: a statement on the listen connection that loses it fails";
    like "$error", qr/Lost connection/, '... with the DBD\'s own error';
    is_deeply \@warnings, [], '... reporting it to a pool that does not hold it warns nothing';
    is_deeply pool_state($async), [ 0, 0 ], '... the pool is untouched';
    ok !$lconn->{dbh}{disconnected}, '... and the handle is left for core\'s _listen_close';
  }
}

# ---------------------------------------------------------------------------
# 7. One implementation. The MariaDB convention class answers with the base's
#    method: the number is DBI's, the same for both DBDs, and a class cannot
#    know which DBD its connections run on anyway (karr k60). And it is this
#    dist's answer, not dbio-async's default "never".
# ---------------------------------------------------------------------------
{
  my $ours    = DBIO::MySQL::Storage::Async->can('_conn_error_is_fatal');
  my $mariadb = DBIO::MySQL::Storage::MariaDB::Async->can('_conn_error_is_fatal');
  my $default = DBIO::Async::Storage->can('_conn_error_is_fatal');
  ok $ours && $default && $ours != $default,
    'the transport fills the seam -- it is not the default of DBIO::Async::Storage';
  ok $mariadb && $ours && $mariadb == $ours,
    'the MariaDB convention class resolves to the same method -- no class decides the DBD';
}

done_testing;
