use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed: no callback can die bare' }

# karr k279. A transaction hands its connection back once COMMIT or ROLLBACK is
# answered (_txn_hand_back), from inside the chain its own Future is settled
# by. In a pool of one that release hands the connection to the oldest queued
# caller, whose callbacks run then and there. One that died was thrown out of
# release into the transaction's chain: the Future of a transaction the server
# had committed failed, with the error of a caller it had nothing to do with.
#
# The claim: how a transaction ends is told by its own Future alone. The death
# of another caller's callback goes to the pool's on_error, and that caller has
# the connection all the same.
#
# The fixture: a fake wire over a real DBIO::Storage::PoolBase of size 1, with
# Future.pm -- on_done runs a callback bare. COMMIT and ROLLBACK are held until
# the test answers them.

{
  package K279T::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K279T::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { K279T::Conn->new(++$_[0]->{_next_id}) }
}

{
  package K279T::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }

  sub pool {
    my $self = shift;
    my $errors = $self->{pool_errors} ||= [];
    return $self->{pool} ||= K279T::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => 'Future',
      on_error     => sub { push @$errors, $_[0] },
    );
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    my ($verb) = $sql =~ /^(\w+)/;
    push @{ $self->{captured} }, $verb;
    my $f = $self->future_class->new;
    return $f->done unless $verb eq 'COMMIT' || $verb eq 'ROLLBACK';
    push @{ $self->{held} }, $f;
    return $f;
  }
}

sub new_backend {
  my $schema  = DBIO::Test->init_schema;
  my $backend = K279T::Backend->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{captured} = [];
  return $backend;
}

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

for my $case (
  [ 'a committed transaction',   'COMMIT',   sub { Future->done('the coderef returned') } ],
  [ 'a rolled back transaction', 'ROLLBACK', sub { die "the coderef died\n" } ],
) {
  my ($l, $verb, $code) = @$case;
  my $backend = new_backend();

  my $txn    = $backend->txn_do_async($code);
  my $queued = $backend->pool->acquire;
  $queued->on_done(sub { die "another caller's callback died\n" });
  ok !$txn->is_ready && !$queued->is_ready,
    "$l: $verb is in flight, and another caller is queued for the connection";

  ok eval { $_->done for @{ $backend->{held} }; 1 },
    "$l: answering $verb does not die of that caller's callback" or diag $@;

  is_deeply $backend->{captured}, [ 'BEGIN', $verb ], "$l: (BEGIN and $verb went out)";
  if ($verb eq 'COMMIT') {
    ok $txn->is_ready && !$txn->is_failed, "$l: its Future resolves"
      or diag scalar $txn->failure;
    is scalar( eval { $txn->get } ), 'the coderef returned', "$l: with what the coderef returned";
  }
  else {
    ok $txn->is_ready && $txn->is_failed, "$l: its Future fails";
    like scalar $txn->failure, qr/the coderef died/, "$l: with the coderef's own error";
    unlike scalar $txn->failure, qr/another caller/, "$l: not with the other caller's";
  }

  ok $queued->is_ready && !$queued->is_failed, "$l: the queued caller has the connection";
  is scalar @{ $backend->{pool_errors} }, 1, "$l: the pool's on_error is told of its callback, once";
  like $backend->{pool_errors}[0],
    qr/a released connection was handed to a queued caller: another caller's callback died/,
    "$l: with the callback's own error, and what it died under";
  is $backend->pool->available, 0, "$l: the connection is borrowed, not idle as well";
}

is_deeply \@warnings, [], 'nothing warned';

done_testing;
