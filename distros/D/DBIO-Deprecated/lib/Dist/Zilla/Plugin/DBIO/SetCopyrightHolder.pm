package Dist::Zilla::Plugin::DBIO::SetCopyrightHolder;
# ABSTRACT: RENAMED -- see Dist::Zilla::Plugin::DBIO::SetMeta (dist Dist-Zilla-PluginBundle-DBIO)

use strict;
use warnings;

# Deliberately explicit $VERSION -- unlike normal DBIO sub-modules, which
# carry none (only the dist's main module does, bumped by dzil). This
# tombstone needs its own hard-coded, higher $VERSION so PAUSE indexes THIS
# module as canonical for the name: PAUSE resolves each module name to
# whichever shipped distribution carries the highest $VERSION, and the
# Dist-Zilla-PluginBundle-DBIO release that last shipped this package
# (v0.900001, whose containing file declared $VERSION = '0.900001') no
# longer ships it as of the SAME distribution's later releases -- this is a
# same-distribution rename, not a cross-distribution one, but PAUSE indexes
# per MODULE NAME, so it orphans just the same. 0.900002 clears that release
# generously (the inner package itself carried no $VERSION of its own in
# that release, so 0.900001 would already be enough, but the file it lived
# in did -- go one better to be unambiguous). Do NOT "clean this up" to
# match the no-$VERSION sub-module convention -- doing so hands the PAUSE
# index entry back to the stale, superseded release.
our $VERSION = '0.900002';

die __PACKAGE__ . " has been renamed to Dist::Zilla::Plugin::DBIO::SetMeta"
  . " and this module is retired. Upgrade Dist-Zilla-PluginBundle-DBIO"
  . " instead:\n"
  . "  cpanm Dist::Zilla::PluginBundle::DBIO\n"
  . "  https://metacpan.org/dist/Dist-Zilla-PluginBundle-DBIO\n";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DBIO::SetCopyrightHolder - RENAMED -- see Dist::Zilla::Plugin::DBIO::SetMeta (dist Dist-Zilla-PluginBundle-DBIO)

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

This module has been renamed I<within its own distribution>: unlike the
other tombstones in L<DBIO::Deprecated>, this is not a cross-distribution
move. C<Dist-Zilla-PluginBundle-DBIO> renamed its inner C<BeforeBuild>
plugin from C<Dist::Zilla::Plugin::DBIO::SetCopyrightHolder> to
L<Dist::Zilla::Plugin::DBIO::SetMeta> when it was extended to also set
C<authors> and C<_license_class>, not just C<_copyright_holder> -- a
superset of the old behaviour under a name that reflects it. Because PAUSE
indexes per B<module name>, not per distribution, a same-distribution rename
across releases orphans the old name exactly like a cross-distribution one
does: newer releases of C<Dist-Zilla-PluginBundle-DBIO> no longer ship
C<Dist::Zilla::Plugin::DBIO::SetCopyrightHolder> at all, so without this
tombstone PAUSE would keep resolving that name to the last release that did.

This module is a CPAN redirect stub, part of L<DBIO::Deprecated>. It carries
no implementation and B<dies unconditionally> as soon as it is loaded,
naming the replacement. Note the replacement lives in the I<same>
distribution you already depend on (C<Dist-Zilla-PluginBundle-DBIO>) -- just
upgrade it, no new dependency to add.

=head1 NAME

Dist::Zilla::Plugin::DBIO::SetCopyrightHolder - DEPRECATED, renamed to Dist::Zilla::Plugin::DBIO::SetMeta

=head1 SEE ALSO

L<Dist::Zilla::Plugin::DBIO::SetMeta>, L<Dist::Zilla::PluginBundle::DBIO>,
L<DBIO::Deprecated>

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
