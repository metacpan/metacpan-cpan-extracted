package DBIO::PostgreSQL::EV;
our $VERSION = '0.900001';
# ABSTRACT: Async PostgreSQL storage for DBIO via EV::Pg

use strict;
use warnings;

use base 'DBIO::Base';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::EV - Async PostgreSQL storage for DBIO via EV::Pg

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components(qw(PostgreSQL PostgreSQL::EV));

  package MyApp::Schema::Result::Artist;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(qw( id name ));

  # Async is opt-in per connection
  my $schema  = MyApp::Schema->connect(
      'dbi:Pg:dbname=myapp', $user, $pass,
      { async => 'ev' },
  );
  my $storage = $schema->storage;        # DBIO::PostgreSQL::Storage

  # Sync still works exactly as before
  my @all = $schema->resultset('Artist')->all;

  # Storage-level async runs real non-blocking over EV::Pg
  $storage->select_async($source, $select, $where, $attrs)->then(sub {
      my @rows = @_;
      ...
  });

  # Pipeline mode, LISTEN/NOTIFY and COPY are async-only — not routed
  # through the sync storage. Reach them on the embedded async backend
  # via $storage->async (see DBIO::PostgreSQL::EV::Storage):
  $storage->async->listen('changelog', sub { my ($chan, $payload) = @_; ... });
  $storage->async->copy_in('artist', [qw( id name )], sub { my $put = shift; ... });

=head1 DESCRIPTION

Real async PostgreSQL for DBIO via L<EV::Pg>, a non-blocking client built on
libpq's async protocol. The async work itself lives in
L<DBIO::PostgreSQL::EV::Storage>.

This module is an B<inert marker component>. Loading it via
C<< load_components('PostgreSQL::EV') >> does B<not> by itself switch the
storage to async: it only tags the schema so the L<DBIO::PostgreSQL::Storage>
MRO arm can resolve the C<ev> mode. Async is an explicit, per-connection
choice (ADR 0030); you opt in at C<connect> time with
C<< { async => 'ev' } >>:

  my $schema = MyApp::Schema->connect(
      $dsn, $user, $pass,
      { async => 'ev' },
  );

The C<ev> mode resolves to L<DBIO::PostgreSQL::EV::Storage> (this
distribution) and is registered by L<DBIO::PostgreSQL::Storage> (the sync
driver, in the L<DBIO::PostgreSQL> distribution). With C<{ async => 'ev' }>
on a schema that has loaded this component, C<< $rs->all >> still runs sync
over DBI/DBD::Pg, while the storage-level C<*_async> methods run B<real>
async over EV::Pg against the same connection info.

Without the opt-in, the C<*_async> methods degrade to the universal forked
fallback (L<DBIO::Forked::Storage>, core ADR 0029); no compile-time dependency
on EV is added to the sync driver.

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
