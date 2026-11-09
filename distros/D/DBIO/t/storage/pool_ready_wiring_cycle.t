use strict;
use warnings;
use Test::More;
use Scalar::Util ();

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# karr k235. DBIO::Storage::PoolBase::_create_ready_connection hands the
# transport an on_connect / on_error pair, and the transport keeps them -- an
# EV::Pg or EV::MariaDB handle holds its callbacks for as long as it lives. The
# pair closed over the connection itself, and over the readiness Future that
# on_connect resolves WITH the connection. Either way round the handle reached
# itself:
#
#   connection -> on_connect -> connection
#   connection -> on_error   -> readiness Future -> its result -> connection
#
# so no pooled handle built through the readiness wiring was ever freed: not
# when the pool retired it, not when the pool shut down, not when the pool was
# gone. Each one kept its socket, its server session and its memory until the
# process exited.
#
# The claim this file pins: a connection built through the wiring lives exactly
# as long as someone other than its own callbacks holds it. Concretely:
#
#   * while the pool holds it -- cold, idle -- it is alive, although the test
#     holds it only weakly (the fix must not weaken the pool's own hold);
#   * once the pool has let go of it -- retired idle, retired dead on release
#     (k230), retired in use (k231), retired after a failed connect, dropped
#     at shutdown cold or ready, dropped with the pool, dropped as inherited in
#     a forked child (k233) -- it is destroyed as soon as no caller holds it;
#   * a caller still holding a connection keeps it alive past all of that.
#
# Destruction is counted by the fake handle's DESTROY. The test keeps its own
# handle on every connection weakly, so the count can only move when the pool
# and the callbacks are what let go. Every scenario runs against
# DBIO::Test::Future and, when installed, Future.pm -- the class the EV drivers
# resolve through, whose then-chains hold on to more than the test double does.

{
  package K235::Conn;
  our %Destroyed;
  our $Next = 0;

  # A transport handle as EV::Pg / EV::MariaDB are one: it keeps the callbacks
  # it was constructed with for as long as it lives.
  sub new {
    my ($class, %args) = @_;
    return bless { id => ++$Next, args => \%args }, $class;
  }
  sub fire_connect { $_[0]->{args}{on_connect}->() }
  sub fire_error   { $_[0]->{args}{on_error}->($_[1]) }
  sub DESTROY      { $Destroyed{ $_[0]->{id} }++ }
}

{
  package K235::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self, $conninfo) = @_;
    return $self->_create_ready_connection(conninfo => $conninfo);
  }

  # The test's handle on each connection is weak: it must never be what keeps
  # a connection alive.
  sub _new_connection {
    my $self = shift;
    my $conn = K235::Conn->new(@_);
    $self->{_last_id} = $conn->{id};
    Scalar::Util::weaken( $self->{_built}{ $conn->{id} } = $conn );
    return $conn;
  }
}

sub destroyed { $K235::Conn::Destroyed{ $_[0] } // 0 }

sub new_pool {
  my ($fc, %args) = @_;
  return K235::Pool->new(
    conninfo     => 'fake',
    size         => 2,
    future_class => $fc,
    on_error     => sub { push @{ $args{errors} }, $_[0] if $args{errors} },
  );
}

# Spawn one connection, bring it up, and hand it back: it ends idle in the pool,
# held by nobody else. Returns its id.
sub connect_idle {
  my ($pool) = @_;
  my $f = $pool->acquire;
  my $id = $pool->{_last_id};
  $pool->{_built}{$id}->fire_connect;
  $pool->release($f->get);
  return $id;
}

sub scenarios {
  my ($fc) = @_;

  # The weak captures still do the job the strong ones did: on_connect finds
  # the connection and resolves the acquire with it.
  {
    my $pool = new_pool($fc);
    my $f = $pool->acquire;
    my $id = $pool->{_last_id};
    ok !$f->is_ready, 'a cold acquire is pending';
    is destroyed($id), 0, 'cold, held by the pool only: alive';
    $pool->{_built}{$id}->fire_connect;
    ok $f->is_ready && !$f->is_failed, 'on_connect resolves the acquire';
    is $f->get->{id}, $id, 'with the connection whose on_connect fired';
  }

  # Idle in the pool, then retired.
  {
    my $pool = new_pool($fc);
    my $id = connect_idle($pool);
    is destroyed($id), 0, 'idle, held by the pool only: alive';
    $pool->_retire_connection($pool->{_built}{$id});
    is $pool->size, 0, 'retired idle connection left the pool';
    is destroyed($id), 1, 'retired idle connection is destroyed';
  }

  # Reported dead while checked out, retired on release (k230).
  {
    my $pool = new_pool($fc);
    my $id = connect_idle($pool);
    my $conn = $pool->acquire->get;
    $pool->_mark_connection_dead($conn);
    $pool->release($conn);
    is $pool->size, 0, 'dead connection was retired on release';
    is destroyed($id), 0, 'the caller still holds it: alive';
    undef $conn;
    is destroyed($id), 1, 'retired dead connection is destroyed once the caller lets go';
  }

  # Retired while checked out (k231).
  {
    my $pool = new_pool($fc);
    my $id = connect_idle($pool);
    my $conn = $pool->acquire->get;
    $pool->_retire_in_use_connection($conn);
    undef $conn;
    is destroyed($id), 1, 'connection retired in use is destroyed once the caller lets go';
  }

  # The connect fails: the readiness failure retires it.
  {
    my @errors;
    my $pool = new_pool($fc, errors => \@errors);
    my $f = $pool->acquire;
    my $id = $pool->{_last_id};
    $pool->{_built}{$id}->fire_error('could not connect');
    ok $f->is_failed, 'the acquire failed with the connect';
    is_deeply \@errors, ['could not connect'], "the pool's on_error still ran";
    undef $f;
    is destroyed($id), 1, 'connection whose connect failed is destroyed';
  }

  # Shutdown with a ready connection idle.
  {
    my $pool = new_pool($fc);
    my $id = connect_idle($pool);
    $pool->shutdown;
    is destroyed($id), 1, 'shutdown destroys the ready idle connection';
  }

  # Shutdown with a connection still connecting.
  {
    my $pool = new_pool($fc);
    my $f = $pool->acquire;
    my $id = $pool->{_last_id};
    $pool->shutdown;
    ok $f->is_failed, 'the cold acquire failed with the shutdown';
    undef $f;
    is destroyed($id), 1, 'shutdown destroys the cold connection';
  }

  # Shutdown with a connection checked out: the caller's hold outlives the
  # pool's, and a late callback on it is harmless.
  {
    my @errors;
    my $pool = new_pool($fc, errors => \@errors);
    my $id = connect_idle($pool);
    my $conn = $pool->acquire->get;
    $pool->shutdown;
    is destroyed($id), 0, 'checked out across shutdown: the caller still holds it';
    ok eval { $conn->fire_error('late'); $conn->fire_connect; 1 },
      'a late on_error / on_connect after shutdown does not die';
    is_deeply \@errors, ['late'], "and the late error still reaches the pool's on_error";
    undef $conn;
    is destroyed($id), 1, 'destroyed once the caller lets go';
  }

  # The pool itself goes away (its DESTROY shuts it down).
  {
    my $id;
    {
      my $pool = new_pool($fc);
      $id = connect_idle($pool);
    }
    is destroyed($id), 1, 'dropping the pool destroys its idle connection';
  }

  # A forked child drops what it inherited (k233): dropped, never closed by the
  # pool, and -- no longer a cycle -- freed. Closing the parent's session from
  # the handle's destructor is the transport's to prevent, as k233 documents.
  {
    my $pool = new_pool($fc);
    my $id = connect_idle($pool);
    $pool->{_owner_pid} = -1;
    $pool->_verify_pid;
    is $pool->size, 0, 'the inherited connection was dropped';
    is destroyed($id), 1, 'the dropped inherited connection is destroyed';
  }
}

subtest 'future_class DBIO::Test::Future' => sub {
  scenarios('DBIO::Test::Future');
};

SKIP: {
  skip 'Future not installed', 1 unless eval { require Future; 1 };
  subtest 'future_class Future' => sub { scenarios('Future') };
}

done_testing;
