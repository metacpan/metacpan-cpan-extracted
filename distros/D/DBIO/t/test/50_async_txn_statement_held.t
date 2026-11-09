use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::Async::TransactionContext;
use DBIO::Storage::PoolBase;

# karr k292, from dbio-mysql (t/71-future-io-txn-offline.t, case 4). A
# transaction context keeps the Future of every statement it hands out
# (_track_statement, karr k236): "held strongly, so a Future nobody else keeps
# -- a statement issued and not awaited -- still reports how it ended". It
# kept them until the context ended, and a context ends as ROLLBACK goes out
# (karr k237) or in the finalizer -- which can be before a statement has its
# answer. A statement still in flight then lost its only holder. With Future.pm
# its Future is a ->then sequence the transport's own Future holds weakly, so
# it was freed on the spot, and Future.pm said so when the answer came: "lost a
# sequence Future", once per statement. For a pipeline run on the transaction
# it was more than a warning: the freed sequence was the one that leaves
# pipeline mode.
#
# The claim: the context lets go of a statement's Future when the statement is
# answered, not when the context ends. On every road a context ends with a
# statement in flight -- the coderef dies, returns a failed Future, or its
# Future fails later; the connection was left unusable by a pipeline (karr
# k232), with the coderef dying or returning; the storage was disconnected in
# between -- the Future is still there until its answer, and is freed after it
# although the context is still in hand. Nothing warns. _txn_statements is
# empty once the context has ended, as documented. A statement Future that is
# cancelled is let go of then.
#
# The fixture: a fake wire whose statement Futures are ->then sequences off a
# Future the test settles later, as a transport's are. Against Future.pm, where
# the bug is, and against DBIO::Test::Future, which holds a chain from its head
# and has no retain: the same claims hold there before and after.

{
  package K292::Conn;
  sub new { bless { id => $_[1], in_pipeline => 0 }, $_[0] }
}

{
  package K292::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { K292::Conn->new(++$_[0]->{_next_id}) }
}

# A context class of a transport's own, as dbio-async's and the EV drivers'
# are: it inherits everything.
{
  package K292::SubContext;
  use base 'DBIO::Storage::Async::TransactionContext';
}

{
  package K292::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { $_[0]->{fc} }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }

  sub _txn_context_class { $_[0]->{ctx_class} || $_[0]->next::method }

  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= K292::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => $self->future_class,
    );
  }

  # The Future handed back is a ->then sequence off $source, the Future the
  # wire settles. {hold}{VERB}: $source is not settled until answer_held; the
  # wire keeps it, as an event loop keeps a transport's.
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    my ($verb) = $sql =~ /^(\w+)/;
    my $fc = $self->future_class;
    $self->{in_flight_at}{$verb} = scalar @{ $self->{held} || [] };
    push @{ $self->{captured} }, $verb;

    my $source    = $fc->new;
    my $statement = $source->then(sub { return $fc->new->done(@_) });
    if ($self->{hold}{$verb}) { push @{ $self->{held} }, [ $source, $verb ] }
    else                      { $self->_answer($source, $verb) }
    return $statement;
  }

  sub _answer {
    my ($self, $source, $verb) = @_;
    return $source->fail($self->{fail}{$verb}) if defined $self->{fail}{$verb};
    return $source->done('row');
  }

  sub _pipeline_enter {
    my ($self, $conn) = @_;
    push @{ $self->{captured} }, 'ENTER';
    $conn->{in_pipeline} = 1;
    return 1;
  }

  sub _pipeline_sync {
    my ($self, $conn) = @_;
    return $self->{sync_future} || $self->future_class->new->done;
  }

  sub _pipeline_exit {
    my ($self, $conn) = @_;
    die "exit croaked\n" if $self->{die_exit};
    push @{ $self->{captured} }, 'EXIT';
    $conn->{in_pipeline} = 0;
    return 1;
  }
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

sub new_backend {
  my ($fc, %wire) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $backend = K292::Backend->new($schema);
  my $owner   = $schema->storage;
  $backend->{fc} = $fc;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
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

my $GAVE_UP = "the block gave up\n";

# One road on which a context ends with a statement in flight. The coderef of
# the transaction issues an INSERT nobody else holds -- the test keeps a weak
# reference only -- and then does what {block} says; {then} is what happens
# after txn_do_async has returned. Asserts, in this order: the transaction
# fails as {fails} says, having sent {sent}; the context has ended and lists
# no statement; the INSERT's Future is still there, unanswered; nothing warned;
# then its answer arrives ({answer_fails}: a failure) -- nothing warns, and the
# Future is gone although the context is still in hand; and nothing is left
# behind once the test lets go.
sub ends_with_statement_in_flight {
  my ($fc, $name, %c) = @_;
  my $l = "$fc, $name";

  my %left;
  {
    my $backend = new_backend($fc, hold => { INSERT => 1 }, %{ $c{wire} || {} });
    my %s;
    my $f = $backend->txn_do_async(sub {
      my ($ctx) = @_;
      $s{ctx} = $ctx;
      weaken($s{stmt} = $ctx->_query_async('INSERT INTO t VALUES (1)', []));
      return $c{block}->($ctx, \%s, $fc);
    });
    $c{then}->($backend, \%s, $l) if $c{then};

    like outcome($f), $c{fails}, "$l: the transaction fails as it should";
    is_deeply $backend->{captured}, $c{sent}, "$l: ... having sent what it should";
    ok !$s{ctx}->_context_active, "$l: the context has ended";
    is_deeply [ $s{ctx}->_txn_statements ], [],
      "$l: ... and lists no statement any more";
    ok defined $s{stmt} && !$s{stmt}->is_ready,
      "$l: the statement in flight still has its Future -- it has no answer yet";
    is_deeply [ splice @warnings ], [], "$l: nothing warned";

    $backend->{fail}{INSERT} = "the insert failed\n" if $c{answer_fails};
    answer_held($backend);
    is_deeply [ splice @warnings ], [], "$l: its answer arrives: nothing warns";
    ok !defined $s{stmt},
      "$l: ... and its Future is let go of, the context still in hand";

    weaken($left{backend} = $backend);
    weaken($left{ctx}     = $s{ctx});
  }
  ok !defined $left{backend} && !defined $left{ctx}, "$l: nothing is left behind";
  return;
}

my @future_classes = ('DBIO::Test::Future');
if (eval { require Future; 1 }) { push @future_classes, 'Future' }
else { diag 'Future.pm not installed: the class the bug shows under is not run' }

for my $fc (@future_classes) {

  # -------------------------------------------------------------------------
  # The coderef fails, three ways: ROLLBACK goes out at once, and the context
  # ends with it (karr k237). The last of them is the card's own case.
  # -------------------------------------------------------------------------
  my @rollback = (
    fails => qr/^failed: .*the block gave up/s,
    sent  => [qw(BEGIN INSERT ROLLBACK)],
  );
  ends_with_statement_in_flight($fc, 'the block dies',
    block => sub { die $GAVE_UP }, @rollback);
  ends_with_statement_in_flight($fc, 'the block dies, the statement then fails',
    block => sub { die $GAVE_UP }, @rollback, answer_fails => 1);
  ends_with_statement_in_flight($fc, 'the block returns a failed Future',
    block => sub { return $_[2]->new->fail($GAVE_UP) }, @rollback);
  ends_with_statement_in_flight($fc, 'the block returns a Future that fails later',
    block => sub { return $_[1]{later} = $_[2]->new },
    then  => sub { $_[1]{later}->fail($GAVE_UP) },
    @rollback);

  # A context class of the transport's own inherits the fix.
  ends_with_statement_in_flight($fc, 'the block dies, context subclass',
    wire  => { ctx_class => 'K292::SubContext' },
    block => sub {
      isa_ok $_[0], 'K292::SubContext', "$fc: the context";
      die $GAVE_UP;
    },
    @rollback);

  # -------------------------------------------------------------------------
  # The connection was left unusable by a pipeline whose exit died (karr
  # k232): nothing is waited for on it, and the context ends in the finalizer.
  # -------------------------------------------------------------------------
  ends_with_statement_in_flight($fc, 'unusable connection, the block dies',
    wire  => { die_exit => 1 },
    block => sub { $_[1]{batch} = $_[0]->pipeline(sub { 1 }); die $GAVE_UP },
    fails => qr/^failed: .*the block gave up/s,
    sent  => [qw(BEGIN INSERT ENTER ROLLBACK)]);
  ends_with_statement_in_flight($fc, 'unusable connection, the block returns',
    wire  => { die_exit => 1 },
    block => sub { $_[1]{batch} = $_[0]->pipeline(sub { 1 }); return 'kept' },
    fails => qr/^failed: .*COMMIT not sent/s,
    sent  => [qw(BEGIN INSERT ENTER ROLLBACK)]);

  # -------------------------------------------------------------------------
  # The storage is disconnected in between. That does not end the context --
  # it still lists its statement -- so it ends on one of the roads above, here
  # the coderef's Future failing afterwards.
  # -------------------------------------------------------------------------
  ends_with_statement_in_flight($fc, 'disconnect, then the block\'s Future fails',
    block => sub { return $_[1]{later} = $_[2]->new },
    then  => sub {
      my ($backend, $s, $l) = @_;
      $backend->disconnect;
      is scalar(() = $s->{ctx}->_txn_statements), 1,
        "$l: the disconnect alone does not end the context: it keeps its statement";
      ok defined $s->{stmt}, "$l: ... whose Future is there";
      $s->{later}->fail($GAVE_UP);
    },
    @rollback);

  # -------------------------------------------------------------------------
  # Control, the COMMIT road: COMMIT waits for every statement (karr k236), so
  # no statement is in flight when the context ends there.
  # -------------------------------------------------------------------------
  {
    my $l = "$fc, the block returns normally";
    my %left;
    {
      my $backend = new_backend($fc, hold => { INSERT => 1 });
      my ($ctx, $stmt);
      my $f = $backend->txn_do_async(sub {
        ($ctx) = @_;
        weaken($stmt = $ctx->_query_async('INSERT INTO t VALUES (1)', []));
        return 'kept';
      });
      is outcome($f), 'pending', "$l: the transaction waits for the statement in flight";
      ok $ctx->_context_active, "$l: ... its context still active";
      ok defined $stmt, "$l: ... and holding the statement's Future";

      answer_held($backend);
      is outcome($f), 'done: kept', "$l: answered, the transaction commits";
      is_deeply $backend->{captured}, [qw(BEGIN INSERT COMMIT)], "$l: ... with COMMIT";
      is $backend->{in_flight_at}{COMMIT}, 0,
        "$l: nothing was in flight as COMMIT went out and the context ended";
      ok !defined $stmt, "$l: the statement's Future is let go of";
      is_deeply [ splice @warnings ], [], "$l: nothing warned";

      weaken($left{backend} = $backend);
      weaken($left{ctx}     = $ctx);
    }
    ok !defined $left{backend} && !defined $left{ctx}, "$l: nothing is left behind";
  }

  # -------------------------------------------------------------------------
  # A pipeline run on the transaction is tracked like a statement, and its
  # Future is the sequence off the sync that leaves pipeline mode. The coderef
  # dies while the sync is outstanding. Asserts that Future is held until the
  # sync is answered, pipeline mode is left then, and nothing warns.
  # -------------------------------------------------------------------------
  {
    my $l = "$fc, the block dies with a pipeline waiting for its sync";
    my %left;
    {
      my $sync    = $fc->new;
      my $backend = new_backend($fc, sync_future => $sync);
      my ($ctx, $batch);
      my $f = $backend->txn_do_async(sub {
        ($ctx) = @_;
        weaken($batch = $ctx->pipeline(sub { 1 }));
        die $GAVE_UP;
      });
      # The ROLLBACK waits for the pipeline: sent now it would go out in
      # pipeline mode (karr k331, t/test/57).
      is outcome($f), 'pending', "$l: the transaction waits for the pipeline's sync";
      is_deeply $backend->{captured}, [qw(BEGIN ENTER)],
        "$l: ... pipeline mode entered, not yet left, nothing sent behind it";
      is_deeply [ $ctx->_txn_statements ], [], "$l: the ended context lists nothing";
      ok defined $batch && !$batch->is_ready,
        "$l: the pipeline still has its Future -- its sync is not answered";

      $sync->done;
      like outcome($f), qr/^failed: .*the block gave up/s,
        "$l: the sync is answered: the transaction fails with the block's error";
      is_deeply $backend->{captured}, [qw(BEGIN ENTER EXIT ROLLBACK)],
        "$l: ... pipeline mode is left, then ROLLBACK";
      is_deeply [ splice @warnings ], [], "$l: ... and nothing warned";
      ok !defined $batch, "$l: ... and the pipeline's Future is let go of";

      weaken($left{backend} = $backend);
      weaken($left{ctx}     = $ctx);
    }
    ok !defined $left{backend} && !defined $left{ctx}, "$l: nothing is left behind";
  }

  # -------------------------------------------------------------------------
  # A statement Future that is cancelled after its context ended is not held
  # for good: the cancel lets go of it. Only a class that can cancel.
  # -------------------------------------------------------------------------
  SKIP: {
    skip "$fc cannot cancel", 4 unless $fc->can('cancel');
    my $l = "$fc, the block dies, the statement is then cancelled";
    my %left;
    {
      my $backend = new_backend($fc, hold => { INSERT => 1 });
      my ($ctx, $stmt);
      my $f = $backend->txn_do_async(sub {
        ($ctx) = @_;
        weaken($stmt = $ctx->_query_async('INSERT INTO t VALUES (1)', []));
        die $GAVE_UP;
      });
      ok defined $stmt, "$l: the statement in flight still has its Future";
      $stmt->cancel if defined $stmt;
      ok !defined $stmt, "$l: cancelled, it is let go of";
      $backend->{held} = [];
      is_deeply [ splice @warnings ], [], "$l: nothing warned";

      weaken($left{backend} = $backend);
      weaken($left{ctx}     = $ctx);
    }
    ok !defined $left{backend} && !defined $left{ctx}, "$l: nothing is left behind";
  }
}

done_testing;
