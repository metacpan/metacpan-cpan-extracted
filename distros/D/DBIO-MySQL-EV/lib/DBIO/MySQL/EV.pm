package DBIO::MySQL::EV;
our $VERSION = '0.900001';
# ABSTRACT: Async MySQL/MariaDB storage for DBIO via EV::MariaDB

use strict;
use warnings;

use base 'DBIO::Base';


# Note for cross-repo readers (karr #14 / dbio-mysql-ev):
# A previous version of this file overrode `connection()` to force
# `storage_type('+DBIO::MySQL::EV::Storage')` on every connect. That hijack
# contradicted the inert-component model (ADR 0030): a loadable component
# must not switch the schema's storage class on its own. PostgreSQL's
# equivalent `DBIO::PostgreSQL::EV` has never had such an override; the
# MySQL copy was removed for parity. The cross-repo handoff that registers
# the `ev` mode on `DBIO::MySQL::Storage` is tracked in the dbio-mysql
# board as its own karr ticket and is intentionally NOT implemented here.

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::EV - Async MySQL/MariaDB storage for DBIO via EV::MariaDB

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  # Schema setup
  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components(qw(MySQL MySQL::EV));

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

  # Automatic wire pipelining — issue several *_async calls without awaiting
  # between them; EV::MariaDB batches them in a single round-trip.
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

EV::MariaDB pipelines queries B<automatically> at the wire level (consecutive
issued queries are batched, up to 64 in flight) and uses prepared statements
for bound queries. There is no explicit pipeline-mode API to bracket, so
L<DBIO::MySQL::EV::Storage> declares no C<pipeline> transport capability;
throughput comes for free from issuing several C<*_async> calls without
awaiting between them.

This module is an B<inert marker component> for async MySQL/MariaDB. Loading
it via C<< load_components('MySQL::EV') >> does B<not> by itself switch the
storage to async: it only tags the schema so the L<DBIO::MySQL::Storage> MRO
arm can resolve the C<ev> mode. Async is an explicit, per-connection choice
(ADR 0030); you opt in at C<connect> time with C<< { async => 'ev' } >>:

  my $schema = MyApp::Schema->connect(
      $dsn, $user, $pass,
      { async => 'ev' },
  );

The C<ev> mode resolves to L<DBIO::MySQL::EV::Storage> (this distribution)
and is registered by L<DBIO::MySQL::Storage> (the sync driver); the
registration is its own karr ticket and lives in the L<DBIO::MySQL>
distribution, not here. With C<{ async => 'ev' }> on a schema that has loaded
this component, the C<*_async> methods on the resulting storage run real
non-blocking queries over L<EV::MariaDB>.

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
