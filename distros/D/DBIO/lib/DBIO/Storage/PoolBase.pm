package DBIO::Storage::PoolBase;
# ABSTRACT: Shared connection pool mechanics for async DBIO drivers

use strict;
use warnings;
use base 'DBIO::Storage::Pool';

use Carp 'croak';
use namespace::clean;



sub new {
  my ($class, %args) = @_;
  croak('conninfo or conninfo_provider required')
    unless $args{conninfo} || $args{conninfo_provider};

  my $self = bless {
    conninfo          => $args{conninfo},
    conninfo_provider => $args{conninfo_provider},
    max_size          => $args{size} || 5,
    on_error          => $args{on_error} || sub { warn "Pool error: $_[0]\n" },
    _connections      => [],
    _idle             => [],
    _waiters          => [],
  }, $class;

  $self->{future_class} = $args{future_class} if $args{future_class};
  my $fc = $self->future_class;
  eval "require $fc" or croak "Cannot load future class $fc: $@";

  return $self;
}


sub future_class { $_[0]->{future_class} || 'Future' }


sub acquire {
  my ($self) = @_;

  if (@{ $self->{_idle} }) {
    return $self->future_class->done(pop @{ $self->{_idle} });
  }

  if (@{ $self->{_connections} } < $self->{max_size}) {
    my $conn = $self->_spawn_connection;
    return $self->future_class->done($conn);
  }

  my $f = $self->future_class->new;
  push @{ $self->{_waiters} }, $f;
  return $f;
}


sub acquire_txn {
  my $self = shift;
  return $self->acquire;  # same behavior, caller manages lifecycle
}


sub release {
  my ($self, $conn) = @_;

  if (@{ $self->{_waiters} }) {
    my $waiter = shift @{ $self->{_waiters} };
    $waiter->done($conn);
    return;
  }

  push @{ $self->{_idle} }, $conn;
}


sub size { scalar @{ $_[0]->{_connections} } }


sub available { scalar @{ $_[0]->{_idle} } }


sub max_size { $_[0]->{max_size} }


sub shutdown {
  my $self = shift;
  for my $conn (@{ $self->{_connections} }) {
    eval { $self->_shutdown_connection($conn) };
  }
  $self->{_connections} = [];
  $self->{_idle} = [];
}

sub _spawn_connection {
  my $self = shift;
  my $conninfo = $self->{conninfo_provider}
    ? $self->{conninfo_provider}->()
    : $self->{conninfo};

  my $conn = $self->_create_connection($self->_transform_conninfo($conninfo));
  push @{ $self->{_connections} }, $conn;
  return $conn;
}


sub _create_connection { croak 'Subclass must override _create_connection' }


sub _shutdown_connection {}


sub _transform_conninfo { $_[1] }

sub DESTROY {
  my $self = shift;
  $self->shutdown;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::PoolBase - Shared connection pool mechanics for async DBIO drivers

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  package DBIO::PostgreSQL::Async::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self, $conninfo) = @_;
    return EV::Pg->new(
      conninfo   => $conninfo,
      on_connect => sub {},
      on_error   => $self->{on_error},
    );
  }

  sub _shutdown_connection { $_[1]->finish }

  sub _transform_conninfo { conninfo_string($_[1]) }

=head1 DESCRIPTION

Concrete implementation of the L<DBIO::Storage::Pool> contract hosting
the pool mechanics shared by all async drivers: idle-pool handling,
capacity-bounded connection creation, the waiter queue and shutdown.

Drivers subclass this and supply only the engine seam:

=over 4

=item *

L</_create_connection> -- build one driver connection (required)

=item *

L</_shutdown_connection> -- close one driver connection (optional,
defaults to a no-op)

=item *

L</_transform_conninfo> -- adapt the stored connect info into whatever
shape the driver's connection constructor expects (optional, defaults
to passing it through unchanged)

=item *

L</future_class> -- the Future implementation used for L</acquire>
(optional, defaults to L<Future>)

=back

=head1 METHODS

=head2 new

  my $pool = Driver::Pool->new(
      conninfo => 'dbname=myapp',
      size     => 10,
      on_error => sub { warn $_[0] },
  );

Requires C<conninfo> or C<conninfo_provider> (a coderef returning fresh
connect info per connection). C<size> caps the pool (default 5).
C<future_class> overrides the Future implementation per instance.

=head2 future_class

The Future implementation backing L</acquire>. Defaults to L<Future>;
override in a subclass or pass C<future_class> to L</new>.

=head2 acquire

Returns an idle connection wrapped in a done Future. Creates a new
connection if the pool has capacity. If all connections are busy and
the pool is at max size, queues the request and returns a pending
Future that resolves on the next L</release>.

=head2 acquire_txn

Acquire a connection pinned for exclusive transaction use.
Same as L</acquire> but the connection will not be released
back to the idle pool until explicitly released.

=head2 release

  $pool->release($conn);

Return a connection to the idle pool. If waiters are queued, hands the
connection straight to the oldest waiter instead.

=head2 size

Total connections (active + idle).

=head2 available

Number of idle connections.

=head2 max_size

Configured maximum pool size.

=head2 shutdown

Close all connections via L</_shutdown_connection> and clear the pool.

=head2 _create_connection

  sub _create_connection { my ($self, $conninfo) = @_; ... }

Required driver hook: build and return one connection from the
(already transformed) connect info. The pool tracks the connection;
do not push it anywhere yourself.

=head2 _shutdown_connection

  sub _shutdown_connection { my ($self, $conn) = @_; $conn->finish }

Optional driver hook: close one connection during L</shutdown>.
Defaults to a no-op; exceptions are swallowed by the caller.

=head2 _transform_conninfo

  sub _transform_conninfo { my ($self, $conninfo) = @_; ... }

Optional driver hook: adapt stored connect info into the shape the
driver's connection constructor expects (e.g. a libpq conninfo
string). Defaults to returning it unchanged.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
