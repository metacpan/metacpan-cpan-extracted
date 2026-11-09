use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::Exception::Server ();
use Scalar::Util qw(blessed);
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k395: a ROLLBACK that is not confirmed (its Future failed, or its
# dispatch threw) leaves the connection with a transaction of unknown state, so
# the connection is retired and never handed back to the pool. The transaction
# still fails with both errors, the original first. A confirmed ROLLBACK
# releases the connection as before.

{
  package K395::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K395::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection { K395::Conn->new(++$_[0]->{_next_id}) }

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

{
  package K395::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }

  sub pool {
    return $_[0]->{pool} ||= K395::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => 'DBIO::Test::Future',
    );
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    my ($verb) = $sql =~ /^(\w+)/;
    push @{ $self->{captured} }, $verb;
    die $self->{throw}{$verb} if defined $self->{throw}{$verb};
    my $f = $self->future_class->new;
    return $f->fail($self->{fail}{$verb}) if defined $self->{fail}{$verb};
    return $f->done({ artistid => ++$self->{next_id} }) if $verb eq 'INSERT';
    return $f->done;
  }
}

sub server_error {
  my ($text, $sqlstate) = @_;
  return DBIO::Exception::Server->new(message => $text, sqlstate => $sqlstate);
}

sub new_backend {
  my (%wire) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $backend = K395::Backend->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{captured} = [];
  $backend->{$_} = $wire{$_} for keys %wire;
  return $backend;
}

sub outcome {
  my ($f) = @_;
  my ($value, $error);
  $f->then(sub { $value = $_[0]; return });
  $f->catch(sub { $error = $_[0]; return });
  return ($value, $error);
}

my $dies = sub {
  my ($ctx) = @_;
  return $ctx->insert_async('artist', { name => 'Miles Davis' })
    ->then(sub { die "coderef died mid-transaction\n" });
};

for my $how (qw(fail throw)) {
  my $backend = new_backend(
    ($how eq 'fail'  ? (fail  => { ROLLBACK => "transport refused: ROLLBACK\n" }) : ()),
    ($how eq 'throw' ? (throw => { ROLLBACK => "transport refused: ROLLBACK\n" }) : ()),
  );
  my $f = eval { $backend->txn_do_async($dies) };
  ok $f && $f->is_failed, "ROLLBACK $how: txn_do_async returns a failed Future";
  my (undef, $error) = $f ? outcome($f) : (undef, $@);
  like "$error", qr/coderef died mid-transaction.*Rollback failed: transport refused: ROLLBACK/s,
    "ROLLBACK $how: both errors, the original first";
  is_deeply $backend->{captured}, [ qw(BEGIN INSERT ROLLBACK) ], "ROLLBACK $how: ROLLBACK was tried";
  is_deeply $backend->pool->{retire_log}, [ 1 ], "ROLLBACK $how: the connection was retired";
  is_deeply $backend->pool->{release_log} || [], [], "ROLLBACK $how: and never handed back";
  my $next = $backend->pool->acquire;
  my $got;
  $next->then(sub { $got = $_[0]; return });
  is $got && $got->{id}, 2, "ROLLBACK $how: with a new connection";
}

{
  my $backend = new_backend();
  my (undef, $error) = outcome($backend->txn_do_async($dies));
  like "$error", qr/coderef died mid-transaction/, 'ROLLBACK ok: the original error';
  unlike "$error", qr/Rollback failed/, 'ROLLBACK ok: no rollback error';
  is_deeply $backend->pool->{release_log}, [ 1 ], 'ROLLBACK ok: released as before';
  is_deeply $backend->pool->{retire_log} || [], [], 'ROLLBACK ok: not retired';
}

done_testing;
