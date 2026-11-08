package DBIO::Schema::Versioned;
# ABSTRACT: REMOVED -- no replacement, see DBIO::Deprecated

use strict;
use warnings;

# Last release that shipped this name: DBIO (core) 0.900000.
# The PAUSE takeover is decided by THIS dist's release version -- the build
# stamps that into every module and into META "provides" -- not by the
# literal below, which RewriteVersion::Transitional rewrites (and inserts,
# if missing) at build time. See DBIO::Deprecated, "HOW THE TAKEOVER WORKS".
our $VERSION = '0.900004';

# "Removed, no successor" tombstone: unlike a rename, there is nothing to
# redirect to -- say so plainly instead of pointing at a replacement module.
die __PACKAGE__ . " has been removed. Its file-diff upgrade path depended"
  . " on the hard-deprecated create_ddl_dir() DDL-file generator and was"
  . " internally broken. There is no replacement module to install in its"
  . " place -- use the native deploy/upgrade path instead:"
  . " DBIO::DeploymentHandler together with your driver's"
  . " DBIO::<Driver>::Deploy class, which reconcile the live database"
  . " against the current schema in one shot with no SQL diff files.\n";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Schema::Versioned - REMOVED -- no replacement, see DBIO::Deprecated

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

This module has been removed from DBIO core, not renamed -- there is no
replacement module, and no deprecated stub or backward-compatibility shim was
kept. It was the schema component for versioned databases whose upgrade path
was driven by SQL diff files. That path depended on the hard-deprecated
C<create_ddl_dir()> DDL-file generator and was internally broken, so DBIO core
dropped it outright in 0.900001.

Use the native deploy/upgrade path instead: L<DBIO::DeploymentHandler>
together with your driver's C<DBIO::E<lt>DriverE<gt>::Deploy> class (for
example the C<Deploy> class of L<DBIO::PostgreSQL> or L<DBIO::SQLite>). They
reconcile the live database against the current schema in one shot, with no
SQL diff files.

This module is a CPAN redirect stub, part of L<DBIO::Deprecated>. It carries
no implementation and B<dies unconditionally> as soon as it is loaded.
Unlike most tombstones in this distribution, it does not point at a
replacement module -- there is none. It exists only so that
C<cpanm DBIO::Schema::Versioned> -- or a cpanfile / code that still
references the old name -- surfaces a clear explanation instead of silently
installing the stale, superseded C<DBIO> 0.900000 release that still carries
this name.

=head1 NAME

DBIO::Schema::Versioned - REMOVED, no replacement

=head1 SEE ALSO

L<DBIO::DeploymentHandler>, L<DBIO>, L<DBIO::Deprecated>

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
