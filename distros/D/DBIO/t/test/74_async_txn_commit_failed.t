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

# karr k372: a COMMIT that fails ends the async transaction. The server may
# keep the transaction open (a deferred constraint checked at COMMIT), so
# ROLLBACK goes out on the pinned connection. If it works the connection goes
# back to the pool; if it fails, or its dispatch throws, the connection is
# retired and never handed back. Either way the transaction fails with the
# error of the COMMIT, never that of the ROLLBACK, and the context is over.
# Only a COMMIT the server refused (a DBIO::Exception::Server, ADR 0062) starts
# that: a COMMIT the transport refuses or that was cancelled (a plain error, no
# server answer) is no failed COMMIT, nothing is rolled back or retired on its
# account, and the failure is the COMMIT's object -- the Server exception with
# its sqlstate, never stringified, never replaced by the ROLLBACK's.
# Fixture: a fake wire over a PoolBase of size 1 that counts releases and
# retirements.

{
  package K372::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K372::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection { K372::Conn->new(++$_[0]->{_next_id}) }

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
  package K372::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }

  sub pool {
    return $_[0]->{pool} ||= K372::Pool->new(
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
  my $backend = K372::Backend->new($schema);
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

my $refused = sub { server_error("deferred constraint\n", '23505') };

my $body = sub {
  my ($ctx) = @_;
  return $ctx->insert_async('artist', { name => 'Miles Davis' });
};

# ROLLBACK works: sent after the failed COMMIT, connection released, not retired.
{
  my $backend = new_backend(fail => { COMMIT => $refused->() });
  my (undef, $error) = outcome($backend->txn_do_async($body));
  like "$error", qr/COMMIT failed: deferred constraint/, 'COMMIT fails: its error is the Future\'s';
  ok blessed($error) && $error->isa('DBIO::Exception::Server'), 'COMMIT fails: the Future fails with the Server object, not a string';
  is $error->sqlstate, '23505', 'COMMIT fails: its sqlstate arrives';
  is $error->context, 'COMMIT', 'COMMIT fails: context COMMIT';
  is_deeply $backend->{captured}, [ qw(BEGIN INSERT COMMIT ROLLBACK) ],
    'COMMIT fails: a ROLLBACK follows on the pinned connection';
  is_deeply $backend->pool->{release_log}, [ 1 ], 'COMMIT fails: the connection went back once';
  is_deeply $backend->pool->{retire_log} || [], [], 'COMMIT fails: it was not retired';
}

# ROLLBACK fails: connection retired, not released, commit error wins.
for my $how (qw(fail throw)) {
  my $backend = new_backend(
    fail => { COMMIT => $refused->(), ($how eq 'fail' ? (ROLLBACK => server_error("no rollback\n", '25P01')) : ()) },
    ($how eq 'throw' ? (throw => { ROLLBACK => "no rollback\n" }) : ()),
  );
  my $f = eval { $backend->txn_do_async($body) };
  ok $f && $f->is_failed, "ROLLBACK $how: txn_do_async returns a failed Future";
  my (undef, $error) = $f ? outcome($f) : (undef, $@);
  like "$error", qr/COMMIT failed: deferred constraint/, "ROLLBACK $how: the COMMIT's error";
  unlike "$error", qr/no rollback/, "ROLLBACK $how: not the ROLLBACK's";
  ok blessed($error) && $error->isa('DBIO::Exception::Server') && $error->sqlstate eq '23505'
    && $error->context eq 'COMMIT', "ROLLBACK $how: the COMMIT's Server object itself";
  is_deeply $backend->{captured}, [ qw(BEGIN INSERT COMMIT ROLLBACK) ],
    "ROLLBACK $how: ROLLBACK was tried";
  is_deeply $backend->pool->{retire_log}, [ 1 ], "ROLLBACK $how: the connection was retired";
  is_deeply $backend->pool->{release_log} || [], [],
    "ROLLBACK $how: and never handed back to the pool";
}

# COMMIT not refused by the server (the transport refuses it, or it was
# cancelled): everything stays as before k372 -- no ROLLBACK, no retirement,
# the connection goes back, the failure is the COMMIT's own text.
for my $why ("Statement refused: the transaction's COMMIT is already issued\n", "cancelled before it was answered\n") {
  my $backend = new_backend(fail => { COMMIT => $why });
  my (undef, $error) = outcome($backend->txn_do_async($body));
  like "$error", qr/\ACOMMIT failed: /, "COMMIT not refused by the server ($why): COMMIT's error";
  is_deeply $backend->{captured}, [ qw(BEGIN INSERT COMMIT) ],
    'COMMIT not refused by the server: no ROLLBACK is sent';
  is_deeply $backend->pool->{release_log}, [ 1 ], 'COMMIT not refused by the server: released as before';
  is_deeply $backend->pool->{retire_log} || [], [], 'COMMIT not refused by the server: not retired';
}

# Control: a good COMMIT sends no ROLLBACK.
{
  my $backend = new_backend();
  my (undef, $error) = outcome($backend->txn_do_async($body));
  is $error, undef, 'good COMMIT: succeeds';
  is_deeply $backend->{captured}, [ qw(BEGIN INSERT COMMIT) ], 'good COMMIT: no ROLLBACK';
  is_deeply $backend->pool->{release_log}, [ 1 ], 'good COMMIT: released';
}

done_testing;
