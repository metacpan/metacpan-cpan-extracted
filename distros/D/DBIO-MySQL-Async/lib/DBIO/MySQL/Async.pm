package DBIO::MySQL::Async;
our $VERSION = '0.900000';
# ABSTRACT: Async MySQL/MariaDB storage for DBIO via EV::MariaDB

use strict;
use warnings;

use base 'DBIO::Base';


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::MySQL::Async::Storage');
  return $self->next::method(@info);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Async - Async MySQL/MariaDB storage for DBIO via EV::MariaDB

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  # Schema setup
  my $schema = MyApp::Schema->connect(
      'DBIO::MySQL::Async',
      {
          host      => 'localhost',
          dbname    => 'myapp',
          user      => 'myapp',
          password  => 'secret',
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

  # Sync methods still work (block the event loop)
  my @all = $schema->resultset('Artist')->all;

=head1 DESCRIPTION

Async MySQL/MariaDB support for DBIO using L<EV::MariaDB>, a non-blocking
MariaDB client built on MariaDB's C client library. Bypasses DBI
entirely for maximum performance.

Supports pipeline mode (batching queries in a single round-trip)
and prepared statements.

=head1 EVENT LOOP COMPATIBILITY

L<EV::MariaDB> uses the L<EV> event loop. This works with:

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
