package DBIO::Sybase::SQLMaker;
# ABSTRACT: Sybase ASE-specific SQL generation for DBIO

use warnings;
use strict;

use base qw( DBIO::SQLMaker );



sub apply_limit {
  my ($self, $sql, $rs_attrs, $rows, $offset) = @_;
  return $self->_GenericSubQ($sql, $rs_attrs, $rows, $offset);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::SQLMaker - Sybase ASE-specific SQL generation for DBIO

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

L<DBIO::SQLMaker> subclass for Sybase ASE (Adaptive Server Enterprise).
ASE has no native C<LIMIT>/C<OFFSET> keyword, so this class overrides
L</apply_limit> to emit ASE-valid pagination.

Used automatically by L<DBIO::Sybase::Storage::ASE>.

=head1 METHODS

=head2 apply_limit

    my $sql = $sqlmaker->apply_limit($sql, $rs_attrs, $rows, $offset);

ASE has no C<LIMIT>/C<OFFSET> keyword. DBIO targets the database-agnostic
C<GenericSubQ> dialect: the query is sliced by a correlated
C<WHERE ( SELECT COUNT(*) ... ) BETWEEN ? AND ?> subquery against a stable,
main-table-based order. This is the same dialect DBIx::Class used for ASE,
because ASE has no single windowing/C<TOP> construct that works reliably for
all query shapes across server versions. Replaces the DBIx::Class
C<sql_limit_dialect> string dispatch.

The C<rows>-only case (no offset) never reaches this method: it is handled
earlier by L<DBIO::Sybase::Storage::ASE/_prep_for_execute> via
C<SET ROWCOUNT>, which strips the limit before this SQLMaker runs.

GenericSubQ requires a stable, main-table-based C<order_by>; a resultset with
an offset but no such order raises an exception (this is intentional, see
L<DBIO::SQLMaker::ClassicExtensions/_GenericSubQ>).

=head1 SEE ALSO

=over

=item * L<DBIO::Sybase::Storage::ASE> - Sybase ASE storage (uses this SQL maker)

=item * L<DBIO::SQLMaker> - Base SQL maker class

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
