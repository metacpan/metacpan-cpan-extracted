package Dist::Zilla::Plugin::DBIO::SetCopyrightHolder;
# ABSTRACT: RENAMED -- see Dist::Zilla::Plugin::DBIO::SetMeta (dist Dist-Zilla-PluginBundle-DBIO)

use strict;
use warnings;

# Last release that shipped this name: Dist-Zilla-PluginBundle-DBIO 0.900001.
# The PAUSE takeover is decided by THIS dist's release version -- the build
# stamps that into every module and into META "provides" -- not by the
# literal below, which RewriteVersion::Transitional rewrites (and inserts,
# if missing) at build time. See DBIO::Deprecated, "HOW THE TAKEOVER WORKS".
our $VERSION = '0.900004';

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

version 0.900004

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
