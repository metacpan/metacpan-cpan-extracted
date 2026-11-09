use strict;
use warnings;
use Test::More;

# OFFLINE regression for karr k48: a transaction's pinned connection runs its
# statements one after the other, so a coderef that dies -- or ends -- while
# one of its statements is still in flight gets a clean ROLLBACK (or COMMIT)
# and the connection comes back to the pool IDLE. Claim 8 below is karr k53's
# (t/46 runs it live).
#
# WHY: outside pipeline mode libpq runs one statement at a time on a
# connection, and EV::Pg refuses a second one while the first is in flight --
# it croaks "PQsendQueryParams failed: another command is already in
# progress" before it queues anything. A txn_do coderef that did
# `$ctx->insert_async(...); die` (or called a blocking $ctx method, which k44
# refuses) left its INSERT in flight, and core sent ROLLBACK at once: refused.
# txn_do failed with THAT error instead of the coderef's, and the connection
# went back to the pool mid-transaction -- the next call on it failed the same
# way or ran inside the open transaction, and its locks blocked DDL (measured
# live at k44, PostgreSQL 18.6). Two unchained $ctx->*_async in one coderef
# croaked at the second the same way.
#
# What this file claims, through the REAL storage, pool and core transaction
# scaffold over a stand-in EV::Pg:
#   1. a coderef that dies with a statement in flight fails the transaction
#      with the coderef's own error; ROLLBACK goes on the wire after that
#      statement's result; the connection comes back IDLE and the next call
#      runs on it;
#   2. the same for a coderef whose blocking $ctx->insert is refused (k44). The
#      refusal depends on the order this fix keeps: a completion callback sends
#      the next statement before it settles its Future, so the INSERT is in
#      flight when the wait starts. Queued instead, the wait would be left
#      waiting for a statement only sent after it;
#   3. two unchained $ctx->insert_async both run, in order, and COMMIT after
#      both;
#   4. the order is the order they were issued: a statement queued behind the
#      one in flight goes before one a then callback of that one issues;
#   5. nothing issued after core queued the transaction's ROLLBACK -- or
#      COMMIT -- reaches the wire: it would run outside the transaction. On the
#      context core refuses it at once, having ended the context as the
#      statement went out (core k237); on the connection reached past the
#      context this transport refuses it, its Future fails. A statement a then
#      callback issues BEFORE COMMIT is not late: core waits for it (core k236),
#      and it is committed with the transaction;
#   6. a statement EV::Pg refuses at dispatch fails its Future with EV::Pg's
#      error instead of dying out of _query_async_pinned, also when it was
#      queued -- and the statements behind it still run. Its failure fails the
#      transaction (core k236): ROLLBACK, nothing committed;
#   7. a pipeline on the transaction's connection is not serialised: its
#      statements all go on the wire before the sync (control; true before the
#      fix too);
#   8. a COMMIT PostgreSQL answers with the tag ROLLBACK -- a pipeline batch
#      swallowed a statement's error, so core sent COMMIT -- fails the
#      transaction with core's "COMMIT was answered with ROLLBACK", and nothing
#      is committed (karr k53, _txn_commit_rolled_back). A COMMIT answered with
#      COMMIT is taken at its word: 3, 4, 5 and 7 commit under the same
#      result_meta;
#   9. no callback of this transport dies out of EV::Pg.
#
# Before the fix 1-6 fail: the ROLLBACK or the second statement is refused, the
# transaction fails with "another command is already in progress", and the
# connection goes back with a statement in flight; 6's first claim fails
# because the croak escapes. 7 passes before and after: it keeps the queue out
# of pipeline mode. 8 fails before k53: the transaction resolves.
#
# THE ONE SUBSTITUTION is EV::Pg itself, as in t/41: a fake the real pool builds
# through its real, fork-safe constructor. It follows Pg.xs (0.02 and 0.07
# alike) where it matters here: outside pipeline mode a dispatch while a
# statement is in flight croaks with libpq's message; EV::Pg delivers a result
# after the command's last result has been read, so libpq is idle again -- a
# statement may be sent -- inside the callback, while pending_count still
# counts the delivering callback until it returns; result_meta is the command
# tag of the last successful result, set before its callback; in pipeline mode
# statements queue, and their results arrive once a sync follows them. Its
# "server" keeps the transaction status and which inserted rows were
# committed, and does what PostgreSQL does with a failed statement (%FAIL): it
# aborts the transaction, and COMMIT then commits nothing and is answered with
# the tag ROLLBACK.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();

  our @HANDLES;     # every handle made (weak)
  our @COMMITTED;   # names of the rows the server has committed
  our %CROAK;       # SQL substring => message: the next dispatch of such SQL croaks, once
  our %FAIL;        # wire name => message: such a statement fails on the server

  my $PID = 9000;

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      up         => 0,
      queue      => [],   # sent, result not delivered yet (the callback queue)
      busy       => 0,    # libpq has a command in progress (outside pipeline mode)
      pipeline   => 0,
      intrans    => 0,
      rows       => [],   # inserted in the open transaction
      wire       => [],   # what was sent, in order: the SQL's verb, an INSERT's name
      pid        => ++$PID,
    }, $class;
    push @HANDLES, $self;
    Scalar::Util::weaken($HANDLES[-1]);
    Scalar::Util::weaken(my $weak = $self);
    my $t;
    $t = EV::timer(0.001, 0, sub {
      undef $t;
      return unless $weak;
      $weak->{up} = 1;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  sub on_error {
    my $s = shift;
    $s->{on_error} = $_[0] if @_;
    return $s->{on_error};
  }

  sub is_connected       { $_[0]{up} ? 1 : 0 }
  sub pending_count      { scalar @{ $_[0]{queue} } }
  sub backend_pid        { $_[0]{pid} }
  sub socket             { -1 }
  sub result_meta        { $_[0]{meta} }
  # PQTRANS_IDLE 0, _ACTIVE 1, _INTRANS 2, _INERROR 3, _UNKNOWN 4
  sub transaction_status {
    my ($s) = @_;
    return !$s->{up} ? 4 : $s->{busy} ? 1 : !$s->{intrans} ? 0 : $s->{aborted} ? 3 : 2;
  }

  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    Carp::croak('not connected') unless $self->{up};   # REQUIRE_CONN
    for my $key (keys %CROAK) {
      die delete $CROAK{$key} if index($sql, $key) >= 0;
    }
    die "PQsendQueryParams failed: another command is already in progress\n"
      if $self->{busy} && !$self->{pipeline};
    my ($verb) = $sql =~ /^(\w+)/;
    push @{ $self->{wire} }, $verb eq 'INSERT' ? $bind->[-1] : $verb;
    push @{ $self->{queue} }, { sql => $sql, bind => [ @$bind ], cb => $cb };
    $self->{busy} = 1 unless $self->{pipeline};
    $self->_arm;
    return;
  }

  sub enter_pipeline {
    my ($self) = @_;
    die "PQenterPipelineMode failed: cannot enter pipeline mode, connection not idle\n"
      if $self->{busy} || $self->_outstanding;
    $self->{pipeline} = 1;
    return;
  }

  sub exit_pipeline {
    my ($self) = @_;
    die "PQexitPipelineMode failed: cannot exit pipeline mode while busy\n"
      if $self->_outstanding;
    $self->{pipeline} = 0;
    return;
  }

  # Results libpq still waits for: the callback being delivered to has had its
  # result already.
  sub _outstanding {
    my ($self) = @_;
    return scalar grep { !$self->{delivering} || $_ != $self->{delivering} } @{ $self->{queue} };
  }

  sub pipeline_sync {
    my ($self, $cb) = @_;
    push @{ $self->{wire} }, 'SYNC';
    push @{ $self->{queue} }, { sync => 1, cb => $cb };
    $self->_arm;
    return;
  }

  sub finish {
    my ($self) = @_;
    while (my $entry = shift @{ $self->{queue} }) {
      next if $self->{delivering} && $entry == $self->{delivering};
      eval { $entry->{cb}->(undef, 'connection finished'); 1 }
        or warn "EV::Pg: exception in callback during cancel: $@";
    }
    $self->{up} = 0;
    delete $self->{meta};
    return;
  }

  sub _arm {
    my ($self) = @_;
    return if $self->{timer} || !@{ $self->{queue} };
    Scalar::Util::weaken(my $weak = $self);
    $self->{timer} = EV::timer(0.001, 0, sub { $weak->_complete_head if $weak });
    return;
  }

  sub _complete_head {
    my ($self) = @_;
    delete $self->{timer};
    my $head = $self->{queue}[0] or return;
    # In pipeline mode the server answers at the sync.
    return if $self->{pipeline} && !grep { $_->{sync} } @{ $self->{queue} };

    my ($tag, @result) = $head->{sync} ? (undef, 1) : $self->_serve($head->{sql}, $head->{bind});

    # EV::Pg points result_meta at a successful result before it calls back;
    # an error or a sync leaves it alone.
    $self->{meta} = { cmd_status => $tag } if defined $tag;
    # EV::Pg delivers once the command's last result is read: libpq is idle in
    # the callback, the callback still counts in pending_count.
    $self->{busy} = 0 unless $self->{pipeline};
    $self->{delivering} = $head;
    eval { $head->{cb}->(@result); 1 } or warn "EV::Pg: exception in callback: $@";
    delete $self->{delivering};
    shift @{ $self->{queue} } if @{ $self->{queue} } && $self->{queue}[0] == $head;
    $self->_arm;
    return;
  }

  # The server's answer to one statement: its command tag, then what EV::Pg
  # hands the callback -- (undef, undef, $error) for an error. A statement that
  # fails aborts the open transaction; PostgreSQL then refuses everything but
  # its end, and answers COMMIT by rolling back, with the tag ROLLBACK.
  my $ID = 0;
  sub _serve {
    my ($self, $sql, $bind) = @_;
    if ($sql eq 'BEGIN') { $self->{intrans} = 1; return ('BEGIN', '') }
    if ($sql eq 'COMMIT') {
      my $aborted = delete $self->{aborted};
      push @COMMITTED, @{ $self->{rows} } unless $aborted;
      @{ $self->{rows} } = ();
      $self->{intrans} = 0;
      return ($aborted ? 'ROLLBACK' : 'COMMIT', '');
    }
    if ($sql eq 'ROLLBACK') {
      delete $self->{aborted};
      @{ $self->{rows} } = ();
      $self->{intrans} = 0;
      return ('ROLLBACK', '');
    }
    return (undef, undef, "ERROR:  current transaction is aborted, commands ignored until end of transaction block\n")
      if $self->{aborted};
    my ($verb) = $sql =~ /^(\w+)/;
    my $name = $verb eq 'INSERT' ? $bind->[-1] : $verb;
    if (defined(my $err = $FAIL{$name})) {
      $self->{aborted} = 1 if $self->{intrans};
      return (undef, undef, $err);
    }
    if ($verb eq 'INSERT') {
      push @{ $self->{intrans} ? $self->{rows} : \@COMMITTED }, $name;
      return ('INSERT 0 1', [ [ ++$ID, $name ] ]);
    }
    return ('SELECT 1', [ [ 1, 'one' ] ]) if $verb eq 'SELECT';
    return (uc $verb, '');
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use Scalar::Util ();
use DBIO::PostgreSQL::EV::Storage;

# These tests are not about the session reset of a pool connection (karr k99):
# NoSessionReset puts the connection back at once, as before the reset existed.
use FindBin;
use lib "$FindBin::Bin/lib";
use NoSessionReset;

alarm 60;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $EVF = 'DBIO::PostgreSQL::EV::Future';
my $BUSY = qr/another command is already in progress/;

# A real storage and pool over the fake EV::Pg, with a pool of one.
sub pool_of_one {
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { dbname => 'fake', pool_size => 1 }, {} ]);
  return $storage;
}

# Wait for $f on the EV loop: (1, @result) once it is done, (0, $error) once it
# failed. A Future still pending after 5 seconds is failed by the watchdog.
sub wait_for {
  my ($f) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(5, 0, sub { $f->fail("watchdog: still pending after 5s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

# Let every timer the fake still has run out.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub the_conn { $_[0]->pool->{_connections}[0] }

sub insert { $_[0]->insert_async('thing', { name => $_[1] }) }

# A pool of one with its connection spawned, a clean wire and a clean server.
sub fresh {
  my $storage = pool_of_one();
  my ($ok, @r) = wait_for($storage->select_async('thing', ['id'], {}));
  die "warming the pool failed: $r[0]" unless $ok;
  my $conn = the_conn($storage);
  @{ $conn->{wire} } = ();
  @EV::Pg::COMMITTED = ();
  return ($storage, $conn);
}

sub wire { [ @{ $_[0]{wire} } ] }

sub no_callback_died {
  my ($label) = @_;
  my @died = grep { /exception in callback/ } @warnings;
  is scalar @died, 0, "$label: no callback died out of EV::Pg"
    or diag @died;
  @warnings = ();
}

# The connection is back in the pool, IDLE, and the next call runs on it.
sub back_idle {
  my ($label, $storage, $conn) = @_;
  settle();
  is $storage->pool->size, 1, "$label: the pool still has its one connection";
  is $storage->pool->available, 1, "$label: back in the pool";
  is $conn->transaction_status, 0, "$label: IDLE -- no transaction open, nothing in flight";
  is $conn->pending_count, 0, "$label: no result due";

  my ($ok, @r) = wait_for($storage->select_async('thing', ['id'], {}));
  ok $ok, "$label: the next call completes" or diag "it failed: $r[0]";
  is Scalar::Util::refaddr(the_conn($storage)), Scalar::Util::refaddr($conn),
    "$label: on the same connection";
  no_callback_died($label);
}

# --- 1. a coderef dies with a statement in flight ------------------------------

{
  my $label = 'die in flight';
  my ($storage, $conn) = fresh();
  my ($ok, $err) = wait_for($storage->txn_do_async(sub {
    my ($ctx) = @_;
    insert($ctx, 'doomed');
    die "coderef died\n";
  }));
  ok !$ok, "$label: the transaction fails";
  is $err, "coderef died\n", "$label: with the coderef's error, not a libpq refusal";
  is_deeply wire($conn), [qw( BEGIN doomed ROLLBACK )],
    "$label: ROLLBACK went on the wire, after the INSERT";
  is_deeply \@EV::Pg::COMMITTED, [], "$label: the row was not committed";
  back_idle($label, $storage, $conn);
}

# --- 2. a coderef whose blocking $ctx->insert is refused -----------------------

{
  my $label = 'refused blocking insert';
  my ($storage, $conn) = fresh();
  my ($ok, $err) = wait_for($storage->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx->insert('thing', { name => 'blocking' });
    return 'not reached';
  }));
  ok !$ok, "$label: the transaction fails";
  like $err, qr/^Blocking wait refused/, "$label: with the refusal (karr k44)";
  is_deeply wire($conn), [qw( BEGIN blocking ROLLBACK )],
    "$label: ROLLBACK went on the wire, after the INSERT";
  is_deeply \@EV::Pg::COMMITTED, [], "$label: the row was not committed";
  back_idle($label, $storage, $conn);
}

# --- 3. two unchained statements -------------------------------------------------

{
  my $label = 'two unchained';
  my ($storage, $conn) = fresh();
  my ($ok, @r) = wait_for($storage->txn_do_async(sub {
    my ($ctx) = @_;
    my $one = insert($ctx, 'one');
    my $two = insert($ctx, 'two');
    return $EVF->needs_all($one, $two);
  }));
  ok $ok, "$label: the transaction commits" or diag "it failed: $r[0]";
  is_deeply \@r, [ { name => 'one' }, { name => 'two' } ], "$label: with both results";
  is_deeply wire($conn), [qw( BEGIN one two COMMIT )], "$label: both ran, in order, then COMMIT";
  is_deeply \@EV::Pg::COMMITTED, [qw( one two )], "$label: both rows committed";
  back_idle($label, $storage, $conn);
}

# --- 4. issue order is wire order ------------------------------------------------

{
  my $label = 'issue order';
  my ($storage, $conn) = fresh();
  my ($ok, @r) = wait_for($storage->txn_do_async(sub {
    my ($ctx) = @_;
    my $first  = insert($ctx, 'first')->then(sub { insert($ctx, 'third') });
    my $second = insert($ctx, 'second');
    return $EVF->needs_all($first, $second);
  }));
  ok $ok, "$label: the transaction commits" or diag "it failed: $r[0]";
  is_deeply wire($conn), [qw( BEGIN first second third COMMIT )],
    "$label: the queued statement goes before the one first's then callback issued";
  is_deeply \@EV::Pg::COMMITTED, [qw( first second third )], "$label: all committed";
  back_idle($label, $storage, $conn);
}

# --- 5. nothing runs after the transaction's end was queued --------------------

# A statement sent on the transaction's connection past its context.
my $INSERT = 'INSERT INTO thing (name) VALUES (?)';
my $NO_LONGER_ACTIVE = qr/transaction context is no longer active/;

{
  my $label = 'after ROLLBACK';
  my ($storage, $conn) = fresh();
  my ($held, $ctx_err, $past);
  my ($ok, $err) = wait_for($storage->txn_do_async(sub {
    my ($ctx) = @_;
    my $txn_conn = $ctx->txn_conn;
    # Held, not returned: Future keeps a then chain only while someone does.
    $held = insert($ctx, 'early')->then(sub {
      $ctx_err = eval { insert($ctx, 'late'); 1 } ? '' : "$@";
      return $past = $storage->_query_async_pinned($txn_conn, $INSERT, ['past']);
    });
    die "stop\n";
  }));
  ok !$ok, "$label: the transaction fails";
  is $err, "stop\n", "$label: with the coderef's error";
  is_deeply wire($conn), [qw( BEGIN early ROLLBACK )],
    "$label: nothing issued after ROLLBACK was queued reached the wire";
  like $ctx_err, $NO_LONGER_ACTIVE,
    "$label: the context refuses a statement at once -- core ended it as ROLLBACK went out (core k237)";
  ok $past && $past->is_failed, "$label: a statement past the context: its Future failed";
  like $past && $past->is_failed ? $past->failure : '', qr/ROLLBACK has already been issued/,
    "$label: saying why";
  settle();   # a stray statement would have run by now
  is_deeply \@EV::Pg::COMMITTED, [], "$label: nothing committed -- no stray write outside the transaction";
  back_idle($label, $storage, $conn);
}

{
  my $label = 'then before COMMIT';
  my ($storage, $conn) = fresh();
  my ($late, $held);
  my ($ok, @r) = wait_for($storage->txn_do_async(sub {
    my ($ctx) = @_;
    my $a = insert($ctx, 'a');
    $held = insert($ctx, 'b')->then(sub { $late = insert($ctx, 'late') });
    return $a;
  }));
  ok $ok, "$label: the transaction commits" or diag "it failed: $r[0]";
  is_deeply wire($conn), [qw( BEGIN a b late COMMIT )],
    "$label: core waits for b, and for what b's then issued, before COMMIT (core k236)";
  ok $late && $late->is_done, "$label: that statement ran inside the transaction";
  is_deeply \@EV::Pg::COMMITTED, [qw( a b late )], "$label: and was committed with it";
  back_idle($label, $storage, $conn);
}

{
  my $label = 'after COMMIT';
  my ($storage, $conn) = fresh();
  my ($held, $ctx_err, $past);
  my ($ok, @r) = wait_for($storage->txn_do_async(sub {
    my ($ctx) = @_;
    my $txn_conn = $ctx->txn_conn;
    my $a = insert($ctx, 'a');
    # Past the context: core does not wait for it, so COMMIT queues behind it.
    $held = $storage->_query_async_pinned($txn_conn, 'SELECT 1', [])->then(sub {
      $ctx_err = eval { insert($ctx, 'late'); 1 } ? '' : "$@";
      return $past = $storage->_query_async_pinned($txn_conn, $INSERT, ['past']);
    });
    return $a;
  }));
  ok $ok, "$label: the transaction commits" or diag "it failed: $r[0]";
  is_deeply wire($conn), [qw( BEGIN a SELECT COMMIT )],
    "$label: nothing issued after COMMIT was queued reached the wire";
  like $ctx_err, $NO_LONGER_ACTIVE,
    "$label: the context refuses a statement at once -- core ended it as COMMIT went out (core k237)";
  ok $past && $past->is_failed, "$label: a statement past the context: its Future failed";
  like $past && $past->is_failed ? $past->failure : '', qr/COMMIT has already been issued/,
    "$label: saying why";
  settle();   # a stray statement would have run by now
  is_deeply \@EV::Pg::COMMITTED, [qw( a )], "$label: what the transaction ran is committed, nothing else";
  back_idle($label, $storage, $conn);
}

# --- 6. a dispatch EV::Pg refuses ------------------------------------------------

{
  my $label = 'dispatch croak';
  my ($storage, $conn) = fresh();
  local $EV::Pg::CROAK{'SELECT 1'} = "not connected at fake line 1.\n";
  my $f = eval { $storage->_query_async_pinned($conn, 'SELECT 1', []) };
  ok $f, "$label: _query_async_pinned returns a Future" or diag "it died: $@";
  ok $f && $f->is_failed, "$label: a failed one";
  is $f && $f->is_failed ? $f->failure : undef, "not connected\n",
    "$label: with EV::Pg's error";
  back_idle($label, $storage, $conn);
}

{
  my $label = 'queued dispatch croak';
  my ($storage, $conn) = fresh();
  local $EV::Pg::CROAK{croak_me} = "PQsendQueryParams failed: refused\n";
  my ($refused, $after);
  my ($ok, $err) = wait_for($storage->txn_do_async(sub {
    my ($ctx) = @_;
    my $before = insert($ctx, 'before');
    $refused   = $ctx->select_async('croak_me', ['id'], {});
    $after     = insert($ctx, 'after');
    return $EVF->needs_all($before, $after);
  }));
  ok $refused && $refused->is_failed, "$label: the refused statement's Future failed";
  is $refused && $refused->is_failed ? $refused->failure : undef, "PQsendQueryParams failed: refused\n",
    "$label: with EV::Pg's error";
  ok !$ok, "$label: the transaction fails -- a statement of it failed (core k236)";
  is $err, "PQsendQueryParams failed: refused\n", "$label: with that statement's error";
  is_deeply wire($conn), [qw( BEGIN before after ROLLBACK )],
    "$label: the statement behind it still ran; then ROLLBACK";
  is_deeply \@EV::Pg::COMMITTED, [], "$label: nothing committed";
  back_idle($label, $storage, $conn);
}

# --- 7. a pipeline on the transaction's connection (control) -------------------

{
  my $label = 'pipeline in a transaction';
  my ($storage, $conn) = fresh();
  my ($ok, @r) = wait_for($storage->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->pipeline(sub {
      my ($batch) = @_;
      return $batch->future_class->needs_all(map { $batch->insert_async('thing', { name => "p$_" }) } 1 .. 3);
    });
  }));
  ok $ok, "$label: the transaction commits" or diag "it failed: $r[0]";
  is_deeply wire($conn), [qw( BEGIN p1 p2 p3 SYNC COMMIT )],
    "$label: every batched statement went on the wire before the sync";
  is_deeply \@EV::Pg::COMMITTED, [qw( p1 p2 p3 )], "$label: committed";
  back_idle($label, $storage, $conn);
}

# --- 8. a COMMIT answered with ROLLBACK (karr k53) ------------------------------

{
  my $label = 'COMMIT answered with ROLLBACK';
  my ($storage, $conn) = fresh();
  local $EV::Pg::FAIL{bad} = "ERROR:  duplicate key value violates unique constraint\n";
  my $swallowed;
  my ($ok, $err) = wait_for($storage->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->pipeline(sub {
      my ($batch) = @_;
      return $batch->future_class->needs_all(
        $batch->insert_async('thing', { name => 'good' }),
        $batch->insert_async('thing', { name => 'bad' })
          ->else(sub { $swallowed = shift; $batch->future_class->done }),
      );
    });
  }));
  like $swallowed // '', qr/duplicate key/, "$label: the batch swallowed its statement's error";
  ok !$ok, "$label: the transaction fails all the same";
  like $ok ? '' : "$err", qr/COMMIT was answered with ROLLBACK/, "$label: with core's COMMIT-answered error";
  is_deeply wire($conn), [qw( BEGIN good bad SYNC COMMIT )],
    "$label: COMMIT went out -- core never saw the failure -- and nothing after it";
  is_deeply \@EV::Pg::COMMITTED, [], "$label: nothing committed";
  back_idle($label, $storage, $conn);
}

done_testing;
