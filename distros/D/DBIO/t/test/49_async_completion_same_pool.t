use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr dbio-async k46, "Also found (a)". What ends a piece of work hands its
# connection back to the pool the connection came from.
#
# txn_do_async, pipeline and deploy_async asked the storage for its pool twice:
# once to acquire, and again -- $self->pool -- when the work ended, to release
# or retire the connection. Every transport in the family builds its pool
# lazily ($self->{pool} ||= ...), and disconnect drops it. So work that was
# under way at a disconnect and ended afterwards -- a transaction standing
# between two statements, a pipeline waiting for its sync, a DDL statement in
# flight -- built a NEW pool on the disconnected storage as it ended, and
# released into it a connection that pool had never held. The storage was left
# "connected" by something that had merely finished.
#
# The claim: what begins work resolves the pool and keeps it; what ends work
# talks to exactly that pool. After a disconnect that pool is shut down, where
# a release and a retirement are no-ops, and the storage stays without a pool.
# The caller's Future ends as it did before, and nothing warns.
#
# The fixture: a backend whose pool is built lazily, as the transports build
# theirs, counting the builds; a real DBIO::Storage::PoolBase of size 1 that
# logs every release and every in-use retirement it is asked for -- also the
# ones it ignores because it was shut down -- and every connection it closes.
# Run against DBIO::Test::Future and, where installed, Future.pm.

{
  package K46::Conn;
  sub new { bless { id => $_[1], in_pipeline => 0 }, $_[0] }
}

{
  package K46::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection   { K46::Conn->new(++$_[0]->{_next_id}) }
  sub _shutdown_connection { push @{ $_[0]->{closed} }, $_[1]->{id} }

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, $conn->{id};
    return $self->SUPER::release($conn);
  }

  sub _retire_in_use_connection {
    my ($self, $conn) = @_;
    push @{ $self->{retire_log} }, $conn->{id};
    return $self->SUPER::_retire_in_use_connection($conn);
  }
}

# The owner deploy_async asks: is the engine transactional, and is this
# statement. ALTER stands for the statement that cannot run in a transaction.
{
  package K46::DdlOwner;
  sub new { bless { txn => $_[1] }, $_[0] }
  sub _use_transactional_ddl { $_[0]->{txn} }
  sub _ddl_statement_is_transactional { $_[1] =~ /^ALTER/ ? 0 : 1 }
}

{
  package K46::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { $_[0]->{fc} }
  # A transport with a session reset (karr core k398).
  sub _reset_pool_connection { $_[0]->future_class->done }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }
  sub _install_ddl     { $_[0]->{ddl} }

  # Lazily, in the slot disconnect empties: the shape of every transport's
  # pool (DBIO::Async::Storage, DBIO::PostgreSQL::EV::Storage, ...).
  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= do {
      $self->{pools_built}++;
      K46::Pool->new(
        storage      => $self,
        conninfo     => 'fake',
        size         => 1,
        future_class => $self->future_class,
        on_error     => sub { warn "pool error: $_[0]\n" },
      );
    };
  }

  # {hold}{VERB}: not answered until answer_held. {fail}{VERB}: its answer is
  # a failure.
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    my ($verb) = $sql =~ /^(\w+)/;
    push @{ $self->{captured} }, $verb;
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
    return $f->done($verb eq 'SELECT' ? 'row' : ());
  }

  sub _pipeline_enter { $_[1]->{in_pipeline} = 1; return 1 }

  sub _pipeline_sync {
    my ($self, $conn) = @_;
    return $self->{sync_future} || $self->future_class->new->done;
  }

  sub _pipeline_exit {
    my ($self, $conn) = @_;
    die "exit croaked\n" if $self->{die_exit};
    $conn->{in_pipeline} = 0;
    return 1;
  }
}

my @warnings;
local $SIG{__WARN__} = sub {
  # deploy_async's own one-shot notice on a non-transactional engine.
  return if $_[0] =~ /^non-transactional DDL on K46::Backend /;
  push @warnings, $_[0];
};

sub new_backend {
  my ($fc, %wire) = @_;
  my $owner = delete $wire{owner};

  my ($schema, $backend);
  if ($owner) {
    $backend = K46::Backend->new(undef);
    $backend->{_test_owner} = $owner;          # _owner_storage holds it weakly
  }
  else {
    $schema  = DBIO::Test->init_schema;
    $backend = K46::Backend->new($schema);
    $owner   = $schema->storage;
    $backend->{_test_schema_guard} = $schema;
  }
  $backend->{fc} = $fc;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token)
    if $owner->can('_async_context_owner_token');
  $backend->{captured} = [];
  $backend->{$_} = $wire{$_} for keys %wire;
  return $backend;
}

sub answer_held {
  my ($backend) = @_;
  while (my $held = shift @{ $backend->{held} || [] }) {
    $backend->_answer(@$held);
  }
  return;
}

sub outcome {
  my ($f) = @_;
  return 'pending' unless $f->is_ready;
  my @values;
  return "failed: $@" unless eval { @values = $f->get; 1 };
  return 'done: ' . join(',', map { defined $_ ? "$_" : 'undef' } @values);
}

# The assertions every scenario ends on. $how is what the work owed its
# connection: 'release', or 'retire' for one left in a state the next borrower
# could not use.
sub handed_back {
  my ($l, $backend, $pool, $teardown, $how) = @_;
  my $other = $how eq 'release' ? 'retire' : 'release';

  is_deeply $pool->{"${how}_log"}, [1],
    "$l: the pool the connection came from was asked to $how it, once";
  is_deeply $pool->{"${other}_log"} || [], [],
    "$l: ... and not to $other it as well";
  is $backend->{pools_built}, 1,
    "$l: no pool was built besides the one the work began with";

  if ($teardown eq 'disconnect') {
    ok !defined $backend->{pool},
      "$l: the disconnected storage is left without a pool";
    is_deeply $pool->{closed}, [1],
      "$l: the pool it had closed the connection, once";
  }
  elsif ($how eq 'release') {
    ok defined $backend->{pool} && $backend->{pool} == $pool,
      "$l: the storage keeps its pool";
    is $pool->available, 1, "$l: ... and the connection is idle in it again";
  }
  else {
    ok defined $backend->{pool} && $backend->{pool} == $pool,
      "$l: the storage keeps its pool";
    is $pool->size, 0, "$l: ... which no longer counts the connection";
    is_deeply $pool->{closed}, [1], "$l: ... and closed it, once";
  }

  is_deeply [ splice @warnings ], [], "$l: nothing warned";
  return;
}

# Holding the pool for the length of the work must not hold the storage for
# longer than that: once the work has ended, dropping the storage frees it and
# its pool.
sub freed {
  my ($l, $left) = @_;
  ok !defined $left->{backend}, "$l: the storage is freed once it is dropped";
  ok !defined $left->{pool},    "$l: ... and so is the pool the work held";
  return;
}

# ---------------------------------------------------------------------------
# (i) A transaction standing between two statements: its first statement is
# answered, its block waits on something else, nothing is in flight. Then the
# block goes on -- and fails, with a ROLLBACK that is answered or one that is
# refused, or returns and is committed.
# ---------------------------------------------------------------------------
sub txn_between_statements {
  my ($fc, $teardown, $ending, $left) = @_;
  my $l = "$fc, txn between two statements, $teardown, the block $ending";

  my $backend = new_backend($fc,
    $ending eq 'fails, ROLLBACK refused' ? (fail => { ROLLBACK => "not sent\n" }) : (),
  );
  my $pool  = $backend->pool;
  my $pause = $fc->new;
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->_query_async('SELECT 1', [])->then(sub { return $pause });
  });
  is_deeply $backend->{captured}, [qw(BEGIN SELECT)],
    "$l: the first statement is answered";
  is outcome($f), 'pending', "$l: ... and the transaction waits for its block";
  is $pool->available, 0, "$l: ... holding its connection";

  $backend->disconnect if $teardown eq 'disconnect';

  if ($ending eq 'succeeds') { $pause->done('kept') }
  else                       { $pause->fail("block gave up\n") }

  if ($ending eq 'succeeds') {
    is outcome($f), 'done: kept', "$l: the transaction resolves with the block's value";
    is_deeply $backend->{captured}, [qw(BEGIN SELECT COMMIT)], "$l: COMMIT was sent";
  }
  elsif ($ending eq 'fails') {
    like outcome($f), qr/^failed: .*block gave up/s,
      "$l: the transaction fails with the block's error";
    unlike outcome($f), qr/Rollback failed/, "$l: ... and no other";
    is_deeply $backend->{captured}, [qw(BEGIN SELECT ROLLBACK)], "$l: ROLLBACK was sent";
  }
  else {
    like outcome($f), qr/^failed: .*Transaction aborted: block gave up\n\. Rollback failed: not sent/s,
      "$l: the transaction fails with the block's error, then the ROLLBACK's";
  }

  # A ROLLBACK that was refused leaves the connection in a state the next
  # borrower could not use: retired (karr k395).
  handed_back($l, $backend, $pool, $teardown,
    $ending eq 'fails, ROLLBACK refused' ? 'retire' : 'release');
  weaken($left->{backend} = $backend);
  weaken($left->{pool}    = $pool);
  return $l;
}

# ---------------------------------------------------------------------------
# (i) The transaction's other hand-back: a pipeline on its connection could
# not leave pipeline mode, so the connection is retired, not released.
# ---------------------------------------------------------------------------
sub txn_unusable_connection {
  my ($fc, $teardown, $left) = @_;
  my $l = "$fc, txn whose connection a pipeline left unusable, $teardown";

  my $backend = new_backend($fc, die_exit => 1);
  my $pool    = $backend->pool;
  my $pause   = $fc->new;
  my $batch;
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    $batch = $ctx->pipeline(sub { return $_[0]->_query_async('SELECT 1', []) });
    return $pause;
  });
  like outcome($batch), qr/^failed: .*exit croaked/s, "$l: the pipeline's exit died";
  is outcome($f), 'pending', "$l: ... and the transaction waits for its block";

  $backend->disconnect if $teardown eq 'disconnect';
  $pause->done('kept');

  like outcome($f), qr/^failed: .*COMMIT not sent/s,
    "$l: the transaction fails: COMMIT was not sent";
  is_deeply $backend->{captured}, [qw(BEGIN SELECT ROLLBACK)],
    "$l: ... a best-effort ROLLBACK was";

  handed_back($l, $backend, $pool, $teardown, 'retire');
  undef $batch;
  weaken($left->{backend} = $backend);
  weaken($left->{pool}    = $pool);
  return $l;
}

# ---------------------------------------------------------------------------
# (ii) A pipeline waiting for its sync. The sync resolves, or fails, or
# resolves into an exit that dies (the connection is retired then, as it is
# when the sync fails: a failed pipeline never releases, karr k396).
# ---------------------------------------------------------------------------
sub pipeline_awaiting_sync {
  my ($fc, $teardown, $ending, $left) = @_;
  my $l = "$fc, pipeline waiting for its sync, $teardown, $ending";

  my $sync    = $fc->new;
  my $backend = new_backend($fc,
    sync_future => $sync,
    $ending eq 'the exit dies' ? (die_exit => 1) : (),
  );
  my $pool = $backend->pool;
  my $f = $backend->pipeline(sub { return $_[0]->_query_async('SELECT 1', []) });
  is outcome($f), 'pending', "$l: the pipeline waits";
  is $pool->available, 0, "$l: ... holding its connection";

  $backend->disconnect if $teardown eq 'disconnect';

  if ($ending eq 'the sync fails') { $sync->fail("sync failed\n") }
  else                             { $sync->done }

  if ($ending eq 'the sync resolves') {
    is outcome($f), 'done: row', "$l: the pipeline resolves with the batch's result";
  }
  elsif ($ending eq 'the sync fails') {
    like outcome($f), qr/^failed: .*sync failed/s, "$l: the pipeline fails with the sync's error";
  }
  else {
    like outcome($f), qr/^failed: .*exit croaked/s, "$l: the pipeline fails with the exit's error";
  }

  handed_back($l, $backend, $pool, $teardown,
    $ending eq 'the sync resolves' ? 'release' : 'retire');
  weaken($left->{backend} = $backend);
  weaken($left->{pool}    = $pool);
  return $l;
}

# ---------------------------------------------------------------------------
# (iii) deploy_async with a DDL statement in flight, on each of its three
# roads: a non-transactional engine (the whole batch on one pooled
# connection), a transactional engine's run of a statement that cannot run in
# a transaction (its own pooled connection), and a transactional run (through
# txn_do_async).
# ---------------------------------------------------------------------------
my %DEPLOY = (
  'non-transactional engine' => [ 0, "CREATE TABLE a (id int);",          [qw(CREATE)] ],
  'non-transactional run'    => [ 1, "ALTER TYPE mood ADD VALUE 'calm';", [qw(ALTER)]  ],
  'transactional run'        => [ 1, "CREATE TABLE a (id int);",          [qw(BEGIN CREATE)] ],
);

sub deploy_ddl_in_flight {
  my ($fc, $teardown, $road, $ending, $left) = @_;
  my $l = "$fc, deploy_async on a $road, $teardown, the statement $ending";

  my ($txn_engine, $ddl, $sent) = @{ $DEPLOY{$road} };
  my $verb = $sent->[-1];
  my $backend = new_backend($fc,
    owner => K46::DdlOwner->new($txn_engine),
    ddl   => $ddl,
    hold  => { $verb => 1 },
    $ending eq 'fails' ? (fail => { $verb => "DDL failed\n" }) : (),
  );
  my $pool = $backend->pool;
  my $f = $backend->deploy_async('schema');
  is_deeply $backend->{captured}, $sent, "$l: the statement is in flight";
  is outcome($f), 'pending', "$l: ... and the deploy waits for it";
  is $pool->available, 0, "$l: ... holding its connection";

  $backend->disconnect if $teardown eq 'disconnect';
  answer_held($backend);

  if ($ending eq 'fails') {
    like outcome($f), qr/^failed: .*DDL failed/s, "$l: the deploy fails with the statement's error";
  }
  else {
    like outcome($f), qr/^done: /, "$l: the deploy resolves";
  }

  handed_back($l, $backend, $pool, $teardown, 'release');
  weaken($left->{backend} = $backend);
  weaken($left->{pool}    = $pool);
  return $l;
}

my @future_classes = ('DBIO::Test::Future');
if (eval { require Future; 1 }) { push @future_classes, 'Future' }
else { note 'Future.pm not installed: run against DBIO::Test::Future only' }

for my $fc (@future_classes) {
  # 'no teardown' is the control: the connection comes back as it always did.
  for my $teardown ('disconnect', 'no teardown') {
    for my $ending ('fails', 'fails, ROLLBACK refused', 'succeeds') {
      my %left;
      freed(txn_between_statements($fc, $teardown, $ending, \%left), \%left);
    }

    {
      my %left;
      freed(txn_unusable_connection($fc, $teardown, \%left), \%left);
    }

    for my $ending ('the sync resolves', 'the sync fails', 'the exit dies') {
      my %left;
      freed(pipeline_awaiting_sync($fc, $teardown, $ending, \%left), \%left);
    }

    for my $road (sort keys %DEPLOY) {
      for my $ending ('succeeds', 'fails') {
        my %left;
        freed(deploy_ddl_in_flight($fc, $teardown, $road, $ending, \%left), \%left);
      }
    }
  }
}

done_testing;
