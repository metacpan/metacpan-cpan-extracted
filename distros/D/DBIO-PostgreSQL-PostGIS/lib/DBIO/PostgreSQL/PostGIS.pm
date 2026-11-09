package DBIO::PostgreSQL::PostGIS;
# ABSTRACT: PostGIS spatial extension support for DBIO::PostgreSQL
our $VERSION = '0.900004';

use strict;
use warnings;

use base 'DBIO::Base';
use DBIO::Exception ();
use DBIO::PostgreSQL::PostGIS::Geometry ();
use DBIO::PostgreSQL::PostGIS::ResultSet ();

__PACKAGE__->load_components(qw( InflateColumn ));

sub connection {
  my ($self, @info) = @_;
  $self->register_storage_layer('DBIO::PostgreSQL::PostGIS::Storage');
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
          # A value that came from the database goes back as the EWKB hex
          # it arrived as. The EWKT of such an object is rebuilt from the
          # decoded coordinates and holds Perl's printing of each double,
          # not the double.
          my $why = $value->_unwritable_reason;
          DBIO::Exception->throw($why) if defined $why;
          my $hex = $value->ewkb_hex;
          return $hex if defined $hex && length $hex;
          return $value->ewkt;
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

version 0.900004

=head1 SYNOPSIS

  package MyApp::DB;
  use DBIO Schema => -pg;
  __PACKAGE__->pg_extensions('postgis');

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
objects on read and deflated on write: to the EWKB hex the object
carries if it was read from the database, to EWKT if it was built in
Perl (see L</register_column>).

=item *

Spatial-query helpers are mixed into the resultset class via
L<DBIO::PostgreSQL::PostGIS::ResultSet>.

=back

=head2 Activating PostGIS

PostGIS is a database extension, and a schema states that its database has it
in its list of extensions (ADR 0066), not by loading this component:

  package MyApp::DB;
  use DBIO Schema => -pg;
  __PACKAGE__->pg_extensions('postgis');                      # or
  __PACKAGE__->pg_extensions(postgis => { schema => 'gis' });

The driver resolves the name to L<DBIO::PostgreSQL::PostGIS::Extension>. That
class carries the model rules (the geometry type and SRID of a column; the
verdict on a change of them: another SRID is converted with C<ST_Transform>,
another type is refused), names the storage layer
(L<DBIO::PostgreSQL::PostGIS::Storage>: C<ensure_postgis>, C<postgis_version>)
and names this component as the inflation. C<postgis_topology> is its own
extension with its own class, L<DBIO::PostgreSQL::PostGIS::Topology::Extension>.
The C<::Deploy> and C<::Introspect> classes of this distribution are stubs.

This component is the result side. Loading it in a result class gives the
inflation and the resultset helpers above. Loading it on a schema registers the
storage layer too, which the driver does for a declared C<postgis> anyway
(registering twice is a no-op); the layer is composed over the resolved driver
storage (see L<DBIO::Storage::Composed>).

=head1 METHODS

=head2 register_column

Hooks into the column registration chain. When a column declares
C<< data_type => 'geometry' >> or C<< 'geography' >>, registers
inflate/deflate handlers for L<DBIO::PostgreSQL::PostGIS::Geometry>
objects.

B<Inflate> takes whichever text form the database returned: EWKB hex
(what PostGIS sends for a plain C<SELECT geom>), EWKT (C<SRID=N;...>, as
from C<ST_AsEWKT>), or plain WKT, which gets the column's C<srid>.

Only C<NULL> inflates to C<undef>. Every other value inflates to a
Geometry object, and that includes the geometry types this distribution
names and does not decode: C<CIRCULARSTRING>, C<COMPOUNDCURVE>,
C<CURVEPOLYGON>, C<MULTICURVE>, C<MULTISURFACE>, C<POLYHEDRALSURFACE>,
C<TIN>, C<TRIANGLE>, and a C<GEOMETRYCOLLECTION> holding one of them.
Such an object has its C<ewkb_hex>, the C<srid> and the
C<geometry_type> of the value (C<circularstring>, ...) and no
coordinates -- C<coordinates>, C<wkt>, C<bbox> and the like return
C<undef>, see L<DBIO::PostgreSQL::PostGIS::Geometry/from_ewkb_hex>. It
is written back as its hex like any other read value, so the row stays
readable, and its geometry can be copied to another row, without Perl
knowing its coordinates. The alternative, an inflater that throws on
such a value, would make every row holding one unreadable.

B<Deflate> writes a Geometry object in the most faithful form it has:

=over 4

=item *

An object that carries EWKB hex -- every value inflated from a plain
C<SELECT> does -- is written as that hex, unchanged. Reading a geometry
and writing it to another row (C<< $b->geom($a->geom); $b->update >>, or
a C<create> with it) therefore stores the same geometry: same type, same
Z/M dimension, the same doubles bit for bit. PostGIS takes the hex for
C<geometry> and C<geography> columns alike.

=item *

An object without hex (an empty C<ewkb_hex> is no hex; built with
C<point>, C<linestring>, C<polygon>, C<from_wkt>, C<from_ewkt>,
C<from_geojson>, ...) is written as EWKT, C<SRID=N;WKT>, or as bare WKT
when it has no SRID.

=item *

An object with none of these -- no hex, no WKT and no coordinates, or
coordinates without a C<geometry_type> to build a WKT under -- B<throws> a
L<DBIO::Exception> that says what is missing. It is not written as
C<NULL>: C<NULL> is what C<undef> stands for, and an object is not
C<undef>. (It was written as C<NULL>, or, for coordinates without a type,
as C<()>, which the server refuses.)

=back

A plain string is passed through as it is, whichever of the three forms
it holds.

Override the auto-detection by setting C<< inflate_geometry => 0 >>
explicitly on the column.

Also promotes the result source's C<resultset_class> to
L<DBIO::PostgreSQL::PostGIS::ResultSet> the first time a spatial column is
registered, giving the resultset spatial-query helpers (C<within_distance>,
C<nearest_to>, etc.). If you need custom resultset methods alongside the
PostGIS helpers, subclass L<DBIO::PostgreSQL::PostGIS::ResultSet> and set
C<resultset_class> to your subclass — the promotion guard skips any class
that already inherits from C<DBIO::PostgreSQL::PostGIS::ResultSet>.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::PostgreSQL> - Base PostgreSQL driver component

=item * L<DBIO::PostgreSQL::PostGIS::Geometry> - Lightweight geometry value object

=item * L<DBIO::PostgreSQL::PostGIS::Extension> - The extension class: model rules for deploy, introspection and diff

=item * L<DBIO::PostgreSQL::PostGIS::Topology::Extension> - The postgis_topology extension

=item * L<DBIO::PostgreSQL::PostGIS::Storage> - Storage layer with spatial methods

=item * L<DBIO::PostgreSQL::PostGIS::ResultSet> - Spatial query helpers

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
