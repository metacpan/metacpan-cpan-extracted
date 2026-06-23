package DBIO::PostgreSQL::Async;
our $VERSION = '0.900000';
# ABSTRACT: Async PostgreSQL storage for DBIO via EV::Pg

use strict;
use warnings;

use base 'DBIO::Base';


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::PostgreSQL::Async::Storage');
  return $self->next::method(@info);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Async - Async PostgreSQL storage for DBIO via EV::Pg

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  # Schema setup
  my $schema = MyApp::Schema->connect(
      'DBIO::PostgreSQL::Async',
      {
          host      => 'localhost',
          dbname    => 'myapp',
          user      => 'myapp',
          pool_size => 10,
      },
  );

  # Async queries return Futures
  $schema->resultset('Artist')->all_async->then(sub {
      my @artists = @_;
      say $_->name for @artists;
  });

  # Pipeline mode — batch queries in one round-trip
  $schema->storage->pipeline(sub {
      my @futures;
      push @futures, $schema->resultset('Artist')
          ->create_async({ name => $_ }) for @names;
      return Future->needs_all(@futures);
  });

  # LISTEN/NOTIFY
  $schema->storage->listen('changelog', sub {
      my ($channel, $payload) = @_;
      say "Event: $payload";
  });

  # Sync methods still work (block the event loop)
  my @all = $schema->resultset('Artist')->all;

=head1 DESCRIPTION

Async PostgreSQL support for DBIO using L<EV::Pg>, a non-blocking
PostgreSQL client built on libpq's async protocol. Bypasses DBI
entirely for maximum performance.

Supports pipeline mode (batching queries in a single round-trip),
prepared statements, COPY, and LISTEN/NOTIFY.

=head1 EVENT LOOP COMPATIBILITY

L<EV::Pg> uses the L<EV> event loop. This works with:

=over 4

=item * L<EV> directly

=item * L<AnyEvent> (uses EV as backend when available)

=item * L<IO::Async> via L<IO::Async::Loop::EV>

=item * L<Mojolicious> via L<Mojo::Reactor::EV>

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
