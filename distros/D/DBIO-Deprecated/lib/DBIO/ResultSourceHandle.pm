package DBIO::ResultSourceHandle;
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
die __PACKAGE__ . " has been removed. The handle indirection is gone:"
  . " STORABLE_freeze/STORABLE_thaw are implemented directly in"
  . " DBIO::ResultSource now, and Rows and ResultSets hold their result"
  . " source directly. There is no replacement module to install -- drop"
  . " any use of this class; \$DBIO::ResultSourceHandle::thaw_schema moved"
  . " to \$DBIO::ResultSource::thaw_schema. Note that blobs frozen by an"
  . " older DBIO will not thaw under the current one.\n";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ResultSourceHandle - REMOVED -- no replacement, see DBIO::Deprecated

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

This module has been removed from DBIO core, not renamed -- there is no
replacement module. It held serializable pointers to
L<result sources|DBIO::ResultSource>, originally so that
L<Rows|DBIO::Row> and L<ResultSets|DBIO::ResultSet> did not have to keep a
L<schema instance|DBIO::Schema> in scope. Its own POD already declared that
purpose obsolete after the C<Schema>/C<ResultSource> mutual-assured-destruction
contract was introduced; all it still did was carry L<Storable> freeze/thaw.
DBIO core removed the indirection outright.

The behaviour did not move to another module, it was inlined:
C<DBIO::ResultSource::STORABLE_freeze> now serializes the minimal identity
itself and C<STORABLE_thaw> resolves it -- via
C<$DBIO::ResultSource::thaw_schema> (the schema-instance channel, relocated
there from this namespace), else the class C<result_source_instance>, else a
detached source. The C<-source_handle> constructor argument and the
C<handle()> accessor are gone with it. There is nothing to C<use> instead:
serialize L<DBIO::ResultSource>, L<DBIO::Row>, L<DBIO::ResultSet> and
L<DBIO::Schema> objects directly, as before.

B<The freeze format changed.> Blobs frozen by a DBIO release that still
shipped this class -- they contain a frozen C<DBIO::ResultSourceHandle> --
will B<not> thaw under current DBIO. This was a deliberate decision, not an
oversight: DBIO is pre-stable and frozen handles were never a documented
interchange format. Re-generate any persisted frozen structures.

This module is a CPAN redirect stub, part of L<DBIO::Deprecated>. It carries
no implementation and B<dies unconditionally> as soon as it is loaded.
Unlike most tombstones in this distribution, it does not point at a
replacement module -- there is none. It exists only so that
C<cpanm DBIO::ResultSourceHandle> -- or a cpanfile / code that still
references the old name -- surfaces a clear explanation instead of silently
installing the stale, superseded C<DBIO> 0.900002 release that still carries
this name.

=head1 NAME

DBIO::ResultSourceHandle - REMOVED, no replacement

=head1 SEE ALSO

L<DBIO::ResultSource>, L<DBIO>, L<DBIO::Deprecated>

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
