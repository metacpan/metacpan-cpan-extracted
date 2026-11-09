package DBIO::PostgreSQL::PostGIS::ResultSet;
# ABSTRACT: Spatial query helpers for PostGIS-aware result classes

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::ResultSet';
use DBIO::Exception ();
use DBIO::PostgreSQL::Util ();


# Render the user-supplied geometry argument into ('SQL fragment', @binds)
# suitable for splicing into a -bool/-and ScalarRef literal.
sub _geom_arg {
  my ($self, $geom) = @_;
  if (ref($geom) eq 'SCALAR') {
    return ($$geom);
  }
  if (ref($geom) eq 'REF' && ref($$geom) eq 'ARRAY') {
    my ($sql, @binds) = @{$$geom};
    return ($sql, @binds);
  }
  if (ref($geom) && $geom->isa('DBIO::PostgreSQL::PostGIS::Geometry')) {
    my $srid = $geom->srid;
    # A value read from the database goes back as the EWKB hex it arrived
    # as: its WKT is a rendering, 15 digits per ordinate, and not the
    # stored geometry (karr k22). The hex carries its own SRID flag; the
    # object's srid, when it has one, is set over it as before.
    my $hex = $geom->ewkb_hex;
    if (defined $hex && length $hex) {
      return ('ST_SetSRID(?::geometry, ?)', $hex, $srid) if defined $srid;
      return ('?::geometry', $hex);
    }
    my $why = $geom->_unwritable_reason;
    DBIO::Exception->throw($why) if defined $why;
    my $wkt = $geom->wkt;
    if (defined $srid) {
      return ('ST_GeomFromText(?, ?)', $wkt, $srid);
    }
    return ('ST_GeomFromText(?)', $wkt);
  }
  # Plain EWKT string
  return ('ST_GeomFromEWKT(?)', $geom);
}

# The quoted reference to a column of the source: "alias"."column". The name
# is an identifier of the source, never SQL.
sub _col_ref {
  my ($self, $col) = @_;
  DBIO::Exception->throw("no column '" . ($col // '') . "' in the source of this resultset")
    unless defined $col && !ref $col && $self->result_source->has_column($col);
  return DBIO::PostgreSQL::Util::quote_ident($self->current_source_alias)
    . '.' . DBIO::PostgreSQL::Util::quote_ident($col);
}

sub _spatial_search {
  my ($self, $sql_func, $col, $geom, @extra) = @_;
  my ($geom_sql, @binds) = $self->_geom_arg($geom);
  my $ref = $self->_col_ref($col);
  return $self->search({
    -bool => \[ "$sql_func($ref, $geom_sql"
              . (@extra ? ', ' . join(', ', ('?') x scalar @extra) : '')
              . ')',
              @binds, @extra ],
  });
}

my @_SIMPLE_PREDICATES = (
  [ intersects => 'ST_Intersects' ],
  [ contains   => 'ST_Contains'   ],
  [ within     => 'ST_Within'     ],
  [ touches    => 'ST_Touches'    ],
  [ crosses    => 'ST_Crosses'    ],
  [ overlaps   => 'ST_Overlaps'  ],
);


for my $pred (@_SIMPLE_PREDICATES) {
  my ($name, $func) = @$pred;
  no strict 'refs';
  *{__PACKAGE__ . "::$name"} = sub {
    my ($self, $col, $geom) = @_;
    return $self->_spatial_search($func, $col, $geom);
  };
}


sub within_distance {
  my ($self, $col, $geom, $dist) = @_;
  return $self->_spatial_search('ST_DWithin', $col, $geom, $dist);
}


sub bbox_intersects {
  my ($self, $col, $geom) = @_;
  my ($geom_sql, @binds) = $self->_geom_arg($geom);
  my $ref = $self->_col_ref($col);
  return $self->search({
    -bool => \[ "$ref && $geom_sql", @binds ],
  });
}


sub nearest_to {
  my ($self, $col, $geom, $limit) = @_;
  my ($geom_sql, @binds) = $self->_geom_arg($geom);
  my $ref = $self->_col_ref($col);
  my $rs = $self->search(undef, {
    order_by => \[ "$ref <-> $geom_sql", @binds ],
    ($limit ? (rows => $limit) : ()),
  });
  return $rs;
}


sub order_by_distance {
  my ($self, $col, $geom) = @_;
  my ($geom_sql, @binds) = $self->_geom_arg($geom);
  my $ref = $self->_col_ref($col);
  return $self->search(undef, {
    order_by => \[ "ST_Distance($ref, $geom_sql)", @binds ],
  });
}


sub with_distance {
  my ($self, $col, $geom, $alias) = @_;
  $alias //= 'distance';
  my ($geom_sql, @binds) = $self->_geom_arg($geom);
  my $ref = $self->_col_ref($col);
  return $self->search(undef, {
    '+select' => [ \[ "ST_Distance($ref, $geom_sql)", @binds ] ],
    '+as'     => [ $alias ],
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::ResultSet - Spatial query helpers for PostGIS-aware result classes

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  # Auto-set as resultset_class when load_components('PostgreSQL::PostGIS')
  # registers the first geometry/geography column.

  # Within distance (geography metres, geometry units of the SRID)
  my $rs = $schema->resultset('Place')->within_distance(
    geom => $point, 1000,
  );

  # Bounding-box / index-friendly intersect
  my $rs = $schema->resultset('Place')->bbox_intersects(geom => $bbox);

  # Exact spatial predicates
  $places->intersects(geom  => $polygon);
  $places->contains  (geom  => $point);
  $places->within    (geom  => $polygon);

  # KNN order — uses the <-> operator on a GIST index
  my $nearest = $schema->resultset('Place')->nearest_to(geom => $point, 10);

=head1 DESCRIPTION

Mixin of common spatial-query shortcuts. Every helper returns a chainable
resultset, so they compose with regular C<< ->search >> calls.

The geometry argument can be either a
L<DBIO::PostgreSQL::PostGIS::Geometry> instance, an EWKT string, or a
raw scalarref C<\['ST_...']> for fully custom SQL.

A Geometry object that was read from the database, or built with an
C<ewkb_hex>, is bound as that EWKB hex (C<?::geometry>, with
C<ST_SetSRID> over it when the object has an SRID): the stored geometry,
bit for bit, so a predicate that holds only for the exact value --
C<within_distance> with a distance of 0, C<touches>, C<contains> on an
edge -- holds for a geometry handed back from a row. An object without
hex is bound as its WKT (C<ST_GeomFromText>), 15 significant digits per
ordinate. A hex without an SRID flag is SRID 0, as it is on the server.

The column name every helper takes is an identifier, not an expression: it
names a column of the resultset's source, and the helper writes it quoted
together with the source alias (C<me.geom>, C<me."Geom">), so a C<MixedCase> name
keeps its case. A name the source does not have makes the helper throw a
L<DBIO::Exception> that names it.

A Geometry object with nothing to bind -- no hex, no WKT and no
coordinates, or coordinates without a C<geometry_type> -- is not an
argument: the helper throws a L<DBIO::Exception> that says what is
missing. It used to bind C<NULL>, and the search found nothing without
saying why.

=head2 Generated spatial predicate methods

The following methods are generated from C<@_SIMPLE_PREDICATES>:
C<intersects>, C<contains>, C<within>, C<touches>, C<crosses>, C<overlaps>.

Each takes C<($column, $geometry)> and returns a filtered resultset using the
corresponding PostGIS function.

=head1 METHODS

=head2 within_distance

  $rs->within_distance($column, $geometry, $distance);

Filter to rows where C<ST_DWithin($column, $geometry, $distance)> is true.
Distance is in metres for C<geography>, in SRID units for C<geometry>.

=head2 bbox_intersects

  $rs->bbox_intersects($column, $geometry);

Bounding-box overlap using the C<&&> operator. This is the cheapest
spatial predicate and the only one that uses a GIST index without
extra hints.

=head2 nearest_to

  $rs->nearest_to($column, $geometry);
  $rs->nearest_to($column, $geometry, $limit);

Order rows by distance from C<$geometry> using the C<< <-> >> KNN
operator, optionally limited.

=head2 order_by_distance

  $rs->order_by_distance($column, $geometry);

Like L</nearest_to> but uses C<ST_Distance> (exact, not the KNN
operator). Use this when you need the actual distance values; use
L</nearest_to> when you just want the closest N rows.

=head2 with_distance

  my $rs = $places->with_distance(geom => $point);
  while (my $row = $rs->next) {
    print $row->name, ' is ', $row->get_column('distance'), ' away';
  }

Selects an extra C<distance> column computed by C<ST_Distance>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
