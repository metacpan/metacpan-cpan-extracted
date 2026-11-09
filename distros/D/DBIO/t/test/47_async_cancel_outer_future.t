use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k270. Core promises that every path after an acquire hands the
# connection back exactly once, and that a transaction is ended before its
# connection goes back to the pool (txn_do_async, pipeline, deploy_async; karr
# k229, k231, k237). Every one of those endings hangs off a ->then: the
# transaction's finalizer, the pipeline's finish step, the release of a DDL
# run. Future.pm runs no ->then callback of a Future that is cancelled -- and
# cancelling the Future a caller was given, or losing it in a wait_any against
# a timeout, is the only way a caller has to stop waiting. No test in the family
# cancelled that outer Future; only a single statement inside a transaction
# (t/test/42_async_txn_failed_statement.t).
#
# What this file pins:
#
#   A. Holds today. A cancel that arrives before the operation has a
#      connection -- queued for one, or waiting for one to come up -- costs
#      nothing: no statement is sent, the coderef never runs, and the
#      connection goes to the next caller (the pool's k256 and k258, here
#      through the three entry points). And a cancel that arrives after a
#      pipeline's bracket has handed its connection back does not hand it back
#      again.
#   B. A cancel while the operation holds its connection -- BEGIN, a statement,
#      COMMIT or ROLLBACK in flight, or the transaction's coderef waiting for a
#      Future of its own; a pipeline's sync in flight; a DDL statement in
#      flight (karr k274). Future.pm runs none of the ->then callbacks that
#      end the operation, so the cancel is answered on its own: ROLLBACK goes
#      out best-effort and is not waited for (not where COMMIT or ROLLBACK is
#      out already, nor in a pipeline or outside a transaction), the context
#      is invalidated, and the connection is RETIRED -- never released into the
#      pool: what is in flight on it cannot be vouched for. Exactly once, and
#      the slot goes to a fresh connection. The cancel still reaches the
#      statement in flight. A cancel while COMMIT is pending leaves the
#      outcome unknown.
#   C. The coderef's own Future cancelled by itself, the transaction's Future
#      not (dbio-postgresql-ev k70): the same ending, and the transaction
#      fails instead of staying pending.
#   D. A connection the pool was told is dead gets no ROLLBACK (dbio-async
#      k47): the transaction fails with the error that ended it, not with
#      "Rollback failed: not sent", and the connection is retired.
#
# Cancelling takes a Future class that can be cancelled: Future.pm. A
# DBIO::Test::Future cannot be, so nothing here runs against it.
#
# The fixture: the real txn_do_async / pipeline / deploy_async over a fake wire
# that holds chosen statements unanswered until the test answers them, and a
# real DBIO::Storage::PoolBase of size 1 that records every release (with the
# state the connection came back in) and every close. The wire keeps the
# server's side on the connection object -- BEGIN opens a transaction when it
# is answered, whether or not the client still waits for the answer.

ok !DBIO::Test::Future->can('cancel'),
  'a DBIO::Test::Future cannot be cancelled: the cancel cases need Future.pm';

unless (eval { require Future; 1 }) {
  SKIP: { skip 'Future not installed: nothing can cancel a Future', 1 }
  done_testing;
  exit;
}

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

{
  package K270C::Conn;
  sub new { my ($class, %args) = @_; bless { in_txn => 0, in_pipeline => 0, %args }, $class }
  sub fire_connect { $_[0]{on_connect}->() }
}

# --- A real PoolBase (size 1) recording each release and each close ---------
{
  package K270C::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection { K270C::Conn->new(id => ++$_[0]{n}) }

  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]{id} }

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, {
      conn        => $conn->{id},
      in_txn      => $conn->{in_txn},
      in_pipeline => $conn->{in_pipeline},
    };
    return $self->SUPER::release($conn);
  }
}

# --- The same, with connections that come up when the test says so ----------
{
  package K270C::ColdPool;
  use base 'K270C::Pool';

  sub _create_connection {
    my ($self, $conninfo) = @_;
    return $self->_create_ready_connection(conninfo => $conninfo);
  }

  sub _new_connection {
    my ($self, %args) = @_;
    my $conn = K270C::Conn->new(%args, id => ++$self->{n});
    push @{ $self->{built} }, $conn;
    return $conn;
  }
}

# --- A fake owner sync storage for the deploy cases -------------------------
# {txn}: the engine's DDL is transactional. {outside}: a statement matching it
# cannot run inside a transaction (the per-statement hook of ADR 0026).
{
  package K270C::Owner;
  sub new { my ($class, %args) = @_; bless {%args}, $class }
  sub _use_transactional_ddl { $_[0]{txn} }
  sub _ddl_statement_is_transactional {
    my ($self, $stmt) = @_;
    return 1 unless $self->{outside};
    return $stmt =~ $self->{outside} ? 0 : 1;
  }
}

# --- The async backend: real orchestration, fake wire -----------------------
# {hold}: a statement matching it is not answered until the test calls
# answer_held. {hold_sync}: the same for _pipeline_sync.
{
  package K270C::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'Future' }
  # A transport with a session reset (karr core k398).
  sub _reset_pool_connection { Future->done }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }
  sub _install_ddl     { $_[0]{ddl} }

  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= ($self->{pool_class} || 'K270C::Pool')->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => 'Future',
      on_error     => sub { push @{ $self->{pool_errors} }, $_[0] },
    );
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, $sql;
    my $f = $self->future_class->new;
    return $f->fail("not sent: connection lost\n") if $conn->{dead};
    if ($self->{hold} && $sql =~ $self->{hold}) {
      push @{ $self->{held} }, [ $f, $conn, $sql ];
      return $f;
    }
    return $self->_answer($f, $conn, $sql);
  }

  # The server's answer. It takes effect on the connection whether or not the
  # client still waits: a Future cancelled on the client is settled no further.
  sub _answer {
    my ($self, $f, $conn, $sql) = @_;
    $conn->{in_txn} = 1 if $sql eq 'BEGIN';
    $conn->{in_txn} = 0 if $sql eq 'COMMIT' || $sql eq 'ROLLBACK';
    return $f if $f->is_ready;
    return $f->done($sql =~ /^INSERT/ ? { artistid => 1 } : ());
  }

  sub _pipeline_enter {
    my ($self, $conn) = @_;
    push @{ $self->{captured} }, 'PIPELINE_ENTER';
    $conn->{in_pipeline} = 1;
    return 1;
  }

  sub _pipeline_sync {
    my ($self, $conn) = @_;
    push @{ $self->{captured} }, 'PIPELINE_SYNC';
    my $f = $self->future_class->new;
    if ($self->{hold_sync}) {
      push @{ $self->{held} }, [ $f, $conn, 'PIPELINE_SYNC' ];
      return $f;
    }
    return $f->done;
  }

  sub _pipeline_exit {
    my ($self, $conn) = @_;
    push @{ $self->{captured} }, 'PIPELINE_EXIT';
    $conn->{in_pipeline} = 0;
    return 1;
  }
}

# A backend wired to an owning sync storage and a shared context-owner token,
# as t/test/42_async_txn_failed_statement.t wires it.
sub new_backend {
  my (%knobs) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $backend = K270C::Backend->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{captured} = [];
  $backend->{$_} = $knobs{$_} for keys %knobs;
  return $backend;
}

# A backend for deploy_async: a fake owner answers the transactional-DDL
# questions, as in t/test/19_async_deploy.t.
sub new_deploy_backend {
  my ($owner, %knobs) = @_;
  my $backend = K270C::Backend->new(undef);
  $backend->{_test_owner} = $owner;
  $backend->_owner_storage($owner);
  $backend->{captured} = [];
  $backend->{$_} = $knobs{$_} for keys %knobs;
  return $backend;
}

# The wire answers everything it was holding.
sub answer_held {
  my ($backend) = @_;
  while (my $held = shift @{ $backend->{held} }) {
    $backend->_answer(@$held);
  }
  return;
}

# The same, as a test: a late answer must never die.
sub lives_answering {
  my ($backend) = @_;
  return 1 if eval { answer_held($backend); 1 };
  diag $@;
  return 0;
}

sub verbs { [ map { /^(\w+)/ ? $1 : $_ } @{ $_[0]{captured} } ] }

# Every hand-back the pool has seen: releases with the state the connection
# came back in, and retirements.
sub hand_backs {
  my ($pool) = @_;
  return (
    @{ $pool->{release_log} || [] },
    map { { conn => $_, retired => 1 } } @{ $pool->{closed} || [] },
  );
}

sub resolved { $_[0]->is_ready && !$_[0]->is_failed && !$_[0]->is_cancelled }

# Run one scenario to its end; the only warnings allowed are the two one-time
# notices deploy_async gives about DDL that is not atomic.
sub scenario {
  my ($label, $code) = @_;
  @warnings = ();
  ok eval { $code->($label); 1 }, "$label: ran to its end" or diag $@;
  is_deeply [ grep { !/^(?:non-transactional DDL|split DDL batch) on / } @warnings ], [],
    "$label: nothing warned";
  return;
}

# The three entry points, each started so that it holds its connection with
# something in flight -- unless it never gets that far.
my %START = (
  txn_do_async => sub {
    my ($backend, $ran, $ctx_ref) = @_;
    return $backend->txn_do_async(sub {
      my ($ctx) = @_;
      $$ctx_ref = $ctx if $ctx_ref;
      $$ran++;
      return $ctx->insert_async('artist', { name => 'Miles Davis' });
    });
  },
  pipeline => sub {
    my ($backend, $ran) = @_;
    return $backend->pipeline(sub {
      my ($batch) = @_;
      $$ran++;
      return $batch->insert_async('artist', { name => 'Miles Davis' });
    });
  },
  deploy_async => sub {
    my ($backend, $ran) = @_;
    return $backend->deploy_async(undef);
  },
);

sub backend_for {
  my ($entry, %knobs) = @_;
  return new_backend(%knobs) unless $entry eq 'deploy_async';
  return new_deploy_backend(
    K270C::Owner->new(txn => 0),
    ddl => 'CREATE TABLE artist (id int);',
    %knobs,
  );
}

# ---------------------------------------------------------------------------
# Control: the fixture without a cancel. A held statement that is answered
# lets the transaction commit, and the connection comes back once, outside a
# transaction. What the cancel cases below show is the cancel's doing.
# ---------------------------------------------------------------------------
scenario 'control, no cancel' => sub {
  my $l = shift;
  my $backend = new_backend(hold => qr/^INSERT/);
  my $f = $START{txn_do_async}->($backend, \my $ran);

  ok !$f->is_ready, "$l: the transaction waits for its statement";
  answer_held($backend);
  ok resolved($f), "$l: and resolves once the statement is answered";
  is_deeply verbs($backend), [ qw(BEGIN INSERT COMMIT) ], "$l: after COMMIT";
  is_deeply [ hand_backs($backend->pool) ], [ { conn => 1, in_txn => 0, in_pipeline => 0 } ],
    "$l: the connection was released once, outside a transaction";
};

# ---------------------------------------------------------------------------
# A. Cancelled while queued for a connection. The pool of one is lent out;
# the operation's acquire waits in the queue.
# ---------------------------------------------------------------------------
for my $entry (qw(txn_do_async pipeline deploy_async)) {
  scenario "$entry cancelled while queued for a connection" => sub {
    my $l = shift;
    my $backend = backend_for($entry);
    my $pool = $backend->pool;
    my $lent = $pool->acquire->get;

    my $ran = 0;
    my $f = $START{$entry}->($backend, \$ran);
    ok !$f->is_ready, "$l: it waits for the pool's one connection";
    is scalar @{ $pool->{_waiters} }, 1, "$l: (in the queue)";

    $f->cancel;
    is scalar @{ $pool->{_waiters} }, 0, "$l: the cancel takes it out of the queue";

    $pool->release($lent);
    is $pool->available, 1, "$l: the released connection is idle, not lost to it";
    is $ran, 0, "$l: its coderef never ran" unless $entry eq 'deploy_async';
    is_deeply verbs($backend), [], "$l: nothing was sent";

    my $next = $pool->acquire;
    ok resolved($next), "$l: the next acquire resolves";
  };
}

# ---------------------------------------------------------------------------
# A. Cancelled while the connection it was given is still coming up.
# ---------------------------------------------------------------------------
for my $entry (qw(txn_do_async pipeline deploy_async)) {
  scenario "$entry cancelled while its connection comes up" => sub {
    my $l = shift;
    my $backend = backend_for($entry, pool_class => 'K270C::ColdPool');
    my $pool = $backend->pool;

    my $ran = 0;
    my $f = $START{$entry}->($backend, \$ran);
    ok !$f->is_ready, "$l: it waits for the connection to come up";

    $f->cancel;
    $pool->{built}[0]->fire_connect;

    is $pool->available, 1, "$l: once up, the connection is idle -- not lost with its caller";
    is $ran, 0, "$l: the coderef never ran" unless $entry eq 'deploy_async';
    is_deeply verbs($backend), [], "$l: nothing was sent on it";
    is_deeply [ hand_backs($pool) ], [ { conn => 1, in_txn => 0, in_pipeline => 0 } ],
      "$l: it went back once, clean";

    my $next = $pool->acquire;
    ok resolved($next), "$l: the next acquire resolves";
  };
}

# ---------------------------------------------------------------------------
# A. A pipeline cancelled after its bracket is finished. The sync is answered
# and pipeline mode is left, but a statement of the batch is still open: the
# connection is not handed back before the batch is decided (karr k396). The
# cancel decides it -- the connection is retired, once, and a late answer to
# the statement does nothing.
# ---------------------------------------------------------------------------
scenario 'pipeline cancelled after its bracket is finished' => sub {
  my $l = shift;
  my $backend = new_backend(hold => qr/^INSERT/);
  my $pool = $backend->pool;
  my $f = $START{pipeline}->($backend, \my $ran);

  ok !$f->is_ready, "$l: the pipeline waits for its batch's Future";
  is_deeply verbs($backend), [ qw(PIPELINE_ENTER INSERT PIPELINE_SYNC PIPELINE_EXIT) ],
    "$l: (the bracket is finished)";
  is_deeply [ hand_backs($pool) ], [],
    "$l: the connection is still held while the batch is open";

  $f->cancel;
  ok lives_answering($backend), "$l: a late answer to the batch's statement does not die";

  is_deeply [ hand_backs($pool) ], [ { conn => 1, retired => 1 } ],
    "$l: the cancel retired the connection, once";
  is $pool->size, 0, "$l: the pool no longer counts it";
  is_deeply verbs($backend), [ qw(PIPELINE_ENTER INSERT PIPELINE_SYNC PIPELINE_EXIT) ],
    "$l: and nothing more is sent on it";
};

# ---------------------------------------------------------------------------
# B. Cancelled while the operation holds its connection. One case per point
# at which something is in flight.
#
#   start     -- starts the operation, returns its Future
#   backend   -- the backend, holding what is to stay in flight
#   in_flight -- what the wire has seen when the cancel arrives
#   ended_by  -- the statement that ends what the connection is in the middle
#                of; a way out sends it, or retires the connection. Not given
#                where the ending statement is already out.
#   context   -- 'open': the operation handed its coderef a context that the
#                cancel leaves open (IST) and a way out invalidates; 'ended':
#                COMMIT or ROLLBACK is out, the context has ended already
#   idle_wire -- nothing is in flight on the connection: what the operation
#                waits for is a Future of the coderef's own
# ---------------------------------------------------------------------------
my @in_flight = (
  {
    name      => 'txn_do_async cancelled while BEGIN is in flight',
    backend   => sub { new_backend(hold => qr/^BEGIN/) },
    start     => $START{txn_do_async},
    in_flight => [ qw(BEGIN) ],
    ended_by  => 'ROLLBACK',
  },
  {
    name      => 'txn_do_async cancelled while a statement is in flight',
    backend   => sub { new_backend(hold => qr/^INSERT/) },
    start     => $START{txn_do_async},
    in_flight => [ qw(BEGIN INSERT) ],
    ended_by  => 'ROLLBACK',
    context   => 'open',
  },
  {
    # Nothing is on the wire: the transaction is open and its coderef waits
    # for something that is no statement -- a timer, another service.
    name      => 'txn_do_async cancelled while its coderef waits for a Future of its own',
    backend   => sub { new_backend() },
    start     => sub {
      my ($backend, $ran, $ctx_ref) = @_;
      return $backend->txn_do_async(sub {
        $$ctx_ref = shift;
        $$ran++;
        return $backend->{own} = Future->new;
      });
    },
    in_flight => [ qw(BEGIN) ],
    ended_by  => 'ROLLBACK',
    context   => 'open',
    idle_wire => 1,
  },
  {
    name      => 'txn_do_async cancelled while COMMIT is in flight',
    backend   => sub { new_backend(hold => qr/^COMMIT/) },
    start     => $START{txn_do_async},
    in_flight => [ qw(BEGIN INSERT COMMIT) ],
    context   => 'ended',
  },
  {
    name      => 'txn_do_async cancelled while ROLLBACK is in flight',
    backend   => sub { new_backend(hold => qr/^ROLLBACK/) },
    start     => sub {
      my ($backend, $ran, $ctx_ref) = @_;
      return $backend->txn_do_async(sub {
        $$ctx_ref = shift;
        $$ran++;
        die "the coderef gave up\n";
      });
    },
    in_flight => [ qw(BEGIN ROLLBACK) ],
    context   => 'ended',
  },
  {
    name      => 'pipeline cancelled while its sync is in flight',
    backend   => sub { new_backend(hold_sync => 1) },
    start     => $START{pipeline},
    in_flight => [ qw(PIPELINE_ENTER INSERT PIPELINE_SYNC) ],
    ended_by  => 'PIPELINE_EXIT',
  },
  {
    name      => 'deploy_async cancelled while a DDL statement is in flight (non-transactional engine)',
    backend   => sub {
      new_deploy_backend(
        K270C::Owner->new(txn => 0),
        ddl  => "CREATE TABLE artist (id int);\nCREATE TABLE cd (id int);",
        hold => qr/^CREATE TABLE artist/,
      );
    },
    start     => $START{deploy_async},
    in_flight => [ qw(CREATE) ],
  },
  {
    name      => 'deploy_async cancelled while a DDL statement is in flight (transactional engine)',
    backend   => sub {
      new_deploy_backend(
        K270C::Owner->new(txn => 1),
        ddl  => "CREATE TABLE artist (id int);\nCREATE TABLE cd (id int);",
        hold => qr/^CREATE TABLE cd/,
      );
    },
    start     => $START{deploy_async},
    in_flight => [ qw(BEGIN CREATE CREATE) ],
    ended_by  => 'ROLLBACK',
  },
  {
    # A split batch (ADR 0026 addendum): the first run committed and released,
    # the statement that cannot run in a transaction is in flight on a pooled
    # connection of its own.
    name      => 'deploy_async cancelled while a statement outside the transaction is in flight',
    backend   => sub {
      new_deploy_backend(
        K270C::Owner->new(txn => 1, outside => qr/^ALTER TYPE/),
        ddl  => "CREATE TABLE artist (id int);\nALTER TYPE mood ADD VALUE 'ok';\nCREATE TABLE cd (id int);",
        hold => qr/^ALTER TYPE/,
      );
    },
    start     => $START{deploy_async},
    in_flight => [ qw(BEGIN CREATE COMMIT ALTER) ],
  },
);

for my $case (@in_flight) {
  scenario $case->{name} => sub {
    my $l = shift;
    my $backend = $case->{backend}->();
    my $pool    = $backend->pool;

    my ($ran, $ctx) = (0);
    my $f = $case->{start}->($backend, \$ran, \$ctx);

    ok !$f->is_ready, "$l: the operation is pending";
    is_deeply verbs($backend), $case->{in_flight}, "$l: (the wire has seen @{ $case->{in_flight} })";
    my @before      = hand_backs($pool);
    my $sent_before = scalar @{ $backend->{captured} };
    my @held        = map { $_->[0] } @{ $backend->{held} };

    $f->cancel;
    ok $f->is_cancelled, "$l: the caller's Future is cancelled";
    ok lives_answering($backend), "$l: the wire answering what was in flight does not die";

    my $next       = $pool->acquire;
    my @hand_backs = hand_backs($pool);
    splice @hand_backs, 0, scalar @before;
    my @sent = @{ $backend->{captured} }[ $sent_before .. $#{ $backend->{captured} } ];

    # The cancel still reaches what the operation waits for.
    if ($case->{idle_wire}) {
      is scalar @held, 0, "$l: (no answer was outstanding)";
      ok $backend->{own}->is_cancelled,
        "$l: the cancel reaches the Future the coderef waited for";
    }
    else {
      is scalar @held, 1, "$l: (one answer was outstanding)";
      ok $held[0]->is_cancelled,
        "$l: the cancel reaches the Future of what was in flight";
    }

    # Retired, once -- not released, whatever state it is in.
    is_deeply \@hand_backs, [ { conn => 1, retired => 1 } ],
      "$l: the connection is retired exactly once, and not released";
    is $pool->size, 1, "$l: and its slot is whole";
    ok resolved($next), "$l: the next acquire resolves";
    isnt eval { $next->get->{id} }, 1, "$l: on a fresh connection, not the one cancelled";

    # ROLLBACK once where a transaction was open, nothing otherwise.
    is_deeply \@sent, [ ($case->{ended_by} // '') eq 'ROLLBACK' ? 'ROLLBACK' : () ],
      "$l: " . (($case->{ended_by} // '') eq 'ROLLBACK'
        ? 'one ROLLBACK is sent, not waited for'
        : 'nothing is sent on it (COMMIT or ROLLBACK is out, or no transaction is open)');

    ok !$ctx->in_txn, "$l: the transaction context is invalidated"
      if ($case->{context} // '') =~ /^(?:open|ended)$/;

    $pool->shutdown;
  };
}

# ---------------------------------------------------------------------------
# B, once. The cancel reaches the operation by several ways: the caller's
# Future, the statement in flight below it, the tracked statements the
# transaction waits for. However many notice it, ROLLBACK goes out once and
# the connection is retired once -- also when the caller cancels twice, and
# when the finalizer runs afterwards on a Future that did not stay cancelled.
# ---------------------------------------------------------------------------
scenario 'a cancel noticed on several ways ends the transaction once' => sub {
  my $l = shift;
  my $backend = new_backend(hold => qr/^INSERT/);
  my $pool = $backend->pool;
  my $f = $START{txn_do_async}->($backend, \my $ran, \my $ctx);

  $backend->{held}[0][0]->cancel;     # the statement first (the coderef's Future too)
  $f->cancel;                         # then the whole transaction
  $f->cancel;
  ok lives_answering($backend), "$l: a late answer does not die";

  is_deeply verbs($backend), [ qw(BEGIN INSERT ROLLBACK) ], "$l: one ROLLBACK";
  is_deeply [ hand_backs($pool) ], [ { conn => 1, retired => 1 } ], "$l: one retirement";
  is $pool->size, 0, "$l: the slot is free, a fresh connection comes up on demand";
  ok !$ctx->in_txn, "$l: context invalidated";
};

scenario 'a transaction that ended before the cancel is not retired by it' => sub {
  my $l = shift;
  my $backend = new_backend();
  my $pool = $backend->pool;
  my $f = $START{txn_do_async}->($backend, \my $ran);
  ok resolved($f), "$l: the transaction has committed";
  $f->cancel;
  is_deeply [ hand_backs($pool) ], [ { conn => 1, in_txn => 0, in_pipeline => 0 } ],
    "$l: the cancel of a finished Future hands nothing back again";
  is_deeply verbs($backend), [ qw(BEGIN INSERT COMMIT) ], "$l: and sends nothing";
};

# ---------------------------------------------------------------------------
# C. The coderef's own Future cancelled, the transaction's Future not
# (dbio-postgresql-ev k70).
# ---------------------------------------------------------------------------
for my $kind (qw(statement own)) {
  scenario "the coderef's $kind Future cancelled by itself" => sub {
    my $l = shift;
    my $backend = new_backend($kind eq 'statement' ? (hold => qr/^INSERT/) : ());
    my $pool = $backend->pool;
    my $f = $backend->txn_do_async(sub {
      my ($ctx) = @_;
      $backend->{ctx} = $ctx;
      return $backend->{own} = $kind eq 'statement'
        ? $ctx->insert_async('artist', { name => 'Miles Davis' })
        : Future->new;
    });
    my $ctx = $backend->{ctx};

    # The Future the coderef returned, not the outer one.
    $backend->{own}->cancel;

    ok $f->is_ready, "$l: the transaction does not stay pending";
    ok $f->is_failed && !$f->is_cancelled, "$l: it fails";
    like eval { $f->failure } // '', qr/cancel/i, "$l: naming the cancel";
    ok lives_answering($backend), "$l: a late answer does not die";

    is_deeply verbs($backend), [ 'BEGIN', ($kind eq 'statement' ? 'INSERT' : ()), 'ROLLBACK' ],
      "$l: one ROLLBACK, no COMMIT";
    is_deeply [ hand_backs($pool) ], [ { conn => 1, retired => 1 } ],
      "$l: the connection is retired once, not released";
    ok !$ctx->in_txn, "$l: the context is invalidated";
    my $next = $pool->acquire;
    ok resolved($next), "$l: the next acquire resolves";
    $pool->shutdown;
  };
}

# ---------------------------------------------------------------------------
# D. A connection reported dead (dbio-async k47).
# ---------------------------------------------------------------------------
scenario 'a transaction failing on a connection reported dead sends no ROLLBACK' => sub {
  my $l = shift;
  my $backend = new_backend();
  my $pool = $backend->pool;
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    my $conn = $ctx->txn_conn;
    $conn->{dead} = 1;
    $pool->_mark_connection_dead($conn);
    die "the connection broke\n";
  });

  ok $f->is_failed, "$l: the transaction fails";
  my $err = eval { $f->failure } // '';
  like $err, qr/the connection broke/, "$l: with the error that ended it";
  unlike $err, qr/Rollback failed|not sent/, "$l: not with a ROLLBACK that could not be sent";
  is_deeply verbs($backend), [ 'BEGIN' ], "$l: no ROLLBACK was sent";
  is_deeply $pool->{closed}, [ 1 ], "$l: the connection is retired, once";
  ok resolved($pool->acquire), "$l: the next acquire resolves";
  $pool->shutdown;
};

is_deeply [ grep { !/^(?:non-transactional DDL|split DDL batch) on / } @warnings ], [],
  'nothing warned outside a scenario either';

done_testing;
