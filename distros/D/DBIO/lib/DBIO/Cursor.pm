package DBIO::Cursor;
# ABSTRACT: Abstract object representing a query cursor on a resultset.

use strict;
use warnings;

our $VERSION = '0.900004';

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


sub is_exhausted {
  die "Virtual method!";
}


sub position {
  die "Virtual method!";
}


sub mark_exhausted {
  die "Virtual method!";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Cursor - Abstract object representing a query cursor on a resultset.

=head1 VERSION

version 0.900004

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

Returns all rows in the L<DBIO::ResultSet>. Unlike the other methods here,
C<all> has a working default implementation built on L</reset> and L</next>;
subclasses may override it with a more efficient version.

=head2 is_exhausted

Virtual method. Returns true once the cursor has been fully consumed via
L</next> (or explicitly retired via L</mark_exhausted>) without an
intervening L</reset>; false otherwise.

=head2 position

Virtual method. Returns the number of rows handed out via L</next> since
the cursor was created or last L</reset>; C<0> if none have been fetched.

=head2 mark_exhausted

Virtual method. Flags the cursor as fully consumed I<without> resetting it,
so a subsequent L</next> yields nothing until the cursor is L</reset>. Used
by the collapse fast-path in L<DBIO::ResultSet> to retire a cursor after
draining it via a stealth L</all>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
