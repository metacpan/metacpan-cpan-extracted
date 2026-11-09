use strict;
use warnings;
use Test::More;
use Socket qw( AF_UNIX SOCK_STREAM PF_UNSPEC );

# karr k69 -- a transaction on the future_io transport, offline: it commits, it
# rolls back, and a statement the server interrupted (error 1317) ends the
# transaction but not the connection.
#
# WHY IT MATTERS. Until this file the only transaction this dist ran offline was
# the one whose connection dies under it (t/68). Commit and rollback ran live
# only (t/55), and a statement the server interrupted ran nowhere: t/68 asks
# _conn_error_is_fatal about 1317 directly, and that was all. Three things
# about a MySQL transaction are this transport's to get right, and each fails
# silently:
#
#   * ONE STATEMENT PER CONNECTION. Both DBDs run a single asynchronous
#     statement per handle, and this transport's _submit_query drops the handle
#     of the statement before it. A block that issues two statements without
#     awaiting the first -- Future->needs_all over two inserts is ordinary code
#     -- must still see them run one after the other, and COMMIT after both.
#   * A STATEMENT ERROR LEAVES THE TRANSACTION OPEN. For an interrupted
#     statement, as for most statement errors, MySQL and MariaDB undo that
#     statement and nothing else; a COMMIT after it succeeds and keeps the half
#     of the block that ran. PostgreSQL would answer that COMMIT with ROLLBACK;
#     here nothing would. So the transaction has to be rolled back by us -- also
#     when nobody looked at the failed statement -- and the caller told why.
#   * THE CONNECTION GOES BACK, ONCE, AND CLEAN. Error 1317 (KILL QUERY, a
#     statement timeout) is the server interrupting one statement; the session
#     runs the next one. _conn_error_is_fatal does not list it, so the
#     connection is reused, not closed -- and the statements issued behind the
#     interrupted one are still sent. It is released exactly once, after the
#     COMMIT or ROLLBACK was answered: handed back earlier, the next borrower's
#     statement lands inside this transaction.
#
# What this file claims, for both DBDs under their schema component:
#   1. two inserts issued unchained in a txn_do_async: BEGIN, the first insert,
#      the second only once the first has its answer, COMMIT, then one release;
#      each insert resolves with its own row, the transaction with the block's
#      value, and the server has both rows;
#   2. the second of the two is interrupted (1317): ROLLBACK and no COMMIT, the
#      transaction fails with that statement's error, the first insert's row
#      is gone, one release after ROLLBACK's answer;
#   3. the first is interrupted and nobody awaits either, the block returning
#      normally: the insert queued behind it is still sent and resolves, and
#      the transaction is rolled back and fails with the interrupted
#      statement's error all the same;
#   4. the block dies with an insert in flight: ROLLBACK waits for that
#      insert's answer, and the transaction fails with the block's error;
#   5. after each of them the connection is the pool's one idle connection,
#      open, with no transaction on its session -- and the next pooled insert
#      runs on it and is committed on its own;
#   6. none of it warns -- for claim 4 as well, where core's transaction
#      context once let go of the Future of the insert still in flight and
#      Future.pm said so when the result arrived (fixed in core, karr core
#      k292).
#
# FULLY OFFLINE. The one substitution is the DBD: DBI->connect hands out a fake
# handle of the DBD the DSN names, with only that DBD's method names. Behind it
# is a server of one table: an INSERT inside a transaction is the session's
# until COMMIT makes it everybody's or ROLLBACK drops it, outside one it is
# committed at once. A statement the test has marked is interrupted: it changes
# nothing, its result is error 1317, and the session and its transaction stay as
# they were. The handle takes one asynchronous statement at a time and refuses a
# second with the DBD's own error (section 0). Its socket is one end of a real
# socketpair, readable exactly while a result waits on it. Schema component,
# storage, async resolution, the pool with its borrow-time check, core's
# txn_do_async and transaction context, dbio-async's _query_async_pinned with
# its statement queue, and this dist's _submit_query / _collect_result /
# _conn_error_is_fatal / _idle_connection_alive run for real. The pool's release
# is wrapped to be counted, and runs.
#
# NOT PROVEN HERE (live only): that a real server answers KILL QUERY with 1317
# at the statement's result and leaves the session and its transaction open --
# t/79 shows that, and that a statement TIMEOUT does the same under another
# number (3024 on MySQL, 1969 on MariaDB; "a statement timeout" above is not
# 1317 on either). Still shown nowhere: what a real DBD does with a second
# statement on a busy handle beyond refusing it.

BEGIN {
  eval {
    require DBIO::MySQL::Storage::Async;
    require DBIO::MySQL::Storage::MariaDB::Async;
    1;
  } or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

use DBI;
use Future;
use DBIO::Test;

# A statement nobody answers would leave its Future pending for good.
local $SIG{ALRM} = sub { die "t/71 timed out: a Future never settled\n" };
alarm 120;

# Everything the runs below say on STDERR. A warning out of the transport's
# completion path is no error anybody can catch: it is all a caller sees of it.
my @WARNINGS;
local $SIG{__WARN__} = sub { push @WARNINGS, @_ };

# Each DBD's own names, spelled out here: the expectation must not be derived
# from the table under test.
my %API = (
  mysql => {
    fd       => 'mysql_fd',
    ready    => 'mysql_async_ready',
    result   => 'mysql_async_result',
    insertid => 'mysql_insertid',
  },
  MariaDB => {
    fd       => 'mariadb_sockfd',
    ready    => 'mariadb_async_ready',
    result   => 'mariadb_async_result',
    insertid => 'mariadb_insertid',
  },
);

# The two errors of this file: what the DBD raises for a second statement on a
# handle with one in flight, and what the server answers an interrupted
# statement with.
my %ERROR = (
  2000 => 'Calling a synchronous function on an asynchronous handle',
  1317 => 'Query execution was interrupted',
);
my $INTERRUPTED = qr/\Q$ERROR{'1317'}\E/;

# --- the fake server and DBDs ------------------------------------------------

our @CONNECTS;    # every handle DBI->connect handed out
our @LOG;         # send:<stmt> and result:<stmt> per statement, release per pool release
our @WIRE;        # the handle each statement was sent on, in order
our @TABLE;       # the committed rows of the server's one table, by name
our $NEXT_ID;     # its AUTO_INCREMENT counter
our $INTERRUPT;   # the name whose INSERT the server interrupts

# What a statement is called in @LOG: an INSERT by the name it inserts, any
# other statement by its SQL.
sub label {
  my ($sql, @bind) = @_;
  return $sql =~ /\AINSERT INTO `?artist`?/ ? "insert:$bind[0]" : $sql;
}

# The server runs one statement on the session behind $dbh. Returns the id it
# generated, or (0, the error number) for a statement it interrupted.
sub serve {
  my ($dbh, $sql, @bind) = @_;

  if ($sql eq 'BEGIN') {
    $dbh->{txn} = 1;
    return 0;
  }
  if ($sql eq 'COMMIT') {
    push @TABLE, splice @{ $dbh->{uncommitted} };
    $dbh->{txn} = 0;
    return 0;
  }
  if ($sql eq 'ROLLBACK') {
    @{ $dbh->{uncommitted} } = ();
    $dbh->{txn} = 0;
    return 0;
  }
  if ($sql =~ /\AINSERT INTO `?artist`?/) {
    my $name = $bind[0];
    # Interrupted: the statement is undone, the transaction it ran in is not.
    return (0, 1317) if defined $INTERRUPT && $name eq $INTERRUPT;
    push @{ $dbh->{txn} ? $dbh->{uncommitted} : \@TABLE }, $name;
    return $NEXT_ID++;
  }
  die "fake server: a statement this file does not expect on the wire: $sql\n";
}

for my $dbd (sort keys %API) {
  my $api = $API{$dbd};
  no strict 'refs';

  # DBI resets a handle's err before a method runs; statement and database
  # handle share it (t/68, section 2).
  my $reset = sub { $_[0]{err} = undef };

  # Fail as the DBD does under RaiseError: number on the handle, text in the
  # exception -- which carries no number.
  my $fail = sub {
    my ($dbh, $method, $code) = @_;
    $dbh->{err} = $code;
    die "DBD::${dbd}::st $method failed: $ERROR{$code}\n";
  };

  *{"K69::${dbd}::DBH::new"} = sub {
    socketpair(my $client, my $server, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
      or die "socketpair: $!";
    return bless {
      Driver      => { Name => $dbd },
      Active      => 1,
      client      => $client,   # the connection's socket
      server      => $server,   # the server's end of it
      txn         => 0,         # the session has a transaction open
      uncommitted => [],        # ... and these rows in it
    }, "K69::${dbd}::DBH";
  };
  *{"K69::${dbd}::DBH::err"}     = sub { $_[0]{err} };
  *{"K69::${dbd}::DBH::prepare"} = sub {
    my ($self, $sql) = @_;
    $reset->($self);
    return bless { dbh => $self, sql => $sql, NUM_OF_FIELDS => 0 }, "K69::${dbd}::STH";
  };
  *{"K69::${dbd}::DBH::$api->{fd}"} = sub { $reset->($_[0]); fileno $_[0]{client} };
  *{"K69::${dbd}::DBH::do"} = sub { 1 };   # the session statement of every connection (karr k121)
  *{"K69::${dbd}::DBH::disconnect"} = sub {
    $reset->($_[0]);
    $_[0]{Active} = 0;
    $_[0]{disconnected}++;
    return 1;
  };

  # Sent: the server runs the statement, and its result is on its way. One
  # statement at a time: until that result is collected the handle refuses the
  # next, and nothing reaches the server.
  *{"K69::${dbd}::STH::execute"} = sub {
    my ($self, @bind) = @_;
    my $dbh = $self->{dbh};
    $reset->($dbh);
    $fail->($dbh, 'execute', 2000) if $dbh->{in_flight};

    $self->{label} = main::label($self->{sql}, @bind);
    push @LOG,  "send:$self->{label}";
    push @WIRE, $dbh;
    @{$self}{qw( generated error )} = main::serve($dbh, $self->{sql}, @bind);
    $dbh->{in_flight} = 1;
    syswrite $dbh->{server}, 'R';
    return 1;
  };
  *{"K69::${dbd}::STH::more_results"} = sub { 0 };   # one result set (karr k73)
  *{"K69::${dbd}::STH::$api->{ready}"} = sub {
    $reset->($_[0]{dbh});
    my $rin = '';
    vec($rin, fileno $_[0]{dbh}{client}, 1) = 1;
    return select($rin, undef, undef, 0) ? 1 : 0;
  };
  # Collected: the socket is quiet again and the handle is free for the next
  # statement. An interrupted statement's error arrives here.
  *{"K69::${dbd}::STH::$api->{result}"} = sub {
    my ($self) = @_;
    my $dbh = $self->{dbh};
    $reset->($dbh);
    sysread $dbh->{client}, my $result, 1;
    $dbh->{in_flight} = 0;
    push @LOG, "result:$self->{label}";
    $fail->($dbh, $api->{result}, $self->{error}) if $self->{error};
    $self->{ $api->{insertid} } = $self->{generated};
    return 1;   # one row affected
  };
}

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn) = @_;
    my ($dbd) = ($dsn // '') =~ /^dbi:(\w*)/i;
    die "fake DBI: no fake for DBD::$dbd\n" unless $API{$dbd};
    my $dbh = "K69::${dbd}::DBH"->new;
    push @CONNECTS, $dbh;
    return $dbh;
  };

  # Every release of a connection to the pool is counted, in @LOG, where it
  # happened between the statements -- and then runs. The pool itself cannot
  # show a second release: it takes an idle connection back without a word.
  my $release = \&DBIO::Storage::PoolBase::release;
  *DBIO::Storage::PoolBase::release = sub { push @LOG, 'release'; goto &$release };
}

# The transport has no session reset (core ADR 0079): the pool retires its
# connection at the end of every borrow. Claim 5 of this file is that a
# transaction hands its connection back clean -- committed or rolled back, no
# transaction open, usable by the next statement -- and that is only visible on
# a connection that is handed back. So the pool gets the reset a server with a
# session reset would give, done at once and touching nothing: the state the
# claim looks at (the session's open transaction) is the one the COMMIT or the
# ROLLBACK of the transaction left, not one the stub made.
{
  no warnings 'redefine';
  *DBIO::MySQL::Storage::Async::_reset_pool_connection = sub { Future->done };
}

{
  package K69::MySQLSchema;
  use base 'DBIO::Test::Schema';
  __PACKAGE__->load_components('MySQL');

  package K69::MariaDBSchema;
  use base 'DBIO::Test::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');
}

# --- helpers -----------------------------------------------------------------

# A schema on the future_io transport with a pool of ONE connection -- so "the
# next statement" has exactly one connection it could be handed again -- and a
# server with an empty table. The schema is kept: the backend holds its owning
# sync storage weakly.
my @schemas;
sub connected {
  my ($schema_class, $dbd) = @_;
  my $schema = $schema_class->connect(
    "dbi:$dbd:database=t", 'u', 'p', { async => 'future_io', pool_size => 1 },
  );
  push @schemas, $schema;
  @CONNECTS = @LOG = @WIRE = @TABLE = ();
  $NEXT_ID  = 1;
  return $schema;
}

# (1, results...) or (0, error) of a Future, waited for.
sub outcome {
  my ($f) = @_;
  $f->await;
  return $f->is_done ? (1, $f->get) : (0, scalar $f->failure);
}

# What a statement Future of a block came to, once the transaction is over.
sub came_to {
  my ($f) = @_;
  return 'never issued'  unless $f;
  return 'still pending' unless $f->is_ready;
  return 'cancelled'     if $f->is_cancelled;
  return $f->is_done ? [ $f->get ] : 'FAILED: ' . $f->failure;
}

# The transaction of this file: two inserts on the context, the second issued
# while the first is in flight. What the block saw as it issued them goes into
# %$seen. $returns builds what the block returns from the two Futures.
sub two_unchained {
  my ($schema, $seen, $returns) = @_;
  my $artist = $schema->source('Artist');
  return $schema->storage->txn_do_async(sub {
    my ($txn) = @_;
    my $first  = $txn->insert_async($artist, { name => 'Miles' });
    my $second = $txn->insert_async($artist, { name => 'Bill' });
    $seen->{log}    = [ @LOG ];
    $seen->{state}  = [ map { $_->is_ready ? 'answered' : 'pending' } $first, $second ];
    $seen->{first}  = $first;
    $seen->{second} = $second;
    return $returns->($first, $second);
  });
}

# Both awaited, as ordinary code does it.
sub awaits_both {
  my ($first, $second) = @_;
  return Future->needs_all($first, $second)->then(sub { Future->done('block result') });
}

# Claim 5, after a transaction on $schema: where its connection is, and that
# the next pooled statement can use it.
sub connection_is_reused {
  my ($schema, $label, @rows_before) = @_;
  my $pool = $schema->storage->async->pool;

  is_deeply [ $pool->size, $pool->available ], [ 1, 1 ],
    "$label: the connection is back in the pool, idle";
  ok !$CONNECTS[0]{disconnected}, '... open, not retired';
  is $CONNECTS[0]{txn}, 0, '... and its session has no transaction open';

  @LOG = ();
  my ($ok, $row) = outcome(
    $schema->storage->insert_async($schema->source('Artist'), { name => 'after' }),
  );
  ok $ok, "$label: the next pooled insert succeeds" or diag $row;
  is_deeply \@LOG, [qw( send:insert:after result:insert:after release )],
    '... sent at once, and released once';
  is scalar(@CONNECTS), 1, '... no connection was opened for it';
  ok $WIRE[-1] == $CONNECTS[0], '... it ran on the connection the transaction had';
  is_deeply \@TABLE, [ @rows_before, 'after' ],
    '... and is committed on its own: no transaction was left open to swallow it';
}

# ---------------------------------------------------------------------------
# 0. The instrument. Everything below is about statements not overlapping on
#    one connection, so the fake has to refuse an overlap -- as the DBDs do.
# ---------------------------------------------------------------------------

for my $dbd (sort keys %API) {
  my $dbh    = "K69::${dbd}::DBH"->new;
  my $result = $API{$dbd}{result};

  my $first = $dbh->prepare('BEGIN');
  $first->execute;
  ok !eval { $dbh->prepare('COMMIT')->execute; 1 },
    "the fake DBD::$dbd refuses a second statement while one is in flight";
  is $dbh->err, 2000, '... with the number both DBDs give their own misuse errors';
  is_deeply \@LOG, [ 'send:BEGIN' ], '... and the refused statement never reached the server';

  $first->$result;
  ok eval { $dbh->prepare('COMMIT')->execute; 1 },
    '... once the result is collected the handle takes the next one' or diag $@;
  @LOG = @WIRE = ();
}

for my $combo (
  [ 'K69::MySQLSchema',   'mysql'   ],
  [ 'K69::MariaDBSchema', 'MariaDB' ],
) {
  my ($schema_class, $dbd) = @$combo;
  my $label = "$schema_class + dbi:$dbd:";

  # -------------------------------------------------------------------------
  # 1. Two unchained inserts, committed.
  # -------------------------------------------------------------------------
  {
    my $schema = connected($schema_class, $dbd);
    my %seen;
    my ($ok, @result) = outcome(two_unchained($schema, \%seen, \&awaits_both));

    is_deeply $seen{log}, [qw( send:BEGIN result:BEGIN send:insert:Miles )],
      "$label: both inserts issued -- only the first is on the wire";
    is_deeply $seen{state}, [qw( pending pending )],
      '... and neither has its answer: the second was issued with the first in flight';

    ok $ok, "$label: the transaction commits" or diag $result[0];
    is_deeply \@result, [ 'block result' ], '... and resolves with the block\'s value';
    is_deeply \@LOG, [qw(
      send:BEGIN        result:BEGIN
      send:insert:Miles result:insert:Miles
      send:insert:Bill  result:insert:Bill
      send:COMMIT       result:COMMIT
      release
    )], '... one statement at a time, in the order issued, COMMIT last, then ONE release';
    is scalar(grep { $_ != $CONNECTS[0] } @WIRE), 0,
      '... all of it on one connection';

    is_deeply [ came_to($seen{first}), came_to($seen{second}) ],
      [ [ { name => 'Miles', artistid => 1 } ], [ { name => 'Bill', artistid => 2 } ] ],
      "$label: each insert resolves with its own row";
    is_deeply \@TABLE, [qw( Miles Bill )], '... and the server has both, committed';

    connection_is_reused($schema, $label, qw( Miles Bill ));
    is_deeply [ splice @WARNINGS ], [], "$label: ... and none of it warned";
  }

  # -------------------------------------------------------------------------
  # 2. The second insert is interrupted. The server undid that statement and
  #    left the transaction open with the first insert in it.
  # -------------------------------------------------------------------------
  {
    my $schema = connected($schema_class, $dbd);
    local $INTERRUPT = 'Bill';
    my %seen;
    my ($ok, $error) = outcome(two_unchained($schema, \%seen, \&awaits_both));

    ok !$ok, "$label: a transaction with an interrupted statement fails";
    like "$error", $INTERRUPTED, '... with that statement\'s own error';
    is_deeply \@LOG, [qw(
      send:BEGIN        result:BEGIN
      send:insert:Miles result:insert:Miles
      send:insert:Bill  result:insert:Bill
      send:ROLLBACK     result:ROLLBACK
      release
    )], '... ROLLBACK and no COMMIT, and ONE release, after ROLLBACK was answered';
    is_deeply came_to($seen{first}), [ { name => 'Miles', artistid => 1 } ],
      "$label: the insert before it had resolved with its row";
    is_deeply \@TABLE, [],
      '... and that row is gone: a COMMIT here would have kept half the block';

    connection_is_reused($schema, "$label after 1317");
    is_deeply [ splice @WARNINGS ], [], "$label: ... and none of it warned";
  }

  # -------------------------------------------------------------------------
  # 3. The FIRST insert is interrupted, nobody awaits either, and the block
  #    returns normally. The second insert was issued before anyone knew.
  # -------------------------------------------------------------------------
  {
    my $schema = connected($schema_class, $dbd);
    local $INTERRUPT = 'Miles';
    my %seen;
    my ($ok, $error) = outcome(two_unchained($schema, \%seen, sub { 'block result' }));

    is_deeply \@LOG, [qw(
      send:BEGIN        result:BEGIN
      send:insert:Miles result:insert:Miles
      send:insert:Bill  result:insert:Bill
      send:ROLLBACK     result:ROLLBACK
      release
    )], "$label: the insert queued behind an interrupted one is still sent -- "
      . 'the connection was not given up -- and then ROLLBACK, not COMMIT';
    is_deeply came_to($seen{second}), [ { name => 'Bill', artistid => 1 } ],
      '... it resolves with its own row';
    ok !$ok, "$label: the transaction fails though its block returned normally";
    like "$error", $INTERRUPTED, '... with the interrupted statement\'s error';
    is_deeply \@TABLE, [], '... and the insert that did run is not committed';

    connection_is_reused($schema, "$label after an unawaited 1317");
    is_deeply [ splice @WARNINGS ], [], "$label: ... and none of it warned";
  }

  # -------------------------------------------------------------------------
  # 4. The block dies with an insert in flight. ROLLBACK on a handle with a
  #    statement in flight is the overlap of section 0: refused, the
  #    transaction would stay open on a connection that goes back to the pool.
  # -------------------------------------------------------------------------
  {
    my $schema = connected($schema_class, $dbd);
    my $artist = $schema->source('Artist');
    my ($ok, $error) = outcome($schema->storage->txn_do_async(sub {
      my ($txn) = @_;
      $txn->insert_async($artist, { name => 'Miles' });
      die "the block changed its mind\n";
    }));

    ok !$ok, "$label: a transaction whose block dies fails";
    like "$error", qr/the block changed its mind/, '... with the block\'s error';
    is_deeply \@LOG, [qw(
      send:BEGIN        result:BEGIN
      send:insert:Miles result:insert:Miles
      send:ROLLBACK     result:ROLLBACK
      release
    )], '... ROLLBACK went out once the insert in flight had its answer, then ONE release';
    is_deeply \@TABLE, [], '... and nothing is committed';

    connection_is_reused($schema, "$label after a rollback");

    # The insert's Future had one holder, the transaction context, and the
    # context let go of its statements as ROLLBACK went out
    # (DBIO::Storage::Async::TransactionContext::_invalidate) -- with that
    # insert still in flight, so that Future.pm warned "lost a sequence
    # Future" when the result arrived. Core (karr core k292) now retains each
    # such Future until it is answered; this is the claim it was waiting for.
    is_deeply [ splice @WARNINGS ], [], "$label: ... and none of it warned";
  }
}

alarm 0;
done_testing;
