package DBIO::PostgreSQL::PostGIS::Introspect;
# ABSTRACT: PostgreSQL introspector augmented with PostGIS geometry_columns

use strict;
use warnings;

use base 'DBIO::PostgreSQL::Introspect';


sub _build_model {
  my ($self) = @_;
  my $model = $self->SUPER::_build_model();
  _augment_geometry_columns($model->{columns});
  return $model;
}


sub _augment_geometry_columns {
  my ($columns_by_table) = @_;
  for my $table_key (keys %{ $columns_by_table // {} }) {
    for my $col (@{ $columns_by_table->{$table_key} // [] }) {
      my $dt = lc($col->{data_type} // '');
      if ($dt =~ /\A(geometry|geography)(?:\((\w+)(?:,(\d+))?\))?\z/) {
        $col->{base_type}     = $1;
        $col->{geometry_type} = $2 if $2;
        $col->{srid}          = $3 + 0 if defined $3;
      }
    }
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::Introspect - PostgreSQL introspector augmented with PostGIS geometry_columns

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Extends L<DBIO::PostgreSQL::Introspect> for PostGIS-enabled databases.
After the standard introspection, augments geometry and geography column
metadata by parsing the C<data_type> string (e.g. C<geometry(Point,4326)>)
into discrete C<geometry_type> and C<srid> fields.

This is used automatically when L<DBIO::PostgreSQL::PostGIS::Storage> is
active — the Deploy class uses this introspector via
L<DBIO::PostgreSQL::PostGIS::Deploy/_new_introspect>.

=head1 METHODS

=head2 _build_model

Calls the parent C<_build_model> then augments geometry and geography
columns with C<geometry_type> and C<srid> parsed from the data_type string.

=head2 _augment_geometry_columns

Private helper. Iterates the columns-by-table hashref and parses PostGIS
C<data_type> strings such as C<geometry(Point,4326)> into discrete
C<base_type> (C<geometry> or C<geography>), C<geometry_type> (e.g.
C<Point>), and numeric C<srid> fields on each column hashref in place.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
