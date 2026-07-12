package DBIO::MySQL::Async::QueryExecutor;
# ABSTRACT: RENAMED -- see DBIO::MySQL::EV::QueryExecutor (dist DBIO-MySQL-EV)

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

die __PACKAGE__ . " has been renamed to DBIO::MySQL::EV::QueryExecutor and this module is"
  . " retired. Install DBIO-MySQL-EV instead:\n"
  . "  cpanm DBIO::MySQL::EV::QueryExecutor\n"
  . "  https://metacpan.org/dist/DBIO-MySQL-EV\n";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Async::QueryExecutor - RENAMED -- see DBIO::MySQL::EV::QueryExecutor (dist DBIO-MySQL-EV)

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

This module has been renamed as part of the C<DBIO-MySQL-Async> ->
C<DBIO-MySQL-EV> distribution rename (see L<DBIO::MySQL::Async> for the full story). It is
a CPAN redirect stub, part of L<DBIO::Deprecated>, and B<dies
unconditionally> on load naming its replacement.

Install and C<use> L<DBIO::MySQL::EV::QueryExecutor> instead.

=head1 NAME

DBIO::MySQL::Async::QueryExecutor - DEPRECATED, renamed to DBIO::MySQL::EV::QueryExecutor

=head1 SEE ALSO

L<DBIO::MySQL::EV::QueryExecutor>, L<DBIO::MySQL::Async>, L<DBIO::Deprecated>

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
