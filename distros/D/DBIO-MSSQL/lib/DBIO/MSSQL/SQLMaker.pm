package DBIO::MSSQL::SQLMaker;
# ABSTRACT: MSSQL-specific SQL generation for DBIO

use warnings;
use strict;

use base qw( DBIO::SQLMaker );



sub apply_limit {
  my ($self, $sql, $rs_attrs, $rows, $offset) = @_;
  return $self->_RowNumberOver($sql, $rs_attrs, $rows, $offset);
}

#
# MSSQL does not support ... OVER() ... RNO limits
#
sub _rno_default_order {
  return \ '(SELECT(1))';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::SQLMaker - MSSQL-specific SQL generation for DBIO

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

L<DBIO::SQLMaker> subclass for Microsoft SQL Server. Implements LIMIT/OFFSET
via C<ROW_NUMBER() OVER()> (the dialect SQL Server 2005+ supports) and
overrides the default C<OVER()> order expression to use C<(SELECT(1))>
because MSSQL does not support an empty C<OVER()> clause.

Used automatically by L<DBIO::MSSQL::Storage>.

=head1 METHODS

=head2 apply_limit

    my $sql = $sqlmaker->apply_limit($sql, $rs_attrs, $rows, $offset);

MSSQL has no C<LIMIT>/C<OFFSET> keyword (before 2012's C<OFFSET ... FETCH>).
DBIO targets the broadly compatible C<ROW_NUMBER() OVER()> windowing
dialect: the query is wrapped in a derived table that numbers rows, then
sliced by C<WHERE rno BETWEEN offset+1 AND offset+rows>. Replaces the
DBIx::Class C<sql_limit_dialect> string dispatch.

=head1 SEE ALSO

=over

=item * L<DBIO::MSSQL::Storage> - MSSQL storage (uses this SQL maker)

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
