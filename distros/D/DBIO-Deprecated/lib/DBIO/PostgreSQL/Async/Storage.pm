package DBIO::PostgreSQL::Async::Storage;
# ABSTRACT: RENAMED -- see DBIO::PostgreSQL::EV::Storage (dist DBIO-PostgreSQL-EV)

use strict;
use warnings;

# Last release that shipped this name: DBIO-PostgreSQL-Async 0.900000.
# The PAUSE takeover is decided by THIS dist's release version -- the build
# stamps that into every module and into META "provides" -- not by the
# literal below, which RewriteVersion::Transitional rewrites (and inserts,
# if missing) at build time. See DBIO::Deprecated, "HOW THE TAKEOVER WORKS".
our $VERSION = '0.900004';

die __PACKAGE__ . " has been renamed to DBIO::PostgreSQL::EV::Storage and this module is"
  . " retired. Install DBIO-PostgreSQL-EV instead:\n"
  . "  cpanm DBIO::PostgreSQL::EV::Storage\n"
  . "  https://metacpan.org/dist/DBIO-PostgreSQL-EV\n";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Async::Storage - RENAMED -- see DBIO::PostgreSQL::EV::Storage (dist DBIO-PostgreSQL-EV)

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

This module has been renamed as part of the C<DBIO-PostgreSQL-Async> ->
C<DBIO-PostgreSQL-EV> distribution rename (see L<DBIO::PostgreSQL::Async> for the full story). It is
a CPAN redirect stub, part of L<DBIO::Deprecated>, and B<dies
unconditionally> on load naming its replacement.

Install and C<use> L<DBIO::PostgreSQL::EV::Storage> instead.

=head1 NAME

DBIO::PostgreSQL::Async::Storage - DEPRECATED, renamed to DBIO::PostgreSQL::EV::Storage

=head1 SEE ALSO

L<DBIO::PostgreSQL::EV::Storage>, L<DBIO::PostgreSQL::Async>, L<DBIO::Deprecated>

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
