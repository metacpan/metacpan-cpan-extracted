package DBIO::Cursor;
# ABSTRACT: Abstract object representing a query cursor on a resultset.

use strict;
use warnings;

use base qw/DBIO::Base/;


sub new {
  die "Virtual method!";
}


sub next {
  die "Virtual method!";
}


sub reset {
  die "Virtual method!";
}


sub all {
  my ($self) = @_;
  $self->reset;
  my @all;
  while (my @row = $self->next) {
    push(@all, \@row);
  }
  $self->reset;
  return @all;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Cursor - Abstract object representing a query cursor on a resultset.

=head1 VERSION

version 0.900002

=head1 SYNOPSIS

  my $cursor = $schema->resultset('CD')->cursor();

  # raw values off the database handle in resultset columns/select order
  my @next_cd_column_values = $cursor->next;

  # list of all raw values as arrayrefs
  my @all_cds_column_values = $cursor->all;

See F<t/cursor.t> for a runnable example of this raw-value C<< ->next >>/
C<< ->all >> API (shared with L<DBIO::Storage::DBI::Cursor>).

=head1 DESCRIPTION

A Cursor represents a query cursor on a L<DBIO::ResultSet> object. It
allows for traversing the result set with L</next>, retrieving all results with
L</all> and resetting the cursor with L</reset>.

Usually, you would use the cursor methods built into L<DBIO::ResultSet>
to traverse it. See L<DBIO::ResultSet/next>,
L<DBIO::ResultSet/reset> and L<DBIO::ResultSet/all> for more
information.

=head1 METHODS

=head2 new

Virtual method. Returns a new L<DBIO::Cursor> object.

=head2 next

Virtual method. Advances the cursor to the next row. Returns an array of
column values (the result of L<DBI/fetchrow_array> method).

=head2 reset

Virtual method. Resets the cursor to the beginning.

=head2 all

Virtual method. Returns all rows in the L<DBIO::ResultSet>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
