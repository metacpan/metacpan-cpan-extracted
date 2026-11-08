package DBIO::Version::Table;
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
die __PACKAGE__ . " has been removed together with DBIO::Version. It was the"
  . " result class of the old DBIx::Class::Schema::Versioned-style"
  . " 'dbio_schema_versions' table, superseded by DBIO's live deployment"
  . " machinery. There is no replacement module to install in its place --"
  . " if you need versioned deployments, use DBIO::DeploymentHandler.\n";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Version::Table - REMOVED -- no replacement, see DBIO::Deprecated

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

This module has been removed from DBIO core, not renamed -- there is no
replacement module. It was the result class registered by
L<DBIO::Version>, describing the C<dbio_schema_versions> table of the old
L<DBIx::Class::Schema::Versioned>-style standalone versioning support (two
columns, C<version> and C<installed>, with C<version> as primary key). Both
classes were removed in the same change: the mechanism had been superseded
by L<DBIO::DeploymentHandler::VersionStorage::Standard> and nothing in DBIO
referenced them any more.

There is no drop-in successor to C<use> instead. Version storage is an
internal of L<DBIO::DeploymentHandler> now, with its own result class and its
own table -- there is no C<dbio_schema_versions> table in DBIO any more. If
you were relying on this class, migrate to L<DBIO::DeploymentHandler>.

This module is a CPAN redirect stub, part of L<DBIO::Deprecated>. It carries
no implementation and B<dies unconditionally> as soon as it is loaded.
Unlike most tombstones in this distribution, it does not point at a
replacement module -- there is none. It exists only so that
C<cpanm DBIO::Version::Table> -- or a cpanfile / code that still references
the old name -- surfaces a clear explanation instead of silently installing
the stale, superseded C<DBIO> 0.900002 release that still carries this name.

=head1 NAME

DBIO::Version::Table - REMOVED, no replacement

=head1 SEE ALSO

L<DBIO::DeploymentHandler>, L<DBIO>, L<DBIO::Deprecated>

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
