package DBIO::Test::Future;
# ABSTRACT: RENAMED -- see DBIO::Future::Immediate (dist DBIO)

use strict;
use warnings;

# Deliberately explicit $VERSION -- unlike normal DBIO sub-modules, which
# carry none (only the dist's main module does, bumped by dzil). This
# tombstone needs its own hard-coded, higher $VERSION so PAUSE indexes THIS
# module as canonical for the name: PAUSE resolves each module name to
# whichever shipped distribution carries the highest $VERSION, and DBIO
# core's last CPAN release to ship this module was 0.900000. Do NOT "clean
# this up" to match the no-$VERSION sub-module convention -- doing so hands
# the PAUSE index entry back to the stale, superseded release.
our $VERSION = '0.900001';

die __PACKAGE__ . " has been renamed to DBIO::Future::Immediate and this"
  . " module is retired. Upgrade DBIO instead:\n"
  . "  cpanm DBIO\n"
  . "  https://metacpan.org/dist/DBIO\n";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Future - RENAMED -- see DBIO::Future::Immediate (dist DBIO)

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

This module has been renamed within DBIO core: C<DBIO::Test::Future> was
renamed to L<DBIO::Future::Immediate>, dropping the misleading C<Test::>
prefix on what is actually the production default Future implementation for
the C<immediate> async mode (ADR 0014). No behaviour change beyond the name;
DBIO core's ADR 0014 keeps the old name as historical record.

This module is a CPAN redirect stub, part of L<DBIO::Deprecated>. It carries
no implementation and B<dies unconditionally> as soon as it is loaded,
naming the replacement module. It exists only so that
C<cpanm DBIO::Test::Future> -- or a cpanfile that still pins the old name --
surfaces a clear, actionable redirect instead of silently installing the
stale, superseded C<DBIO> 0.900000 release that still carries this name.

Install and C<use> L<DBIO::Future::Immediate> instead -- it ships as part of
the regular L<DBIO> distribution, not a separate one; upgrading C<DBIO> is
enough.

=head1 NAME

DBIO::Test::Future - DEPRECATED, renamed to DBIO::Future::Immediate

=head1 SEE ALSO

L<DBIO::Future::Immediate>, L<DBIO>, L<DBIO::Deprecated>

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
