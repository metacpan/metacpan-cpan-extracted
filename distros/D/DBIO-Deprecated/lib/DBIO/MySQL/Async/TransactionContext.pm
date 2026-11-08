package DBIO::MySQL::Async::TransactionContext;
# ABSTRACT: RENAMED -- see DBIO::MySQL::EV::TransactionContext (dist DBIO-MySQL-EV)

use strict;
use warnings;

# Last release that shipped this name: DBIO-MySQL-Async 0.900000.
# The PAUSE takeover is decided by THIS dist's release version -- the build
# stamps that into every module and into META "provides" -- not by the
# literal below, which RewriteVersion::Transitional rewrites (and inserts,
# if missing) at build time. See DBIO::Deprecated, "HOW THE TAKEOVER WORKS".
our $VERSION = '0.900004';

die __PACKAGE__ . " has been renamed to DBIO::MySQL::EV::TransactionContext and this module is"
  . " retired. Install DBIO-MySQL-EV instead:\n"
  . "  cpanm DBIO::MySQL::EV::TransactionContext\n"
  . "  https://metacpan.org/dist/DBIO-MySQL-EV\n";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Async::TransactionContext - RENAMED -- see DBIO::MySQL::EV::TransactionContext (dist DBIO-MySQL-EV)

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

This module has been renamed as part of the C<DBIO-MySQL-Async> ->
C<DBIO-MySQL-EV> distribution rename (see L<DBIO::MySQL::Async> for the full story). It is
a CPAN redirect stub, part of L<DBIO::Deprecated>, and B<dies
unconditionally> on load naming its replacement.

Install and C<use> L<DBIO::MySQL::EV::TransactionContext> instead.

=head1 NAME

DBIO::MySQL::Async::TransactionContext - DEPRECATED, renamed to DBIO::MySQL::EV::TransactionContext

=head1 SEE ALSO

L<DBIO::MySQL::EV::TransactionContext>, L<DBIO::MySQL::Async>, L<DBIO::Deprecated>

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
