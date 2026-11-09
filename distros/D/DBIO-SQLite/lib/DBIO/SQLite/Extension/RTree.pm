package DBIO::SQLite::Extension::RTree;
# ABSTRACT: The extension class of SQLite's R*Tree module

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::SQLite::Extension::VirtualTable';


sub module          { 'rtree' }
sub shadow_suffixes { qw( _node _parent _rowid ) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Extension::RTree - The extension class of SQLite's R*Tree module

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  __PACKAGE__->sqlite_extensions('rtree');

=head1 DESCRIPTION

An R*Tree index C<geo> keeps itself in the shadow tables C<geo_node>,
C<geo_parent> and C<geo_rowid>. They are the module's and not the
application's: this class claims them
(L<DBIO::SQLite::Extension::VirtualTable/claims>), found by the probe of
L<DBIO::SQLite::Extension::VirtualTable/inspect>. Only C<USING rtree> is
probed; C<rtree_i32> and C<geopoly> are other modules and are other
declarations.

=head1 METHODS

=head2 module

C<rtree>.

=head2 shadow_suffixes

C<_node>, C<_parent>, C<_rowid>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
