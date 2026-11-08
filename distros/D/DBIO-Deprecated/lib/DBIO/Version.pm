package DBIO::Version;
# ABSTRACT: REMOVED -- no replacement, see DBIO::Deprecated

use strict;
use warnings;

# Last release that shipped this name: DBIO (core) 0.900002.
# The PAUSE takeover is decided by THIS dist's release version -- the build
# stamps that into every module and into META "provides" -- not by the
# literal below, which RewriteVersion::Transitional rewrites (and inserts,
# if missing) at build time. See DBIO::Deprecated, "HOW THE TAKEOVER WORKS".
our $VERSION = '0.900004';

# "Removed, no successor" tombstone: unlike a rename, there is nothing to
# redirect to -- say so plainly instead of pointing at a replacement module.
die __PACKAGE__ . " has been removed. It was the old"
  . " DBIx::Class::Schema::Versioned-style standalone versioning schema"
  . " (the 'dbio_schema_versions' table), superseded by DBIO's live"
  . " deployment machinery, and was dead code by the time it was dropped."
  . " There is no replacement module to install in its place -- if you need"
  . " versioned deployments, use DBIO::DeploymentHandler.\n";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Version - REMOVED -- no replacement, see DBIO::Deprecated

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

This module has been removed from DBIO core, not renamed -- there is no
replacement module. It was the schema class of the old
L<DBIx::Class::Schema::Versioned>-style standalone versioning support: a
minimal C<DBIO::Schema> subclass registering a single result class,
L<DBIO::Version::Table>, for the C<dbio_schema_versions> table. That
mechanism was superseded by
L<DBIO::DeploymentHandler::VersionStorage::Standard>, which is what actually
tracks deployed schema versions in DBIO; C<DBIO::Version> was left behind
unreferenced by anything in C<lib>, C<t>, C<examples> or C<bin>, and DBIO
core dropped it outright.

There is no drop-in successor to C<use> instead: the two are not the same
shape, and the version-storage classes are internals of
L<DBIO::DeploymentHandler>, not a standalone schema you point at yourself.
If you were using C<DBIO::Version> for versioned deployments, migrate to
L<DBIO::DeploymentHandler>. Note that the storage table is not the same one
either -- there is no C<dbio_schema_versions> table any more.

This module is a CPAN redirect stub, part of L<DBIO::Deprecated>. It carries
no implementation and B<dies unconditionally> as soon as it is loaded.
Unlike most tombstones in this distribution, it does not point at a
replacement module -- there is none. It exists only so that
C<cpanm DBIO::Version> -- or a cpanfile / code that still references the old
name -- surfaces a clear explanation instead of silently installing the
stale, superseded C<DBIO> 0.900002 release that still carries this name.

=head1 NAME

DBIO::Version - REMOVED, no replacement

=head1 SEE ALSO

L<DBIO::DeploymentHandler>, L<DBIO>, L<DBIO::Deprecated>

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
