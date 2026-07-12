package DBIO::Async::Storage;
# ABSTRACT: Future::IO transport backend for DBIO async storage

use strict;
use warnings;
use base 'DBIO::Storage::Async';

use Carp 'croak';
use Future;
use Future::IO qw( POLLIN );
use DBIO::Async::Pool;
use DBIO::Async::TransactionContext;
use namespace::clean;



sub future_class { 'Future' }


sub transport_capabilities { qw(on_connect_replay) }


sub pool {
  my $self = shift;
  $self->{pool} ||= do {
    my %args = (
      storage  => $self,
      size     => $self->{_pool_size},
      on_error => sub { warn "DBIO::Async pool error: $_[0]\n" },
    );

    if (my $provider = $self->_conninfo_provider) {
      $args{conninfo_provider} = $provider;
    }
    else {
      $args{conninfo} = $self->{_conninfo};
    }

    DBIO::Async::Pool->new(%args);
  };
}


sub _async_broker_conninfo {
  my ($self, $mode) = @_;
  my ($conninfo) = $self->_normalize_async_connect_info(
    $self->_current_async_connect_info($mode)
  );
  return $conninfo;
}

# --- Future::IO transport ---
# Concrete overrides of the DBIO::Storage::Async transport seams. The inherited
# Model-B orchestration (_run_crud & friends) calls these; they route through
# the Future::IO watcher seam below.


sub _query_async {
  my ($self, $sql, $bind) = @_;
  $bind //= [];
  $sql = $self->_transform_sql($sql);

  $self->_debug_query($sql, $bind) if $self->{debug};

  return $self->pool->acquire->then(sub {
    my $conn = shift;
    return $self->_await_query_result($conn, $sql, $bind)
      ->on_ready(sub { $self->pool->release($conn) });
  });
}


sub _query_async_pinned {
  my ($self, $conn, $sql, $bind) = @_;
  $bind //= [];
  $sql = $self->_transform_sql($sql);

  $self->_debug_query($sql, $bind) if $self->{debug};

  return $self->_await_query_result($conn, $sql, $bind);
}

sub _debug_query {
  my ($self, $sql, $bind) = @_;
  my $bind_str = join(', ', map { defined $_ ? "'$_'" : 'NULL' } @$bind);
  warn "$sql: $bind_str\n";
}

# --- Future::IO Watcher Seam ---
#
# These methods isolate the Future::IO dependency. A driver that uses its
# own event-loop integration overrides _query_async / _query_async_pinned
# entirely and never calls these.


sub _await_readable {
  my ($self, $conn) = @_;
  return Future::IO->poll($self->_conn_poll_fh($conn), POLLIN);
}


sub _conn_poll_fh {
  my ($self, $conn) = @_;
  return $conn->{_dbio_async_poll_fh} ||= do {
    my $fd = $self->_conn_fileno($conn);
    open my $fh, '+<&', $fd
      or croak 'Cannot dup async connection fd '
             . (defined $fd ? $fd : 'undef') . " for Future::IO poll: $!";
    $fh;
  };
}


sub _await_conn_ready {
  my ($self, $conn) = @_;
  return Future->done($conn) if $self->_conn_ready($conn);

  return Future->call(sub {
    return $self->_await_readable($conn)->then(sub {
      return $self->_await_conn_ready($conn);
    });
  });
}


sub _await_query_result {
  my ($self, $conn, $sql, $bind) = @_;

  return Future->call(sub {
    $self->_submit_query($conn, $sql, $bind);
    return $self->_await_readable($conn)->then(sub {
      return $self->_collect_result($conn, $sql, $bind);
    });
  });
}

# --- DB-specific seam hooks ---
#
# Filled in by a concrete DBD subclass; each croaks until provided. The
# SQL-shaping and pipeline seams are inherited as croaking seams from
# DBIO::Storage::Async. These are the ones specific to the Future::IO transport,
# plus the two whose inherited base default (identity conninfo / a named txn
# context) does not fit an abstract transport -- a concrete backend must name
# its own conninfo shape and transaction context.

sub _submit_query {
  croak 'Subclass must override _submit_query($conn, $sql, $bind)';
}

sub _collect_result {
  croak 'Subclass must override _collect_result($conn, $sql, $bind)';
}

sub _normalize_conninfo {
  croak 'Subclass must override _normalize_conninfo($info)';
}

sub _create_pool_connection {
  croak 'Subclass must override _create_pool_connection($conninfo)';
}

sub _shutdown_pool_connection {
  croak 'Subclass must override _shutdown_pool_connection($conn)';
}

sub _conn_ready {
  croak 'Subclass must override _conn_ready($conn)';
}

sub _conn_fileno {
  croak 'Subclass must override _conn_fileno($conn) when _conn_ready can return false';
}

sub _txn_context_class {
  croak 'Subclass must override _txn_context_class';
}

sub _txn_conn_accessor {
  croak 'Subclass must override _txn_conn_accessor';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Async::Storage - Future::IO transport backend for DBIO async storage

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

The C<future_io> async backend (ADR 0030): one loop-agnostic transport that
drives a driver's own non-blocking DBD binding through L<Future::IO>. The
event loop is chosen by installing a C<Future::IO::Impl::*> adapter, not by
picking a distribution.

The B<Model-B orchestration> -- connect-info normalisation, the CRUD runner
(L<DBIO::Storage::Async/_run_crud> with its pooled and pinned runners), INSERT
returned-columns mapping, L<DBIO::Storage::Async/txn_do_async> bracketing
through the generic L<DBIO::Storage::Async::TransactionContext>, and the
L<DBIO::Storage::Async/pipeline> scaffold -- is inherited concretely from
L<DBIO::Storage::Async> (ADR 0030 §4). This class supplies only the
B<transport>: the L<Future::IO> query execution (L</_query_async> /
L</_query_async_pinned> over L</_await_query_result>), the L<Future>
implementation (L</future_class>) and the connection pool (L</pool>), plus the
DB-specific seam hooks a concrete DBD subclass fills in.

=head1 METHODS

=head2 future_class

Returns C<'Future'> -- this backend uses L<Future> from CPAN.

=head2 transport_capabilities

  my @caps = DBIO::Async::Storage->transport_capabilities;   # ('on_connect_replay')

Class method (see L<DBIO::Storage::Async/transport_capabilities>). Declares the
named transport capabilities this C<future_io> transport provides, so
L<DBIO::Storage::DBI/_async_storage> lets an async extension layer that declares
a matching C<required_transport_capabilities> compose onto it (and croaks on a
shortfall rather than silently dropping the feature).

This transport declares C<on_connect_replay>: its pool
(L<DBIO::Async::Pool>, a L<DBIO::Storage::PoolBase>) drives core's
L<DBIO::Storage::Async/_setup_pool_connection> on every freshly-spawned
connection, and the C<< { dbh => $dbh } >> connection shape is handled by the
base C<_run_pool_connect_statement> -- so each pooled async connection replays
the owning sync storage's C<on_connect_do>/C<on_connect_call> (and the
C<on_disconnect_*> actions at shutdown) end to end (karr #68 seam). A concrete
DBD subclass inherits this obligation for free.

=head2 pool

Returns the L<DBIO::Async::Pool> connection pool, created lazily on first
access. Fed the per-spawn C<conninfo_provider> when an AccessBroker is attached
(see L<DBIO::Storage::Async/_conninfo_provider>), otherwise the static
conninfo.

=head2 _async_broker_conninfo

  my $conninfo = $storage->_async_broker_conninfo($mode);

AccessBroker seam (see L<DBIO::Storage::Async/ACCESSBROKER CONSUMPTION>):
return one fresh, storage-native conninfo for a single new pool connection,
built from the current broker credentials via the inherited normalisation.

=head2 _query_async

Transport override: execute a query on a freshly-acquired pooled connection,
releasing it once the Future is ready.

Receives SQL in the C<sql_maker> C<?>-placeholder dialect (the core #70 seam
contract) and shapes it into the driver's own dialect B<internally>, up front,
through L</_transform_sql> before the query reaches the wire -- callers no longer
pre-shape. The C<?>-E<gt>C<$N>-style rewrite is idempotent on already-shaped SQL
(no bare C<?> left to touch), which is what keeps the transition window safe
while core still shapes at its own call site.

=head2 _query_async_pinned

Transport override: like L</_query_async> but runs on the supplied pinned
connection and does B<not> release it -- used for queries inside a pinned
transaction. Shapes the incoming C<?>-dialect SQL internally through
L</_transform_sql> exactly as L</_query_async> does.

=head2 _await_readable

  my $future = $storage->_await_readable($conn);

Returns a Future that becomes ready once the connection's socket is readable.
The single seam through which this transport touches L<Future::IO>: a concrete
driver's L</_collect_result> that must wait for more of a result also calls this
rather than re-implementing the fd wrapping. The filehandle C<poll> needs is
supplied by L</_conn_poll_fh>.

=head2 _conn_poll_fh

  my $fh = $storage->_conn_poll_fh($conn);

The stable poll filehandle for C<$conn>, created lazily on first use and cached
on the connection for its whole life. L<Future::IO-E<gt>poll> requires a real
filehandle, but a driver's L</_conn_fileno> hands back the raw integer socket fd
(e.g. DBD::Pg's C<pg_socket>). The C<< '+<&' >> open mode dups that fd (via
C<dup(2)>) into an independent filehandle, so closing this handle never touches
the driver's own socket.

The dup is cached B<per connection> for a correctness reason, not merely for
speed. L<Future::IO> watches the filehandle and, once the poll resolves,
unwatches it B<by its fileno> -- but its impls mark the Future done I<before>
they unwatch. A fresh-dup-per-poll handle closed the moment its poll resolved
would already be gone when the loop unwatches: C<< $fh->fileno >> returns
C<undef>, the loop's watch table is corrupted, and the freed fd -- reused by the
next dup -- collides with the stale watch (observed as
C<pg_ready: No asynchronous query is running> on the following query). Reusing
one stable handle for every poll on a connection keeps the fileno valid across
the whole watch/unwatch cycle. The dup fd dies with the connection it mirrors,
when C<$conn> is torn down.

Cached on the connection hashref under the reserved key C<_dbio_async_poll_fh>;
a driver whose connection is not a hashref must supply its own caching.

=head2 _await_conn_ready

  my $future = $storage->_await_conn_ready($conn);

Returns a Future that resolves to C<$conn> once the connection is ready for
queries. Uses L</_conn_ready> to check readiness and L</_await_readable> to
wait on the fd from L</_conn_fileno> when not yet ready.

=head2 _await_query_result

  my $future = $storage->_await_query_result($conn, $sql, $bind);

Submits the query via L</_submit_query>, waits for the connection socket to
become readable via L</_await_readable>, and collects the result via
L</_collect_result>. Returns a Future resolving to the result rows.

=head1 SEAM HOOKS

Overridden by a concrete DBD subclass; each croaks until provided.

=head2 Query execution / connection lifecycle

=over 4

=item * L</_submit_query> -- send query bytes to the wire (non-blocking)

=item * L</_collect_result> -- read the result from the wire

=item * L</_conn_ready> -- is the connection ready for queries?

=item * L</_conn_fileno> -- socket fd for the L<Future::IO> watcher seam

=item * L</_create_pool_connection> / L</_shutdown_pool_connection> -- pool
connection lifecycle

=back

=head2 SQL / connect-info / transaction shaping

The SQL-shaping seams (C<sql_maker_class>, C<_transform_sql>,
C<_post_insert_sql>) and the pipeline seams
(C<_pipeline_enter>/C<_pipeline_sync>/C<_pipeline_exit>) are inherited as
croaking seams from L<DBIO::Storage::Async>. This transport additionally
requires:

=over 4

=item * L</_normalize_conninfo> -- DB-specific connect-info conversion

=item * L</_txn_context_class> / L</_txn_conn_accessor> -- the
transaction-context class and the pinned-connection accessor key

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
