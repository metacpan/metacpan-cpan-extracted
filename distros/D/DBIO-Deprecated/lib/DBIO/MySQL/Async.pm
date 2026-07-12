package DBIO::MySQL::Async;
# ABSTRACT: RENAMED -- see DBIO::MySQL::EV (dist DBIO-MySQL-EV)

use strict;
use warnings;

# Deliberately explicit $VERSION -- unlike normal DBIO sub-modules, which
# carry none (only the dist's main module does, bumped by dzil). This
# tombstone needs its own hard-coded, higher $VERSION so PAUSE indexes THIS
# module as canonical for the name: PAUSE resolves each module name to
# whichever shipped distribution carries the highest $VERSION, and the old
# DBIO-MySQL-Async dist's last CPAN release was 0.900000. Do NOT "clean this
# up" to match the no-$VERSION sub-module convention -- doing so hands the
# PAUSE index entry back to the stale, superseded distribution.
our $VERSION = '0.900001';

die __PACKAGE__ . " has been renamed to DBIO::MySQL::EV and this module is"
  . " retired. Install DBIO-MySQL-EV instead:\n"
  . "  cpanm DBIO::MySQL::EV\n"
  . "  https://metacpan.org/dist/DBIO-MySQL-EV\n";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Async - RENAMED -- see DBIO::MySQL::EV (dist DBIO-MySQL-EV)

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

This module has been renamed. C<DBIO-MySQL-Async> (namespace
C<DBIO::MySQL::Async>) was renamed in place to C<DBIO-MySQL-EV> (namespace
L<DBIO::MySQL::EV>): the driver is hard-wired to the L<EV> event loop, so the
C<::EV> name reflects that, and the C<::Async> namespace is freed for a
possible future loop-agnostic MySQL/MariaDB driver built on
L<DBIO::Async::Storage>. There is no behaviour change beyond the name.

This module is a CPAN redirect stub, part of L<DBIO::Deprecated>. It carries
no implementation and B<dies unconditionally> as soon as it is loaded
(C<use>/C<require>), naming the replacement module and distribution. It
exists only so that C<cpanm DBIO::MySQL::Async> -- or a cpanfile that still
pins the old name -- surfaces a clear, actionable redirect instead of
silently installing the stale, superseded C<DBIO-MySQL-Async> 0.900000
release that remains on CPAN.

Install and C<use> L<DBIO::MySQL::EV> instead.

=head1 NAME

DBIO::MySQL::Async - DEPRECATED, renamed to DBIO::MySQL::EV

=head1 SEE ALSO

L<DBIO::MySQL::EV>, L<DBIO::Deprecated>

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
