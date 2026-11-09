use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k334, from dbio-postgresql-ev k87. txn_do_async(sub { $storage->... })
# -- the coderef returns the Future of a call on the STORAGE, not on $ctx. With
# pool_size 1 that call is queued for the connection the transaction holds, so
# the transaction waits on a Future that waits on the transaction. The core
# cannot recognise a driver's queued waiter; it asks the driver through the seam
# _txn_inner_future($txn_ctx, $conn, $inner_future), once the coderef has
# returned and before COMMIT is chained on its Future.
#
# The claim: (1) the default seam hands the coderef's Future back and changes
# nothing; (2) a driver that fails the inner Future through the seam gets
# ROLLBACK, the transaction fails with exactly that refusal, and the connection
# is back in the pool; (3) a seam that throws is a coderef die: ROLLBACK and the
# error; (4) in none of the refused cases does COMMIT go out.

{
  package K334::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K334::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { K334::Conn->new(++$_[0]->{_next_id}) }
}

{
  package K334::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }

  sub pool {
    return $_[0]->{pool} ||= K334::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => 'DBIO::Test::Future',
    );
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    my ($verb) = $sql =~ /^(\w+)/;
    push @{ $self->{captured} }, $verb;
    return $self->future_class->new->done;
  }
}

{
  # A driver filling the seam: refuse (fail), throw, or pass through.
  package K334::Driver;
  use base 'K334::Backend';

  sub _txn_inner_future {
    my ($self, $ctx, $conn, $inner) = @_;
    push @{ $self->{seam_calls} }, [ $ctx, $conn, $inner ];
    die $self->{seam_throw} if defined $self->{seam_throw};
    return $inner if $self->{seam_pass};
    return $self->future_class->fail($self->{seam_refusal});
  }
}

sub new_backend {
  my ($class, %set) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $backend = $class->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{captured} = [];
  $backend->{$_} = $set{$_} for keys %set;
  return $backend;
}

sub outcome {
  my ($f) = @_;
  my ($value, $error);
  $f->then(sub { $value = $_[0]; return });
  $f->catch(sub { $error = $_[0]; return });
  return ($value, $error);
}

sub pool_is_free {
  my ($backend, $label) = @_;
  my $pool = $backend->pool;
  is $pool->available, $pool->size, "$label: the connection is back in the pool";
}

# (1) Default: nothing changes.
{
  my $backend = new_backend('K334::Backend');
  my ($got, $error) = outcome(
    $backend->txn_do_async(sub { DBIO::Test::Future->done('v') })
  );
  is $error, undef, 'default seam: the transaction succeeds';
  is $got, 'v', 'default seam: with the coderef\'s value';
  is_deeply $backend->{captured}, [ qw(BEGIN COMMIT) ],
    'default seam: BEGIN then COMMIT';
  pool_is_free($backend, 'default seam');

  my $inner = DBIO::Test::Future->done('x');
  is $backend->_txn_inner_future(undef, undef, $inner), $inner,
    'default seam: returns the inner Future unchanged';
}

# (2) A driver refuses the inner Future.
{
  my $refusal = "refused: call on the storage inside txn_do\n";
  my $backend = new_backend('K334::Driver', seam_refusal => $refusal);
  my $pending = DBIO::Test::Future->new;
  my $f = $backend->txn_do_async(sub { $pending });

  my (undef, $error) = outcome($f);
  is scalar @{ $backend->{seam_calls} || [] }, 1, 'refused: the seam was asked once';
  is $backend->{seam_calls}[0][2], $pending, 'refused: with the coderef\'s Future';
  is $error, $refusal, 'refused: the transaction fails with exactly the refusal';
  is_deeply $backend->{captured}, [ qw(BEGIN ROLLBACK) ],
    'refused: ROLLBACK went out, COMMIT did not';
  pool_is_free($backend, 'refused');
  ok !$backend->{seam_calls}[0][0]->in_txn,
    'refused: the transaction context is no longer in a transaction';
}

# (3) A seam that throws is a coderef die.
{
  my $backend = new_backend('K334::Driver', seam_throw => "seam died\n");
  my $f = eval { $backend->txn_do_async(sub { DBIO::Test::Future->new }) };
  ok $f && $f->is_failed, 'throwing seam: txn_do_async returns a failed Future';
  my (undef, $error) = $f ? outcome($f) : (undef, $@);
  is $error, "seam died\n", 'throwing seam: the transaction fails with the exception';
  is_deeply $backend->{captured}, [ qw(BEGIN ROLLBACK) ],
    'throwing seam: ROLLBACK went out, COMMIT did not';
  pool_is_free($backend, 'throwing seam');
}

# A seam that passes the Future through leaves a succeeding transaction.
{
  my $backend = new_backend('K334::Driver', seam_pass => 1);
  my ($got, $error) = outcome(
    $backend->txn_do_async(sub { DBIO::Test::Future->done('ok') })
  );
  is $error, undef, 'passing seam: no error';
  is $got, 'ok', 'passing seam: the coderef\'s value';
  is_deeply $backend->{captured}, [ qw(BEGIN COMMIT) ], 'passing seam: COMMIT';
}

# The seam is not asked when the coderef died.
{
  my $backend = new_backend('K334::Driver', seam_refusal => 'nope');
  my (undef, $error) = outcome($backend->txn_do_async(sub { die "coderef died\n" }));
  is $error, "coderef died\n", 'coderef died: its own error';
  ok !$backend->{seam_calls}, 'coderef died: the seam was not asked';
}

done_testing;
