package DBIO::Sybase::Storage::ASE::IdentityRetrieval;
# ABSTRACT: Identity retrieval for Sybase ASE

use strict;
use warnings;
use namespace::clean;

# No requires - these methods expect the consuming class to have:
# _identity, _perform_autoinc_retrieval, sql_maker, next::method

sub _fetch_identity_sql {
  my ($self, $source, $col) = @_;

  return sprintf ("SELECT MAX(%s) FROM %s",
    map { $self->sql_maker->_quote ($_) } ($col, $source->from)
  );
}

# Called during execute to retrieve identity after insert
sub _execute {
  my $self = shift;
  my ($rv, $sth, @bind) = $self->next::method(@_);

  $self->_identity( ($sth->fetchall_arrayref)->[0][0] )
    if $self->_perform_autoinc_retrieval;

  return wantarray ? ($rv, $sth, @bind) : $rv;
}

sub last_insert_id { shift->_identity }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Storage::ASE::IdentityRetrieval - Identity retrieval for Sybase ASE

=head1 VERSION

version 0.900000

=head1 METHODS

=head2 last_insert_id

Returns the last autoincrement identity value, retrieved via
C<SELECT MAX(col)> from the most recently inserted row.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
