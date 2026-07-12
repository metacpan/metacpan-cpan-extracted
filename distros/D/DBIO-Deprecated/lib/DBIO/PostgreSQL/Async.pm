package DBIO::PostgreSQL::Async;
# ABSTRACT: RENAMED -- see DBIO::PostgreSQL::EV (dist DBIO-PostgreSQL-EV)

use strict;
use warnings;

# Deliberately explicit $VERSION -- unlike normal DBIO sub-modules, which
# carry none (only the dist's main module does, bumped by dzil). This
# tombstone needs its own hard-coded, higher $VERSION so PAUSE indexes THIS
# module as canonical for the name: PAUSE resolves each module name to
# whichever shipped distribution carries the highest $VERSION, and the old
# DBIO-PostgreSQL-Async dist's last CPAN release was 0.900000. Do NOT "clean
# this up" to match the no-$VERSION sub-module convention -- doing so hands
# the PAUSE index entry back to the stale, superseded distribution.
our $VERSION = '0.900001';

die __PACKAGE__ . " has been renamed to DBIO::PostgreSQL::EV and this module"
  . " is retired. Install DBIO-PostgreSQL-EV instead:\n"
  . "  cpanm DBIO::PostgreSQL::EV\n"
  . "  https://metacpan.org/dist/DBIO-PostgreSQL-EV\n";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Async - RENAMED -- see DBIO::PostgreSQL::EV (dist DBIO-PostgreSQL-EV)

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

This module has been renamed. C<DBIO-PostgreSQL-Async> (namespace
C<DBIO::PostgreSQL::Async::*>) was renamed in place to C<DBIO-PostgreSQL-EV>
(namespace L<DBIO::PostgreSQL::EV>): the driver is hard-wired to the L<EV>
event loop via C<EV::Pg>/libpq-async, so the C<::EV> name reflects that, and
the C<::Async> namespace is freed for a possible future loop-agnostic
PostgreSQL driver built on L<DBIO::Async::Storage>. There is no behaviour
change beyond the name.

This module is a CPAN redirect stub, part of L<DBIO::Deprecated>. It carries
no implementation and B<dies unconditionally> as soon as it is loaded
(C<use>/C<require>), naming the replacement module and distribution. It
exists only so that C<cpanm DBIO::PostgreSQL::Async> -- or a cpanfile that
still pins the old name -- surfaces a clear, actionable redirect instead of
silently installing the stale, superseded C<DBIO-PostgreSQL-Async> 0.900000
release that remains on CPAN.

Install and C<use> L<DBIO::PostgreSQL::EV> instead.

=head1 NAME

DBIO::PostgreSQL::Async - DEPRECATED, renamed to DBIO::PostgreSQL::EV

=head1 SEE ALSO

L<DBIO::PostgreSQL::EV>, L<DBIO::Deprecated>

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
