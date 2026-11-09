use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k94: two statements issued on a future_io transaction
# context without chaining them -- the second issued before the first has its
# answer -- run one after the other on the transaction's connection, and the
# transaction ends.
#
# WHY: this transport has room for exactly one statement per connection.
# _submit_query leaves the statement handle on $conn, _collect_result reads
# "the" result through it, and DBD::Pg itself keeps one async statement per
# database handle. Nothing in a transaction makes the caller await one
# statement before issuing the next -- Future->needs_all over two selects is
# ordinary code. Before dbio-async k33 the second _submit_query ran while the
# first statement was still in flight and dropped its handle; live (PostgreSQL
# 18.6 / DBD::Pg 3.20.2, measured at karr k86) DBI warned "st handle cleared
# whilst still active", the first statement never resolved, and txn_do_async
# never finished. The base now queues statements per pinned connection
# (DBIO::Async::Storage, "THE PINNED STATEMENT QUEUE"). This file pins what
# that means for this transport's own two seams.
#
# What this file claims:
#   1. _submit_query is called for the second statement only once the first
#      has SETTLED -- not at its first readable event: a result that arrives in
#      two reads keeps the second waiting through _collect_result's re-poll --
#      and after the first's caller saw its answer. Until then the handle on
#      $conn is the first statement's;
#   2. no statement handle is dropped while its statement is in flight, each
#      statement resolves with its own rows, COMMIT goes out last, the
#      transaction resolves with the block's value, and the connection is back
#      in the pool, idle -- the next pooled statement goes out at once;
#   3. a failure does not hang it either. The first statement fails: the second
#      (cancelled by needs_all while it waited) is never sent, ROLLBACK goes out,
#      and the transaction fails with the statement's own error. The second
#      fails: the same, after the first resolved with its rows;
#   4. counter-check: with the base's queue taken out, the transaction of claim
#      1 puts the second statement on the connection while the first is in
#      flight, the first's handle is dropped, and no COMMIT is sent -- so
#      claims 1 and 2 hold because of the queue, and the scenario really is two
#      statements on one connection.
#
# There is no skip for a dbio-async without the queue: it has no seam to ask
# for, and against such a copy this file is meant to fail -- that combination
# is the bug.
#
# THE FAKE models DBD::Pg's one async slot per database handle and nothing
# beyond it: a statement handle dropped while it owns the slot is recorded
# (@CLEARED -- the event DBI warns about live) and frees the slot, pg_ready and
# pg_result without a statement in the slot die, and a transaction aborts as
# in t/71. On the fake the unqueued transaction of claim 4 fails where the
# live one hangs; that it does not commit is all claim 4 says. WHAT RUNS FOR
# REAL: the pool, core's txn_do_async and the transaction context, the base's
# _query_async_pinned with its queue and _await_query_result, and this dist's
# _submit_query / _collect_result / _txn_commit_rolled_back (section 0 checks
# that). THE SUBSTITUTIONS: DBI->connect hands out the fake; _await_readable
# returns a pending Future the test resolves itself (answer), so "before the
# first has its answer" is a state the test can stand in; and the borrow-time
# check _idle_connection_alive answers its default (t/75).

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

use Future;
use Scalar::Util ();

# --- the fake DBD::Pg ------------------------------------------------------------

our @LOG;        # send:<stmt> / result:<stmt> from the fake, and what stmt() adds
our @CLEARED;    # statements whose handle was dropped while they were in flight
our @READABLE;   # the pending _await_readable Futures, oldest first
our %READS;      # statement => readable events its result takes (default 1)

# The table a statement names, or the statement itself (BEGIN, COMMIT, ...).
sub label { my ($sql) = @_; return $sql =~ /FROM "(\w+)"/ ? $1 : $sql }

{
  package FakeQueue::DBH;

  sub new {
    return bless { Active => 1, pg_socket => 42, txn => 'idle' }, shift;
  }

  sub prepare {
    my ($self, $sql) = @_;
    return bless { dbh => $self, sql => $sql, label => main::label($sql) },
      'FakeQueue::STH';
  }

  sub pg_ready {
    my ($self) = @_;
    my $sth = $self->{in_flight}
      or die "DBD::Pg::db pg_ready failed: No asynchronous query is running\n";
    return --$sth->{reads_left} > 0 ? 0 : 1;
  }

  # The answer for the statement in the slot; dies like DBD::Pg (RaiseError)
  # on an error. A failed statement aborts an open transaction, as in t/71.
  sub pg_result {
    my ($self) = @_;
    my $sth = delete $self->{in_flight}
      or die "DBD::Pg::db pg_result failed: No asynchronous query is running\n";
    $sth->{in_flight} = 0;
    my ($label, $txn) = ($sth->{label}, $self->{txn});
    push @main::LOG, "result:$label";

    if ($label eq 'BEGIN') {
      $self->{txn} = 'open';
      return $self->answer($sth, 'BEGIN', 0);
    }
    if ($label eq 'COMMIT' || $label eq 'ROLLBACK') {
      $self->{txn} = 'idle';
      return $self->answer($sth, $txn eq 'aborted' ? 'ROLLBACK' : $label, 0);
    }
    if ($txn eq 'aborted') {
      die "DBD::Pg::db pg_result failed: ERROR:  current transaction is aborted, "
        . "commands ignored until end of transaction block\n";
    }
    if ($label eq 'bad') {
      $self->{txn} = 'aborted' if $txn eq 'open';
      die qq{DBD::Pg::db pg_result failed: ERROR:  relation "bad" does not exist\n};
    }
    return $self->answer($sth, 'SELECT 1', 1);
  }

  sub answer {
    my ($self, $sth, $tag, $fields) = @_;
    $sth->{pg_cmd_status} = $tag;
    $sth->{NUM_OF_FIELDS} = $fields;
    return $fields ? 1 : '0E0';
  }

  sub state { q{} }

  sub disconnect { $_[0]{Active} = 0; 1 }
}

{
  package FakeQueue::STH;

  # The slot holds the statement weakly, as DBD::Pg's async_sth pointer does:
  # the handle on $conn is the only thing keeping it.
  sub execute {
    my ($self) = @_;
    push @main::LOG, "send:$self->{label}";
    $self->{in_flight}  = 1;
    $self->{reads_left} = $main::READS{ $self->{label} } // 1;
    Scalar::Util::weaken($self->{dbh}{in_flight} = $self);
    return 1;
  }

  # Every row names its statement, so a result read for the wrong one shows.
  sub fetchall_arrayref { [ [ $_[0]{label} ] ] }

  sub DESTROY {
    my ($self) = @_;
    return unless $self->{in_flight};
    push @main::CLEARED, $self->{label};
    delete $self->{dbh}{in_flight}
      if ($self->{dbh}{in_flight} // 0) == $self;
    return;
  }
}

{
  no warnings 'redefine';
  *DBI::connect = sub { FakeQueue::DBH->new };
}

{
  package FakeQueue::Transport;
  use base 'DBIO::PostgreSQL::Storage::Async';

  # The socket turns readable when the test says so (main::answer).
  sub _await_readable {
    my $f = Future->new;
    push @main::READABLE, $f;
    return $f;
  }

  # Held at the seam's default: the fake's pg_socket is no real fd (t/72).
  sub _idle_connection_alive { 1 }

  # The fake counts what goes on the wire; the reset between borrows
  # (DISCARD ALL, k154) is not what this file is about (t/195, t/196).
  sub _reset_pool_connection { Future->done }
}

{
  # The base's pinned dispatch without its queue, for the counter-check
  # (claim 4): every statement goes onto the connection as it is issued.
  package FakeQueue::Unqueued;
  use base 'FakeQueue::Transport';

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    return $self->_await_query_result($conn, $self->_transform_sql($sql), $bind // []);
  }
}

# --- helpers ---------------------------------------------------------------------

sub fresh {
  my ($class) = @_;
  my $s = ($class // 'FakeQueue::Transport')->new(undef);
  $s->connect_info([ 'dbi:Pg:dbname=queue_test', 'u', 'p', { pool_size => 1 } ]);
  @LOG = @CLEARED = @READABLE = ();
  %READS = ();
  return $s;
}

# One readable event on the connection: the oldest wait still pending.
sub answer {
  while (my $f = shift @READABLE) {
    next if $f->is_ready;
    $f->done;
    return 1;
  }
  return 0;
}

# Readable events until $f settles or nothing waits for one. Bounded, so a
# transaction that would never end leaves a pending Future, not a spinning test.
sub drain {
  my ($f) = @_;
  for (1 .. 50) {
    last if $f->is_ready;
    answer() or last;
  }
  return $f;
}

# A statement on the context; when its caller sees the outcome goes in the log.
sub stmt {
  my ($ctx, $table) = @_;
  my $f = $ctx->select_async($table, ['x'], {});
  $f->on_ready(sub {
    push @LOG, ($_[0]->is_cancelled ? 'cancelled' : 'settled') . ":$table";
  });
  return $f;
}

# The transaction of this file: two statements on the context, the second
# issued while the first is in flight. What the block sees goes into %$st.
sub unchained_txn {
  my ($s, $st, $first, $second) = @_;
  return $s->txn_do_async(sub {
    my ($ctx) = @_;
    $st->{conn}   = $ctx->txn_conn;
    $st->{first}  = stmt($ctx, $first);
    $st->{second} = stmt($ctx, $second);
    return Future->needs_all($st->{first}, $st->{second})
      ->then(sub { Future->done('block result') });
  });
}

sub handle_on { my ($conn) = @_; return $conn && $conn->{sth} ? $conn->{sth}{label} : 'none' }

sub rows_of {
  my ($f) = @_;
  return 'never issued' unless $f;
  return 'still pending' unless $f->is_ready;
  return 'cancelled' if $f->is_cancelled;
  return $f->is_done ? [ $f->get ] : scalar $f->failure;
}

sub wire { return [ grep { /^(?:send|result):/ } @LOG ] }

# ---------------------------------------------------------------------------
# 0. What runs for real: the fake transport takes nothing of the query path.
# ---------------------------------------------------------------------------

for my $seam (qw(_submit_query _collect_result _txn_commit_rolled_back)) {
  is(FakeQueue::Transport->can($seam), DBIO::PostgreSQL::Storage::Async->can($seam),
    "the fake transport does not override $seam -- this dist's runs");
}
for my $method (qw(_query_async_pinned _await_query_result)) {
  is(FakeQueue::Transport->can($method), DBIO::Async::Storage->can($method),
    "the fake transport does not override $method -- the base's runs");
}

# ---------------------------------------------------------------------------
# 1 + 2. Two unchained statements, one readable event at a time. The first
#        statement's result takes two reads.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  %READS = (first => 2);

  my %st;
  my $f = unchained_txn($s, \%st, 'first', 'second');
  answer();   # BEGIN's answer: the block runs and issues both statements

  my @issued = qw( send:BEGIN result:BEGIN send:first );
  is_deeply \@LOG, \@issued,
    'both statements issued: only the first has reached _submit_query';
  ok $st{second} && !$st{second}->is_ready,
    '... the second has its Future, pending';
  is handle_on($st{conn}), 'first',
    '... and the handle on the connection is the first statement\'s';

  answer();   # the first part of the first statement's result
  is_deeply \@LOG, \@issued,
    'the first\'s result has not fully arrived: the second still waits';
  is handle_on($st{conn}), 'first',
    '... and the handle is still the first\'s, through the re-poll';

  answer();   # the rest of it
  is_deeply \@LOG, [ @issued, qw( result:first settled:first send:second ) ],
    'the first settled and its caller saw it: now the second is sent';
  is_deeply rows_of($st{first}), [ [ 'first' ] ],
    '... the first resolved with its own rows';
  is handle_on($st{conn}), 'second',
    '... and the handle on the connection is now the second\'s';

  answer();   # the second statement's answer
  is_deeply rows_of($st{second}), [ [ 'second' ] ],
    'the second resolves with its own rows';

  answer();   # COMMIT's answer
  ok $f->is_ready, 'the transaction ends -- it does not hang';
  ok $f->is_ready && $f->is_done, '... committed'
    or diag 'it ' . ($f->is_ready ? 'failed: ' . $f->failure : 'is still pending');
  is $f->is_ready && $f->is_done ? scalar $f->get : undef, 'block result',
    '... and resolves with the block\'s value';
  is_deeply wire(), [qw(
    send:BEGIN  result:BEGIN
    send:first  result:first
    send:second result:second
    send:COMMIT result:COMMIT
  )], '... one statement at a time, in issue order, COMMIT last';
  is_deeply \@CLEARED, [],
    'no statement handle was dropped while its statement was in flight';

  is $s->pool->size, 1, 'the pool still has its one connection';
  is $s->pool->available, 1, '... back in the pool, idle';
  my $next = $s->_query_async('SELECT "x" FROM "next"', []);
  is $LOG[-1], 'send:next',
    '... and the next pooled statement goes out on it at once';
  answer();
  is_deeply rows_of($next), [ [ 'next' ] ], '... and resolves';
}

# ---------------------------------------------------------------------------
# 3. A statement fails.
# ---------------------------------------------------------------------------

my $NO_RELATION = qr/relation "bad" does not exist/;

{
  my $s = fresh();
  my %st;
  my $f = drain(unchained_txn($s, \%st, 'bad', 'second'));

  ok $f->is_ready, 'the first fails: the transaction ends -- it does not hang';
  ok $f->is_ready && $f->is_failed, '... failed';
  like rows_of($f), $NO_RELATION, '... with the statement\'s own error';
  ok $st{second} && $st{second}->is_cancelled,
    '... the second, waiting for its turn, was cancelled (needs_all)';
  is_deeply wire(), [qw(
    send:BEGIN    result:BEGIN
    send:bad      result:bad
    send:ROLLBACK result:ROLLBACK
  )], '... and never sent: ROLLBACK follows the failed statement';
  is_deeply \@CLEARED, [], '... no handle dropped in flight';
  is $s->pool->available, 1, '... the connection is back in the pool, idle';
}

{
  my $s = fresh();
  my %st;
  my $f = drain(unchained_txn($s, \%st, 'first', 'bad'));

  ok $f->is_ready, 'the second fails: the transaction ends -- it does not hang';
  ok $f->is_ready && $f->is_failed, '... failed';
  like rows_of($f), $NO_RELATION, '... with the statement\'s own error';
  is_deeply rows_of($st{first}), [ [ 'first' ] ],
    '... the first had resolved with its rows';
  is_deeply wire(), [qw(
    send:BEGIN    result:BEGIN
    send:first    result:first
    send:bad      result:bad
    send:ROLLBACK result:ROLLBACK
  )], '... each statement sent after the one before it was answered';
  is_deeply \@CLEARED, [], '... no handle dropped in flight';
  is $s->pool->available, 1, '... the connection is back in the pool, idle';
}

# ---------------------------------------------------------------------------
# 4. Counter-check: the same transaction without the base's queue.
# ---------------------------------------------------------------------------

{
  my $s = fresh('FakeQueue::Unqueued');
  my %st;
  my $f = unchained_txn($s, \%st, 'first', 'second');
  answer();   # BEGIN's answer

  is_deeply \@LOG, [qw( send:BEGIN result:BEGIN send:first send:second )],
    'unqueued: the second statement goes onto the connection while the first '
    . 'is in flight';
  is_deeply \@CLEARED, [ 'first' ],
    '... and the first statement\'s handle is dropped in flight';

  drain($f);
  ok !($f->is_ready && $f->is_done), '... the transaction does not commit';
  ok !(grep { $_ eq 'send:COMMIT' } @LOG), '... no COMMIT is sent';
}

done_testing;
