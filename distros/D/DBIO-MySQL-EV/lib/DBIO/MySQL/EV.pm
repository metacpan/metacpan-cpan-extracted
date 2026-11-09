package DBIO::MySQL::EV;
our $VERSION = '0.900004';
# ABSTRACT: Async MySQL/MariaDB storage for DBIO via EV::MariaDB

use strict;
use warnings;

use base 'DBIO::Base';


# Note for cross-repo readers (karr k14 / dbio-mysql-ev):
# A previous version of this file overrode `connection()` to force
# `storage_type('+DBIO::MySQL::EV::Storage')` on every connect. That hijack
# contradicted the inert-component model (ADR 0030): a loadable component
# must not switch the schema's storage class on its own. PostgreSQL's
# equivalent `DBIO::PostgreSQL::EV` has never had such an override; the
# MySQL copy was removed for parity. The `ev` mode registration itself has
# shipped in the dbio-mysql distribution since commit 8515206 --
# DBIO::MySQL::Storage calls register_async_mode(ev => ...) on the sync
# driver storage -- and is intentionally NOT duplicated here: the
# mode->transport map belongs on the class whose MRO the resolver walks.

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::EV - Async MySQL/MariaDB storage for DBIO via EV::MariaDB

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  # Schema setup
  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components(qw(MySQL));

  # Async is opt-in per connection
  my $schema = MyApp::Schema->connect(
      $dsn, $user, $pass,
      { async => 'ev' },
  );

  # Async queries return Futures
  $schema->resultset('Artist')->all_async->then(sub {
      my @artists = @_;
      say $_->name for @artists;
  });

  # Concurrency, not batching: there is no pipeline() to bracket here
  # (ADR 0009). Issue several *_async calls without awaiting between them and
  # gather them -- each runs on its own pooled connection.
  my @futures = map {
      $schema->resultset('Artist')->create_async({ name => $_ })
  } @names;
  Future->needs_all(@futures)->then(sub { ... });

  # Sync methods still work (block the event loop)
  my @all = $schema->resultset('Artist')->all;

=head1 DESCRIPTION

Async MySQL/MariaDB support for DBIO using L<EV::MariaDB>, a non-blocking
MariaDB client built on MariaDB's C client library. Bypasses DBI
entirely for maximum performance.

This transport has B<no> explicit pipeline mode. EV::MariaDB exposes no
primitive to bracket a batch, so L<DBIO::MySQL::EV::Storage> overrides none of
core's C<_pipeline_enter> / C<_pipeline_sync> / C<_pipeline_exit> seams and
declares no C<pipeline> transport capability. C<< $storage->pipeline >> is
refused: it returns a failed L<Future> saying that C<DBIO::MySQL::EV::Storage>
does not support C<pipeline()>, without taking a connection from the pool and
without running the batch (L<DBIO::Storage::Async/pipeline>, ADR 0009).

What this driver offers instead is
B<concurrency, not batching>: issue several C<*_async> calls without awaiting
between them and gather them with C<< Future->needs_all >>. Each of those runs
on its B<own> pooled connection, so the statements overlap on the wire.
EV::MariaDB does batch consecutive queries issued on a I<single> connection (up
to 64 in flight), but the pooled CRUD path takes a connection per call, so
wire-level batching is not something this driver can promise.

Async is an explicit, per-connection choice (ADR 0030): you opt in at
C<connect> time with C<< { async => 'ev' } >>:

  my $schema = MyApp::Schema->connect(
      $dsn, $user, $pass,
      { async => 'ev' },
  );

The C<ev> mode resolves to L<DBIO::MySQL::EV::Storage> (this distribution) and
is registered by L<DBIO::MySQL::Storage> (the sync driver, in the L<DBIO::MySQL>
distribution) with
C<< register_async_mode( ev => 'DBIO::MySQL::EV::Storage' ) >>. Nothing in this
distribution registers anything; the mapping deliberately lives on the driver
storage, whose MRO the resolver walks. With C<{ async => 'ev' }>, the C<*_async>
methods on the resulting storage run real non-blocking queries over
L<EV::MariaDB>.

A connection made from an L<DBIO::AccessBroker> takes the same options beside
the broker -- C<< connect($broker, { async => 'ev', pool_size => 3 }) >>: the
transport declares the C<broker_connect_options> capability
(L<DBIO::MySQL::EV::Storage/transport_capabilities>), so C<pool_size> sizes its
pool, and the broker is asked again for every pooled connection.

An L<EV::MariaDB> parameter for the connections (C<charset>,
C<connect_timeout>, C<ssl_ca>, ...) belongs in the broker's answer
(L<DBIO::MySQL::EV::Storage/_async_broker_conninfo>). Given beside the broker,
C<< connect($broker, { async => 'ev', charset => ... }) >>, such a parameter
is not applied to any connection, and the transport refuses to be built with
it rather than connect without it
(L<DBIO::MySQL::EV::Storage/connect_info>).

C<< $storage->insert_async >> resolves with the returned-columns
I<hashref> (autoinc PK overlaid onto the supplied insert data), per ADR 0031
§3 -- MySQL has no RETURNING clause, so the EV storage assembles the hashref
from C<LAST_INSERT_ID()> on the pinned connection. C<< select_async >>
resolves with the raw row arrayrefs (cursor C<< ->all >> shape) and
C<< select_single_async >> with a single row arrayref, matching the sync
cursor shape. Backend L<Future> C<< ->then >> callbacks auto-wrap a plain
return into a resolved Future (ADR 0031 §4), which is the native
L<Future.pm|Future> behaviour.

=head1 EVENT LOOP COMPATIBILITY

L<EV::MariaDB> uses the L<EV> event loop. This works with:

=over 4

=item * L<EV> directly

=item * L<AnyEvent> (uses EV as backend when available)

=item * L<IO::Async> via L<IO::Async::Loop::EV>

=item * L<Mojolicious> via L<Mojo::Reactor::EV>

=back

=head1 SEE ALSO

L<DBIO::MySQL::EV::Storage>, L<DBIO::MySQL::Storage>, L<DBIO::Storage::Async>.

ADRs 0030 and 0031 in the L<DBIO> distribution's C<docs/adr/>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
