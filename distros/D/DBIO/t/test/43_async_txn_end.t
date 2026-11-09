use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Storage ();
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k237, found in a dbio-postgresql-ev run against a real server. How an
# async transaction ends -- the ROLLBACK or COMMIT that closes it.
#
# (1) A failed ROLLBACK replaced the error it was cleaning up after. A killed
#     backend fails the transaction's statement with "connection lost"; the
#     ROLLBACK after it fails with "not connected"; the caller saw only "not
#     connected" -- the consequence, never the cause. The synchronous txn_do
#     reports this case as "Transaction aborted: <error>. Rollback failed:
#     <rollback error>" (DBIO::Storage::BlockRunner), and so did the immediate
#     async mode, which runs txn_do underneath; only a real async backend
#     differed. The claim now, on every path that sends ROLLBACK and for a
#     ROLLBACK whose Future fails as well as one whose dispatch throws: the
#     transaction fails with a DBIO::Exception carrying both errors, the
#     original first, in the text txn_do uses -- the same in immediate mode.
#     A ROLLBACK that succeeds still leaves the original error as it was.
#
# (2) The context stayed active until the connection was released, i.e. until
#     COMMIT or ROLLBACK had been answered. A statement issued on it between
#     the send and the answer -- from the then callback of a statement still in
#     flight when the coderef died, say -- went out after the transaction's
#     end, outside it. The claim now: the context refuses every statement from
#     the moment COMMIT or ROLLBACK goes out, and nothing more reaches the
#     wire.
#
# The fixture: a fake wire over a real DBIO::Storage::PoolBase of size 1. Each
# verb can be made to fail its Future, throw at dispatch, or be held
# unanswered until the test answers it.

{
  package K237::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K237::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection { K237::Conn->new(++$_[0]->{_next_id}) }

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, $conn->{id};
    return $self->SUPER::release($conn);
  }
}

{
  package K237::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }

  sub pool {
    return $_[0]->{pool} ||= K237::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => 'DBIO::Test::Future',
    );
  }

  # {throw}{VERB}: dispatching it dies. {hold}{VERB}: it is not answered
  # until answer_held. {fail}{VERB}: its answer is a failure. Every dispatch
  # is captured, a throwing one included.
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    my ($verb) = $sql =~ /^(\w+)/;
    push @{ $self->{captured} }, $verb;
    die $self->{throw}{$verb} if defined $self->{throw}{$verb};
    my $f = $self->future_class->new;
    if ($self->{hold}{$verb}) {
      push @{ $self->{held} }, [ $f, $verb ];
      return $f;
    }
    return $self->_answer($f, $verb);
  }

  sub _answer {
    my ($self, $f, $verb) = @_;
    return $f->fail($self->{fail}{$verb}) if defined $self->{fail}{$verb};
    return $f->done({ artistid => ++$self->{next_id} }) if $verb eq 'INSERT';
    return $f->done;
  }
}

sub new_backend {
  my (%wire) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $backend = K237::Backend->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{captured} = [];
  $backend->{$_} = $wire{$_} for keys %wire;
  return $backend;
}

sub answer_held {
  my ($backend, $verb) = @_;
  my @held = @{ $backend->{held} || [] };
  $backend->{held} = [ grep { $_->[1] ne $verb } @held ];
  $backend->_answer(@$_) for grep { $_->[1] eq $verb } @held;
  return;
}

# (value, error) of a settled Future, the error exactly as the Future failed
# with it: ->get would wrap a plain string into a DBIO::Exception of its own.
sub outcome {
  my ($f) = @_;
  my ($value, $error);
  $f->then(sub { $value = $_[0]; return });
  $f->catch(sub { $error = $_[0]; return });
  return ($value, $error);
}

my $LOST         = "connection lost\n";
my $NOT_CONNECTED = "not connected\n";
my $BOTH = qr/Transaction aborted: connection lost\n\. Rollback failed: not connected/;

# ---------------------------------------------------------------------------
# (1) The run that found it: the killed backend fails the statement, then the
# ROLLBACK. Asserts, for a statement nobody awaited and for one the coderef
# returned: the transaction fails with a DBIO::Exception naming both errors,
# the statement's first, in txn_do's text; ROLLBACK was sent and COMMIT was
# not; the connection went back once. Before the fix the error was
# "not connected" alone.
# ---------------------------------------------------------------------------
for my $case (
  [ unawaited => sub {
      my ($ctx) = @_;
      $ctx->insert_async('artist', { name => 'Miles Davis' });
      return 'queued';
    } ],
  [ returned => sub {
      my ($ctx) = @_;
      return $ctx->insert_async('artist', { name => 'Miles Davis' });
    } ],
) {
  my ($label, $coderef) = @$case;
  my $backend = new_backend(fail => { INSERT => $LOST, ROLLBACK => $NOT_CONNECTED });

  my (undef, $error) = outcome($backend->txn_do_async($coderef));
  isa_ok $error, 'DBIO::Exception', "$label statement, ROLLBACK fails: the error";
  like "$error", $BOTH,
    "$label statement, ROLLBACK fails: it names the statement's error, then the ROLLBACK's";
  is_deeply $backend->{captured}, [ qw(BEGIN INSERT ROLLBACK) ],
    "$label statement, ROLLBACK fails: ROLLBACK was sent, COMMIT was not";
  is_deeply $backend->pool->{release_log} || [], [],
    "$label statement, ROLLBACK fails: the connection is retired, never handed back (karr k395)";
}

# ---------------------------------------------------------------------------
# (1) The coderef's own failure, cleaned up by a ROLLBACK that fails -- its
# Future failing, or its dispatch throwing. Asserts: the coderef's error comes
# first, the ROLLBACK's is named after it, in txn_do's text; txn_do_async
# returns a failed Future in both cases, never throws. Before the fix the
# ROLLBACK's error replaced the coderef's.
# ---------------------------------------------------------------------------
for my $case (
  [ 'coderef dies', sub { die "coderef died\n" } ],
  [ 'coderef Future fails',
    sub { return DBIO::Test::Future->fail("coderef failed\n") } ],
) {
  my ($what, $coderef) = @$case;
  my ($original) = $what eq 'coderef dies' ? 'coderef died' : 'coderef failed';

  for my $rollback (qw(fails throws)) {
    my $label = "$what, ROLLBACK $rollback";
    my $backend = new_backend(
      ($rollback eq 'fails' ? 'fail' : 'throw') => { ROLLBACK => $NOT_CONNECTED },
    );

    my $f = eval { $backend->txn_do_async($coderef) };
    ok $f && $f->is_failed, "$label: txn_do_async returns a failed Future";
    my (undef, $error) = $f ? outcome($f) : (undef, $@);
    isa_ok $error, 'DBIO::Exception', "$label: the error";
    like "$error",
      qr/Transaction aborted: \Q$original\E\n\. Rollback failed: not connected/,
      "$label: it names the coderef's error, then the ROLLBACK's";
    is_deeply $backend->{captured}, [ qw(BEGIN ROLLBACK) ],
      "$label: ROLLBACK was sent, COMMIT was not";
    is_deeply $backend->pool->{release_log} || [], [],
      "$label: the connection is retired, never handed back (karr k395)";
  }
}

# ---------------------------------------------------------------------------
# (1) Control: a ROLLBACK that succeeds leaves the error as it was -- the
# statement's own, not wrapped, nothing about a rollback in it.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend(fail => { INSERT => $LOST });
  my (undef, $error) = outcome($backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->insert_async('artist', { name => 'Miles Davis' });
  }));
  is $error, $LOST, 'ROLLBACK succeeds: the error is the statement\'s, unchanged';
}

# ---------------------------------------------------------------------------
# (1) Parity (ADR 0055): the immediate mode, where the context is the storage
# and txn_do runs underneath, reports the same case in the same words.
# Asserts: the same DBIO::Exception, both errors, the statement's first -- so a
# caller's /Rollback failed/ matches in every mode.
# ---------------------------------------------------------------------------
{
  no warnings 'redefine';
  my $execute = \&DBIO::Test::Storage::_execute;
  local *DBIO::Test::Storage::_execute = sub {
    my ($self, $op, $ident, @args) = @_;
    die $LOST if $op eq 'insert';
    return $self->$execute($op, $ident, @args);
  };
  local *DBIO::Test::Storage::_exec_txn_rollback = sub { die $NOT_CONNECTED };

  my $schema  = DBIO::Test->init_schema;
  my $storage = $schema->storage;
  is $storage->_async_mode, 'immediate', 'immediate: mock storage mode';

  my (undef, $error) = outcome($storage->txn_do_async(sub {
    my ($ctx, $source) = @_;
    $ctx->insert_async($source, { name => 'Miles Davis' });
    return 'queued';
  }, $schema->source('Artist')));
  isa_ok $error, 'DBIO::Exception', 'immediate, ROLLBACK fails: the error';
  like "$error", $BOTH,
    'immediate, ROLLBACK fails: the same words as on a real backend';
}

# ---------------------------------------------------------------------------
# (2) A statement issued while ROLLBACK is on the wire. The coderef issues a
# statement that is still in flight when it dies, and chains a second one
# onto it; ROLLBACK goes out at once (the ROLLBACK path does not wait) and is
# answered after that statement -- a wire that runs one statement at a time,
# as dbio-postgresql-ev's pinned queue does. The first statement is answered,
# and its then callback issues the second while ROLLBACK is still pending.
# Asserts: the context is inactive once ROLLBACK is sent; the second statement
# is refused ("no longer active") and never reaches the wire; the transaction
# then fails with the coderef's error. Before the fix the second statement
# went out behind the ROLLBACK, after the transaction's end.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend(hold => { INSERT => 1, ROLLBACK => 1 });
  my ($ctx, $chained, $late);
  my $f = $backend->txn_do_async(sub {
    ($ctx) = @_;
    $chained = $ctx->insert_async('artist', { name => 'Miles Davis' })
      ->then(sub { $late = $ctx->insert_async('artist', { name => 'Late' }) });
    die "coderef died\n";
  });

  is_deeply $backend->{captured}, [ qw(BEGIN INSERT ROLLBACK) ],
    'after ROLLBACK: ROLLBACK went out with the statement still in flight';
  ok !$ctx->in_txn, 'after ROLLBACK: the context is inactive once ROLLBACK is sent';

  answer_held($backend, 'INSERT');
  ok !defined $late, 'after ROLLBACK: the chained statement was not handed out';
  ok $chained->is_failed, 'after ROLLBACK: the chain failed';
  my (undef, $refusal) = outcome($chained);
  like $refusal, qr/transaction context is no longer active/,
    'after ROLLBACK: refused as a statement on an ended transaction';
  is_deeply $backend->{captured}, [ qw(BEGIN INSERT ROLLBACK) ],
    'after ROLLBACK: nothing more reached the wire';

  ok !$f->is_ready, 'after ROLLBACK: the transaction waits for its answer';
  answer_held($backend, 'ROLLBACK');
  my (undef, $error) = outcome($f);
  is $error, "coderef died\n", 'after ROLLBACK: the transaction fails with the coderef\'s error';
  is_deeply $backend->pool->{release_log}, [ 1 ],
    'after ROLLBACK: the connection went back once';
}

# ---------------------------------------------------------------------------
# (2) A statement issued while COMMIT is on the wire, not yet answered.
# Asserts: the context is inactive once COMMIT is sent; a statement on it --
# CRUD or raw -- is refused and never reaches the wire; COMMIT's answer then
# resolves the transaction with the coderef's value. Before the fix the
# statement went out behind COMMIT, after the transaction's end.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend(hold => { COMMIT => 1 });
  my $ctx;
  my $f = $backend->txn_do_async(sub {
    ($ctx) = @_;
    return $ctx->insert_async('artist', { name => 'Miles Davis' })
      ->then(sub { 'committed' });
  });

  is_deeply $backend->{captured}, [ qw(BEGIN INSERT COMMIT) ],
    'after COMMIT: COMMIT is on the wire, unanswered';
  ok !$f->is_ready, 'after COMMIT: the transaction waits for its answer';
  ok !$ctx->in_txn, 'after COMMIT: the context is inactive once COMMIT is sent';

  eval { $ctx->insert_async('artist', { name => 'Late' }) };
  like $@, qr/transaction context is no longer active/,
    'after COMMIT: a CRUD statement on the context is refused';
  eval { $ctx->_query_async('SELECT 1', []) };
  like $@, qr/transaction context is no longer active/,
    'after COMMIT: a raw statement on the context is refused';
  is_deeply $backend->{captured}, [ qw(BEGIN INSERT COMMIT) ],
    'after COMMIT: nothing more reached the wire';

  answer_held($backend, 'COMMIT');
  my ($got, $error) = outcome($f);
  is $error, undef, 'after COMMIT: the transaction succeeds';
  is $got, 'committed', 'after COMMIT: with the coderef\'s value';
  is_deeply $backend->pool->{release_log}, [ 1 ],
    'after COMMIT: the connection went back once';
}

done_testing;
