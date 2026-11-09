use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k400 (3). An unbound `$storage->..._async` started while the coderef of a
# txn_do_async runs is not in the transaction: it takes a connection of its own.
# Under debug (DBIO_TRACE) the storage says so. Without debug it is silent. The
# text names the operation and never a value or a bind.

{
  package K400B::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K400B::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection   { K400B::Conn->new(++$_[0]->{_next_id}) }
  sub _shutdown_connection { }
}

{
  package K400B::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }

  sub pool {
    my $self = shift;
    return $self->{pool} ||= K400B::Pool->new(
      conninfo => 'fake', size => 3, future_class => 'DBIO::Test::Future',
    );
  }

  sub _query_async {
    my ($self, $sql, $bind) = @_;
    return $self->future_class->done(1);
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    return $self->future_class->done(1);
  }
}

sub new_backend {
  my (%knobs) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $backend = K400B::Backend->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{debug} = $knobs{debug} ? 1 : 0;
  return $backend;
}

sub warnings_of {
  my ($code) = @_;
  my @w;
  local $SIG{__WARN__} = sub { push @w, @_ };
  $code->();
  return @w;
}

my $SECRET = 'bind-value-k400';

# --- debug: unbound call in the coderef warns ------------------------------------
{
  my $backend = new_backend(debug => 1);
  my @w = warnings_of(sub {
    $backend->txn_do_async(sub {
      $backend->delete_async('artist', { name => $SECRET });
      return $backend->future_class->done;
    });
  });
  is scalar @w, 1, 'debug: one warning for the unbound call in the coderef';
  like $w[0], qr/delete_async on the storage ran while a txn_do_async coderef was running/,
    'debug: it names the operation and the transaction';
  unlike $w[0], qr/\Q$SECRET\E|artist/, 'debug: and no value, bind or table';
}

# --- debug: calls on the context and after the transaction are silent ----------------
{
  my $backend = new_backend(debug => 1);
  my @w = warnings_of(sub {
    $backend->txn_do_async(sub {
      my ($ctx) = @_;
      return $ctx->delete_async('artist', { id => 1 });
    });
    $backend->delete_async('artist', { id => 2 });
  });
  is scalar @w, 0, 'debug: a call on the context, and one after the transaction, do not warn';
}

# --- debug: a coderef that dies does not leave the storage marked -------------------
{
  my $backend = new_backend(debug => 1);
  my @w = warnings_of(sub {
    $backend->txn_do_async(sub { die "boom\n" });
    $backend->delete_async('artist', { id => 2 });
  });
  is scalar @w, 0, 'debug: after a coderef that died the storage is not marked';
}

# --- no debug: silent -------------------------------------------------------------
{
  my $backend = new_backend(debug => 0);
  my @w = warnings_of(sub {
    $backend->txn_do_async(sub {
      $backend->delete_async('artist', { id => 1 });
      return $backend->future_class->done;
    });
  });
  is scalar @w, 0, 'no debug: the unbound call in the coderef is silent';
}

done_testing;
