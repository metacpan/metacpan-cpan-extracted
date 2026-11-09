use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k236. PostgreSQL does not answer a COMMIT in an aborted transaction with
# an error: it ends the transaction and answers with the command tag ROLLBACK.
# Nothing is committed, and nothing on the client side fails. txn_do_async
# decided COMMIT on one thing only -- the coderef's result -- so a statement
# that failed where the coderef did not wait for it (an unchained
# $ctx->insert_async, possible since dbio-postgresql-ev k48) left the
# transaction aborted on the server while txn_do_async went on to send COMMIT
# and resolved as if it had committed: silent data loss.
#
# The claims this file pins (ADR 0055, addendum 2026-09-27):
#
#   (a) Before COMMIT, the transaction waits until every statement Future its
#       context handed out has settled. If any of them failed -- awaited or
#       not, handled by the coderef or not -- COMMIT is not sent: ROLLBACK is,
#       and the transaction fails with the error of the first statement that
#       failed, in the order they were issued.
#   (b) A transport can say that a COMMIT which succeeded on the wire was in
#       truth a rollback (_txn_commit_rolled_back). Then the transaction fails,
#       and no ROLLBACK follows: the server has already ended it.
#
# The fixture is a fake wire with PostgreSQL's transaction semantics, as far as
# the claims need them: a statement that fails aborts the transaction, every
# statement after it fails with "current transaction is aborted", and a COMMIT
# in an aborted transaction ends it with the tag ROLLBACK and does NOT fail --
# it resolves like any COMMIT, as DBD::Pg and EV::Pg resolve it. The pool is a
# real DBIO::Storage::PoolBase of size 1 that records, for every release,
# whether the connection was still inside a transaction.

# --- A connection whose transaction state the fake wire drives --------------
{
  package K236::Conn;
  sub new { bless { id => $_[1], in_txn => 0, aborted => 0 }, $_[0] }
}

# --- A real PoolBase (size 1) that records the state of each release --------
{
  package K236::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection { K236::Conn->new(++$_[0]->{_next_id}) }

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} },
      { conn => $conn->{id}, in_txn => $conn->{in_txn} };
    return $self->SUPER::release($conn);
  }
}

# --- The async backend: real txn_do_async, fake PostgreSQL-like wire --------
# Leaves _txn_commit_rolled_back at core's default: a transport that cannot
# read the COMMIT's tag. Claim (a) has to hold on it.
{
  package K236::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }

  sub pool {
    return $_[0]->{pool} ||= K236::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => 'DBIO::Test::Future',
    );
  }

  # With {hold} set, an INSERT is not answered until the test calls
  # answer_held: it is still in flight when the coderef returns.
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, $sql;
    my $f = $self->future_class->new;
    if ($self->{hold} && $sql =~ /^INSERT/) {
      push @{ $self->{held} }, [ $f, $conn, $sql, $bind ];
      return $f;
    }
    return $self->_answer($f, $conn, $sql, $bind);
  }

  sub _answer {
    my ($self, $f, $conn, $sql, $bind) = @_;

    if ($sql eq 'BEGIN') {
      @$conn{qw(in_txn aborted)} = (1, 0);
      return $f->done;
    }
    if ($sql eq 'ROLLBACK') {
      @$conn{qw(in_txn aborted tag)} = (0, 0, 'ROLLBACK');
      return $f->done;
    }
    if ($sql eq 'COMMIT') {
      # PostgreSQL: no error. The tag says what happened, and only the tag.
      $conn->{tag} = $conn->{aborted} ? 'ROLLBACK' : 'COMMIT';
      push @{ $self->{commit_tags} }, $conn->{tag};
      @$conn{qw(in_txn aborted)} = (0, 0);
      return $f->done('');
    }

    return $f->fail(
      "ERROR:  current transaction is aborted, commands ignored until end of "
    . "transaction block\n"
    ) if $conn->{aborted};

    my @values = map { ref $_ eq 'ARRAY' ? $_->[-1] : $_ } @{ $bind || [] };
    if (grep { defined && $_ eq 'Duplicate' } @values) {
      $conn->{aborted} = 1;
      return $f->fail(
        qq{ERROR:  duplicate key value violates unique constraint "artist_name_key"\n}
      );
    }

    return $f->done({ artistid => ++$self->{next_id} }) if $sql =~ /^INSERT/;
    return $f->done;
  }

  sub _pipeline_enter { push @{ $_[0]->{captured} }, 'PIPELINE_ENTER'; 1 }
  sub _pipeline_exit  { push @{ $_[0]->{captured} }, 'PIPELINE_EXIT';  1 }
  sub _pipeline_sync {
    push @{ $_[0]->{captured} }, 'PIPELINE_SYNC';
    return $_[0]->future_class->done;
  }
}

# --- The same wire, with the transport seam filled as a PostgreSQL driver ----
# fills it: the COMMIT rolled back when the connection's last command tag says
# ROLLBACK (EV::Pg: result_meta->{cmd_status}; DBD::Pg: pg_cmd_status).
{
  package K236::PgBackend;
  use base 'K236::Backend';

  sub _txn_commit_rolled_back {
    my ($self, $conn) = @_;
    return (($conn->{tag} // '') eq 'ROLLBACK') ? 1 : 0;
  }
}

# Wire the backend to an owning sync storage and a shared context-owner token,
# as t/test/39_async_txn_unblessed_return.t does.
sub new_backend {
  my ($class) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $backend = ($class || 'K236::Backend')->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{captured} = [];
  return $backend;
}

sub answer_held {
  my ($backend) = @_;
  while (my $held = shift @{ $backend->{held} }) {
    $backend->_answer(@$held);
  }
}

sub verbs { [ map { /^(\w+)/ ? $1 : $_ } @{ $_[0]->{captured} } ] }

# (value, error) of a settled Future, without a failure aborting the file.
sub outcome {
  my ($f) = @_;
  my $value;
  return ($value, undef) if eval { $value = $f->get; 1 };
  return (undef, "$@");
}

sub connection_is_clean {
  my ($backend, $label) = @_;
  is_deeply $backend->pool->{release_log}, [ { conn => 1, in_txn => 0 } ],
    "$label: the connection was released once, outside a transaction";
}

my $DUPLICATE = qr/duplicate key value violates unique constraint/;
my $ABORTED   = qr/current transaction is aborted/;

# ---------------------------------------------------------------------------
# Unawaited statements, one of which fails. The coderef issues three inserts,
# awaits none of them and returns a plain value. The second fails and aborts
# the transaction, the third fails because of it. Asserts: ROLLBACK is sent,
# COMMIT is not; txn_do_async fails with the error of the statement that broke
# the transaction -- the duplicate key, not the "current transaction is
# aborted" that follows from it; the connection comes back clean. Before the
# fix: COMMIT was sent, the wire answered it with ROLLBACK, and txn_do_async
# resolved with 'queued'.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx->insert_async('artist', { name => 'Miles Davis' });
    $ctx->insert_async('artist', { name => 'Duplicate' });
    $ctx->insert_async('artist', { name => 'John Coltrane' });
    return 'queued';
  });

  my ($got, $error) = outcome($f);
  ok defined $error, 'unawaited failure: txn_do_async fails';
  like $error, $DUPLICATE,
    'unawaited failure: with the error of the statement that failed first';
  unlike $error, $ABORTED,
    'unawaited failure: not with the error that statement caused later';
  is_deeply verbs($backend), [ qw(BEGIN INSERT INSERT INSERT ROLLBACK) ],
    'unawaited failure: ROLLBACK is sent, COMMIT is not';
  connection_is_clean($backend, 'unawaited failure');
}

# ---------------------------------------------------------------------------
# An unawaited statement still in flight when the coderef's result is in.
# Asserts: nothing further goes out on the connection -- in particular no
# COMMIT -- and the transaction does not settle while the statement has no
# answer; once it fails, ROLLBACK goes out and the transaction fails with its
# error. Before the fix COMMIT was sent at once, overtaking the statement, and
# the transaction resolved before the statement was answered.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  $backend->{hold} = 1;
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx->insert_async('artist', { name => 'Duplicate' });
    return 'queued';
  });

  is_deeply verbs($backend), [ qw(BEGIN INSERT) ],
    'in flight: no COMMIT while a statement of the transaction is unanswered';
  ok !$f->is_ready,
    'in flight: the transaction does not settle before its statement does';

  answer_held($backend);
  my (undef, $error) = outcome($f);
  like $error, $DUPLICATE,
    'in flight, then failed: txn_do_async fails with the statement\'s error';
  is_deeply verbs($backend), [ qw(BEGIN INSERT ROLLBACK) ],
    'in flight, then failed: ROLLBACK is sent once it has failed, COMMIT never';
  connection_is_clean($backend, 'in flight, then failed');
}

# ---------------------------------------------------------------------------
# The same, with a statement that succeeds. Asserts: COMMIT is held back only
# until the statement is answered, then sent, and the transaction resolves
# with the coderef's value. Before the fix COMMIT overtook the statement.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  $backend->{hold} = 1;
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx->insert_async('artist', { name => 'Miles Davis' });
    return 'queued';
  });

  is_deeply verbs($backend), [ qw(BEGIN INSERT) ],
    'in flight, then ok: COMMIT waits for the statement';
  answer_held($backend);
  my ($got, $error) = outcome($f);
  is $error, undef, 'in flight, then ok: txn_do_async succeeds';
  is $got, 'queued', 'in flight, then ok: with the coderef\'s value';
  is_deeply verbs($backend), [ qw(BEGIN INSERT COMMIT) ],
    'in flight, then ok: COMMIT is sent after the statement was answered';
  connection_is_clean($backend, 'in flight, then ok');
}

# ---------------------------------------------------------------------------
# An awaited failure the coderef handles: it catches the failed statement's
# Future and returns normally. The pinned semantics: the transaction still
# fails, with that statement's error, and ROLLBACK is sent. On PostgreSQL the
# server has aborted the transaction at that point, so a COMMIT could only roll
# back; the async layer has no savepoint that would make "carry on after a
# failed statement" mean anything, and the rule is the same on every engine.
# Before the fix: COMMIT was sent and the transaction resolved 'recovered'.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->insert_async('artist', { name => 'Duplicate' })
      ->catch(sub { return 'recovered' });
  });

  my ($got, $error) = outcome($f);
  like $error, $DUPLICATE,
    'handled failure: txn_do_async still fails, with the statement\'s error';
  is_deeply verbs($backend), [ qw(BEGIN INSERT ROLLBACK) ],
    'handled failure: ROLLBACK is sent, COMMIT is not';
  connection_is_clean($backend, 'handled failure');
}

# ---------------------------------------------------------------------------
# A transaction whose statements all succeed -- awaited, chained and one left
# unawaited. The regression guard for the fix (this passed before it too):
# COMMIT is sent after every statement, the transaction resolves with the
# coderef's value, and the connection comes back clean.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx->insert_async('artist', { name => 'Miles Davis' });
    return $ctx->insert_async('artist', { name => 'John Coltrane' })
      ->then(sub {
        my ($row) = @_;
        return $ctx->update_async('artist', { rank => 1 },
          { artistid => $row->{artistid} })->then(sub { 'all in' });
      });
  });

  my ($got, $error) = outcome($f);
  is $error, undef, 'all succeed: txn_do_async succeeds';
  is $got, 'all in', 'all succeed: with the coderef\'s value';
  is_deeply verbs($backend), [ qw(BEGIN INSERT INSERT UPDATE COMMIT) ],
    'all succeed: COMMIT is sent after the work';
  is_deeply $backend->{commit_tags}, [ 'COMMIT' ],
    'all succeed: and the wire really committed';
  connection_is_clean($backend, 'all succeed');
}

# ---------------------------------------------------------------------------
# A pipeline on the transaction whose Future nobody awaits. The context hands
# the pipeline's Future out like any statement's. Asserts: its failure fails
# the transaction and ROLLBACK is sent. Before the fix: COMMIT, answered with
# ROLLBACK, and success.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx->pipeline(sub {
      my ($batch) = @_;
      return $batch->future_class->needs_all(
        $batch->insert_async('artist', { name => 'Duplicate' }),
      );
    });
    return 'queued';
  });

  my (undef, $error) = outcome($f);
  like $error, $DUPLICATE,
    'unawaited pipeline: txn_do_async fails with the batch\'s error';
  is verbs($backend)->[-1], 'ROLLBACK',
    'unawaited pipeline: the transaction ends with ROLLBACK';
  ok !(grep { $_ eq 'COMMIT' } @{ verbs($backend) }),
    'unawaited pipeline: COMMIT is not sent';
  # The failed batch marked the connection unusable; the boundary retired it
  # instead of releasing it (karr k396).
  is_deeply $backend->pool->{release_log} // [], [],
    'unawaited pipeline: the connection was not released';
  is $backend->pool->size, 0,
    'unawaited pipeline: it was retired, the pool no longer counts it';
}

# ---------------------------------------------------------------------------
# A context-bound resultset (ADR 0045) routes its statements through the
# context, so they are handed out -- and tracked -- like the context's own.
# Asserts: a create_async on it that nobody awaits fails the transaction, and
# ROLLBACK is sent. Before the fix: COMMIT and success.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  my $schema  = $backend->{_test_schema_guard};
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    $schema->resultset('Artist')->with_context($ctx)
      ->create_async({ name => 'Duplicate' });
    return 'queued';
  });

  my (undef, $error) = outcome($f);
  like $error, $DUPLICATE,
    'bound resultset: txn_do_async fails with the statement\'s error';
  is_deeply verbs($backend), [ qw(BEGIN INSERT ROLLBACK) ],
    'bound resultset: ROLLBACK is sent, COMMIT is not';
  connection_is_clean($backend, 'bound resultset');
}

# ---------------------------------------------------------------------------
# (b) The transport seam. Core's default answers false: a transport that does
# not fill it is taken at the COMMIT's word.
# ---------------------------------------------------------------------------
{
  my $seam = DBIO::Storage::Async->can('_txn_commit_rolled_back');
  ok $seam, 'the storage has the _txn_commit_rolled_back seam';
  ok $seam && !DBIO::Storage::Async->$seam(K236::Conn->new(1), ''),
    'its default answers false';
}

# ---------------------------------------------------------------------------
# (b) A statement the context never handed out: a pipeline batch that drops
# its own statement's failure and resolves normally. The transaction's context
# sees only the pipeline's Future, which succeeded, so (a) cannot see this;
# the server aborted the transaction all the same, and answers COMMIT with the
# tag ROLLBACK. Asserts, on a transport that reads the tag: txn_do_async fails,
# saying the server rolled back instead of committing; no ROLLBACK follows the
# COMMIT; the connection comes back clean. Before the fix: success.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend('K236::PgBackend');
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->pipeline(sub {
      my ($batch) = @_;
      $batch->insert_async('artist', { name => 'Duplicate' });
      return 'batch sent';
    });
  });

  my ($got, $error) = outcome($f);
  ok defined $error, 'COMMIT answered by ROLLBACK: txn_do_async fails';
  like $error, qr/COMMIT.*ROLLBACK/s,
    'COMMIT answered by ROLLBACK: the error says the server rolled back';
  is_deeply $backend->{commit_tags}, [ 'ROLLBACK' ],
    'COMMIT answered by ROLLBACK: (the wire did roll back)';
  is verbs($backend)->[-1], 'COMMIT',
    'COMMIT answered by ROLLBACK: no ROLLBACK is sent after it';
  connection_is_clean($backend, 'COMMIT answered by ROLLBACK');
}

# ---------------------------------------------------------------------------
# (b) does not misfire: on the same transport a transaction that commits is
# answered with the tag COMMIT and resolves normally.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend('K236::PgBackend');
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->insert_async('artist', { name => 'Miles Davis' })
      ->then(sub { 'committed' });
  });

  my ($got, $error) = outcome($f);
  is $error, undef, 'COMMIT answered by COMMIT: txn_do_async succeeds';
  is $got, 'committed', 'COMMIT answered by COMMIT: with the coderef\'s value';
  connection_is_clean($backend, 'COMMIT answered by COMMIT');
}

# ---------------------------------------------------------------------------
# A statement Future that is cancelled -- Future.pm's wait_any cancels the
# statement that lost a race against a timeout. A cancelled Future runs no
# then/catch callback, so a transaction waiting for it through those alone
# would wait for ever and hold its connection. Asserts, over real Future.pm,
# cancelled before and while the transaction waits: the transaction settles;
# it fails, saying a statement was cancelled before it was answered; ROLLBACK
# is sent, COMMIT is not. Before the fix: COMMIT and success.
# ---------------------------------------------------------------------------
SKIP: {
  skip 'Future not installed', 12 unless eval { require Future; 1 };

  {
    package K236::FutureBackend;
    use base 'K236::Backend';
    sub future_class { 'Future' }
    sub pool {
      return $_[0]->{pool} ||= K236::Pool->new(
        conninfo     => 'fake',
        size         => 1,
        future_class => 'Future',
      );
    }
  }

  for my $when (qw(before while)) {
    my $backend = new_backend('K236::FutureBackend');
    $backend->{hold} = 1;
    my $statement;
    my $f = $backend->txn_do_async(sub {
      my ($ctx) = @_;
      $statement = $ctx->insert_async('artist', { name => 'Miles Davis' });
      $statement->cancel if $when eq 'before';
      return 'gave up';
    });
    $statement->cancel if $when eq 'while';

    ok $f->is_ready, "cancelled $when waiting: the transaction settles";
    my (undef, $error) = outcome($f);
    like $error, qr/cancelled before it was answered/,
      "cancelled $when waiting: it fails, naming the cancelled statement";
    is_deeply verbs($backend), [ qw(BEGIN INSERT ROLLBACK) ],
      "cancelled $when waiting: ROLLBACK is sent, COMMIT is not";
    is_deeply $backend->pool->{release_log}, [ { conn => 1, in_txn => 0 } ],
      "cancelled $when waiting: the connection was released once, outside a "
    . 'transaction';
    answer_held($backend);   # the wire's late answer changes nothing
    is_deeply verbs($backend), [ qw(BEGIN INSERT ROLLBACK) ],
      "cancelled $when waiting: a late answer sends nothing more";
    ok $f->is_failed, "cancelled $when waiting: and the transaction stays failed";
  }
}

# ---------------------------------------------------------------------------
# The immediate mode (ADR 0055): the context is the storage, every *_async runs
# in-process inside a synchronous txn_do. The same claims hold there: a failed
# statement Future the coderef drops, or catches and recovers from, fails the
# transaction with that statement's error and rolls it back.
# ---------------------------------------------------------------------------
{
  no warnings 'redefine';
  my $execute = \&DBIO::Test::Storage::_execute;
  local *DBIO::Test::Storage::_execute = sub {
    my ($self, $op, $ident, @args) = @_;
    die qq{ERROR:  duplicate key value violates unique constraint "artist_name_key"\n}
      if $op eq 'insert' && ($args[0]{name} // '') eq 'Duplicate';
    return $self->$execute($op, $ident, @args);
  };

  for my $case (
    [ unawaited => sub {
        my ($ctx, $source) = @_;
        $ctx->insert_async($source, { name => 'Duplicate' });
        return 'queued';
      } ],
    [ handled => sub {
        my ($ctx, $source) = @_;
        return $ctx->insert_async($source, { name => 'Duplicate' })
          ->catch(sub { return 'recovered' });
      } ],
  ) {
    my ($label, $coderef) = @$case;
    my $schema  = DBIO::Test->init_schema;
    my $storage = $schema->storage;
    is $storage->_async_mode, 'immediate', "immediate, $label: mock storage mode";
    $storage->reset_captured;

    my $f = $storage->txn_do_async($coderef, $schema->source('Artist'));
    my (undef, $error) = outcome($f);
    like $error, $DUPLICATE,
      "immediate, $label: txn_do_async fails with the statement's error";
    my @txn = grep { /^(?:BEGIN|COMMIT|ROLLBACK)$/ }
      map { $_->{sql} } $storage->captured_queries;
    is_deeply \@txn, [ qw(BEGIN ROLLBACK) ],
      "immediate, $label: ROLLBACK, not COMMIT";
  }
}

done_testing;
