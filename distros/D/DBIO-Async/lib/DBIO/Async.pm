package DBIO::Async;
our $VERSION = '0.900004';
# ABSTRACT: Shared, loop-agnostic async layer for DBIO drivers

use strict;
use warnings;

# Why DBIO::Base (karr k13): it is core's meta-infrastructure base for internal
# DBIO classes -- c3 mro, DBIO::Componentised, Class::Accessor::Grouped,
# component_base_class 'DBIO' -- and the base every dist entry point in the
# family carries: DBIO::Forked (the sibling async-mode dist, likewise with no
# load_components of its own), DBIO::PostgreSQL, DBIO::MySQL,
# DBIO::PostgreSQL::EV, ::Age and ::PostGIS. It is NOT here for a
# load_components('Async'): this module has no behaviour to load and no such
# component is documented. It is here because it is the NEUTRAL base -- it
# inherits no driver component's connection() hook, so loading this dist
# decides no storage_type (the property ADR 0032 §7 exists to protect). @ISA is
# a composition seam: changing this needs its own ticket and an ADR, not a
# cleanup. t/00-load.t pins it.
use base 'DBIO::Base';

# ADR 0030 refinement (core k65): future_io does NOT register a generic backend
# on the core base. The core resolver discovers the per-driver transport adapter
# by CONVENTION -- ref($storage) . '::Async' (e.g. DBIO::PostgreSQL::Storage ->
# DBIO::PostgreSQL::Storage::Async) -- so merely loading this module no longer
# globally claims future_io for every driver. This module just carries the
# shared abstract Future::IO backend (DBIO::Async::Storage) that each driver's
# ::Storage::Async adapter subclasses and completes.


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Async - Shared, loop-agnostic async layer for DBIO drivers

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

See L<DBIO::Async::Storage> for the subclass contract and the seam hooks a
DB-specific driver supplies.

=head1 DESCRIPTION

Shared, loop-agnostic async layer for L<DBIO> drivers. This distribution
carries the Future / L<Future::IO> requirements and the generic async plumbing
that every DB-specific async driver needs, so a sync-only driver pulls no
async dependencies.

The C<future_io> async I<mode> (ADR 0030) resolves its transport adapter B<by
convention>: a schema connected with C<< { async => 'future_io' } >> uses the
per-driver adapter class C<< ref($storage) . '::Async' >> for its C<< *_async >>
methods -- e.g. a PostgreSQL storage C<DBIO::PostgreSQL::Storage> resolves
C<DBIO::PostgreSQL::Storage::Async>. Loading this module does B<not> globally
register future_io for every driver; it provides the shared abstract backend
those per-driver adapters subclass. A driver with no such adapter croaks early
and clearly. There is no auto-fallback and no
C<async_backend>/C<async_fallback> -- the mode is explicit or the connection
stays synchronous.

  use DBIO::Async;   # provides the shared future_io backend base

  my $schema = MyApp::Schema->connect(
      $dsn, $user, $pass, { async => 'future_io' },
  );

  $schema->resultset('Artist')->all_async->then(sub { ... });

The async work lives in L<DBIO::Async::Storage>, a concrete, DB-agnostic
skeleton subclassing core L<DBIO::Storage::Async>. The generic CRUD runner,
transaction pinning, pipeline bracketing and the sync C<< ->get >> fallbacks
are inherited from that core class (core ADR 0030, section 4);
L<DBIO::Async::Storage> adds the L<Future::IO> transport -- query execution
over the watcher seam, the listen watch loop -- the connection pool
(L<DBIO::Async::Pool>) and the AccessBroker connect-info wiring. A DB-specific
driver subclasses it as C<< DBIO::X::Storage::Async >> and supplies only the
DB-specific seam hooks (how to submit an async query, collect the ready result,
the socket fd to watch, SQL transform, connect-info shape).

=head1 EVENT LOOP COMPATIBILITY

The watcher seam is loop-agnostic: L<Future::IO> runs on its built-in
implementation -- a plain C<select> loop of its own, no event loop -- until an
implementation is B<loaded>: C<use Future::IO::Impl::IOAsync;> in the program
(likewise for L<AnyEvent>, L<Mojolicious>, L<UV> or L<Glib>), or
C<< Future::IO->load_best_impl >> called once by the main program. Installing a
C<Future::IO::Impl::*> module alone changes nothing, and this distribution
loads none. The user picks the loop; no event loop is a hard requirement (core
ADR 0014). What the implementations do differently with this transport's
polls is listed in L<DBIO::Async::Storage/FUTURE::IO IMPLEMENTATIONS>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
