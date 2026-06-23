package DBIO::PostgreSQL::PostGIS;
# ABSTRACT: PostGIS spatial extension support for DBIO::PostgreSQL
our $VERSION = '0.900000';

use strict;
use warnings;

use base 'DBIO::Base';
use DBIO::PostgreSQL::PostGIS::Geometry ();
use DBIO::PostgreSQL::PostGIS::ResultSet ();

__PACKAGE__->load_components(qw( InflateColumn ));

sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::PostgreSQL::PostGIS::Storage');
  return $self->next::method(@info);
}


sub register_column {
  my ($self, $column, $info, @rest) = @_;
  $self->next::method($column, $info, @rest);

  my $data_type = lc($info->{data_type} // '');
  my $is_spatial =
    exists $info->{inflate_geometry}
      ? $info->{inflate_geometry}
      : ($data_type eq 'geometry' || $data_type eq 'geography');
  return unless $is_spatial;

  # Promote the resultset class once, leaving custom user subclasses alone.
  my $rs_class = $self->resultset_class;
  if ($rs_class && !$rs_class->isa('DBIO::PostgreSQL::PostGIS::ResultSet')) {
    $self->resultset_class('DBIO::PostgreSQL::PostGIS::ResultSet');
  }

  my $default_srid = $info->{srid};

  $self->inflate_column(
    $column => {
      inflate => sub {
        my ($value, $obj) = @_;
        return undef unless defined $value;
        return $value if ref($value) && $value->isa('DBIO::PostgreSQL::PostGIS::Geometry');
        # PostGIS hands EWKB-hex back by default, EWKT when ST_AsEWKT is used.
        if ($value =~ /\A[0-9A-Fa-f]+\z/) {
          return DBIO::PostgreSQL::PostGIS::Geometry->from_ewkb_hex($value);
        }
        if ($value =~ /\ASRID=\d+;/) {
          return DBIO::PostgreSQL::PostGIS::Geometry->from_ewkt($value);
        }
        return DBIO::PostgreSQL::PostGIS::Geometry->from_wkt(
          $value, srid => $default_srid,
        );
      },
      deflate => sub {
        my ($value, $obj) = @_;
        return undef unless defined $value;
        if (ref($value) && $value->isa('DBIO::PostgreSQL::PostGIS::Geometry')) {
          return $value->ewkt // $value->wkt // $value->ewkb_hex;
        }
        # Already an EWKT/WKT/EWKB-hex string — pass through.
        return $value;
      },
    },
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS - PostGIS spatial extension support for DBIO::PostgreSQL

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  package MyApp::Schema::Result::Place;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::PostGIS');
  __PACKAGE__->table('place');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
    geom => {
      data_type     => 'geometry',
      geometry_type => 'POINT',
      srid          => 4326,
    },
  );

  # Inflated reads
  my $place = $schema->resultset('Place')->find(1);
  $place->geom->isa('DBIO::PostgreSQL::PostGIS::Geometry');
  $place->geom->x;        # longitude
  $place->geom->y;        # latitude

  # Deflated writes — pass a Geometry object, the helper builds EWKT
  $place->geom(
    DBIO::PostgreSQL::PostGIS::Geometry->point(13.4, 52.5, srid => 4326),
  );
  $place->update;

  # Spatial query — raw SQL via -bool literal
  my $rs = $schema->resultset('Place')->search({
    -bool => \['ST_DWithin(geom, ST_MakePoint(?, ?)::geography, ?)',
               $lon, $lat, $meters],
  });

=head1 DESCRIPTION

L<DBIO::PostgreSQL::PostGIS> is a result-class component that adds
PostGIS spatial type handling to L<DBIO> result classes:

=over 4

=item *

Columns with C<< data_type => 'geometry' >> or C<< 'geography' >> are
automatically inflated to L<DBIO::PostgreSQL::PostGIS::Geometry>
objects on read and deflated back to EWKT on write.

=item *

Spatial-query helpers are mixed into the resultset class via
L<DBIO::PostgreSQL::PostGIS::ResultSet>.

=back

For the schema-level storage extensions (C<ensure_postgis>,
C<postgis_version>), set C<storage_type> on the schema:

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::PostgreSQL::PostGIS::Storage');

=head1 METHODS

=head2 register_column

Hooks into the column registration chain. When a column declares
C<< data_type => 'geometry' >> or C<< 'geography' >>, registers
inflate/deflate handlers that round-trip
L<DBIO::PostgreSQL::PostGIS::Geometry> objects through EWKT.

Override the auto-detection by setting C<< inflate_geometry => 0 >>
explicitly on the column.

Also promotes the result source's C<resultset_class> to
L<DBIO::PostgreSQL::PostGIS::ResultSet> the first time a spatial column is
registered, giving the resultset spatial-query helpers (C<within_distance>,
C<nearest_to>, etc.). If you need custom resultset methods alongside the
PostGIS helpers, subclass L<DBIO::PostgreSQL::PostGIS::ResultSet> and set
C<resultset_class> to your subclass — the promotion guard skips any class
that already inherits from C<DBIO::PostgreSQL::PostGIS::ResultSet>.

=seealso

=over 4

=item * L<DBIO::PostgreSQL> - Base PostgreSQL driver component

=item * L<DBIO::PostgreSQL::PostGIS::Geometry> - Lightweight geometry value object

=item * L<DBIO::PostgreSQL::PostGIS::Storage> - Storage class with spatial methods

=item * L<DBIO::PostgreSQL::PostGIS::ResultSet> - Spatial query helpers

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
