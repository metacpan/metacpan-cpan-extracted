package DBIO::DB2::SQLMaker;
# ABSTRACT: SQL dialect for IBM DB2

use strict;
use warnings;

use base 'DBIO::SQLMaker';


sub apply_limit {
  my ($self, $sql, $rs_attrs, $rows, $offset) = @_;

  # DB2 5.4+ uses ROW_NUMBER() OVER() for offset support
  # Older DB2 uses FETCH FIRST n ROWS ONLY (no offset support, requires subquery)
  if ($offset) {
    return $self->_RowNumberOver($sql, $rs_attrs, $rows, $offset);
  }
  return $self->_FetchFirst($sql, $rs_attrs, $rows, $offset);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::SQLMaker - SQL dialect for IBM DB2

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

DB2-specific SQL dialect. Its C<apply_limit> branches on whether the query has
an offset: C<ROW_NUMBER() OVER()> when an offset is present (the only DB2 form
that can skip a prefix), C<FETCH FIRST n ROWS ONLY> otherwise. This is an
offset-based branch, not server-version detection. See ADR 0003.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
