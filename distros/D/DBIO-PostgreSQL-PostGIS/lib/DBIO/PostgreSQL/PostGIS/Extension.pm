package DBIO::PostgreSQL::PostGIS::Extension;
# ABSTRACT: The postgis extension for deploy, introspection and diff (DBIO extension interface)

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Extension';

use DBIO::PostgreSQL::Util ();


sub extension_interface { 1 }

sub name { 'postgis' }

sub driver { 'DBIO::PostgreSQL' }


sub storage_layer { 'DBIO::PostgreSQL::PostGIS::Storage' }


sub inflation_component { 'DBIO::PostgreSQL::PostGIS' }


sub annotate {
  my ($class, $model, $ctx) = @_;

  # The schema the types live in, per side of the diff: the model's own word
  # first (a temp database may differ from the live one), the entry's second.
  my $postgis_schema = ($model->{extensions} // {})->{postgis}
    ? $model->{extensions}{postgis}{schema_name}
    : undef;
  $postgis_schema //= ($ctx->{self} // {})->{schema};

  my @triples;
  my $columns_by_table = $model->{columns} // {};
  for my $table_key (sort keys %$columns_by_table) {
    for my $col (@{ $columns_by_table->{$table_key} // [] }) {
      my $dt = $col->{data_type} // '';
      next unless $dt =~ /\A
        (?: (?: "((?:[^"]|"")+)" | ([A-Za-z_][\w\$]*) ) \. )?
        (geometry|geography)
        (?: \( (\w+) (?: ,(\d+) )? \) )?
      \z/xi;
      my ($quoted, $plain, $base, $gtype, $srid) = ($1, $2, $3, $4, $5);

      if (defined $postgis_schema) {
        # Where the type lives: the catalog's word first, the prefix of the
        # string otherwise. Only when neither says, the type is taken as
        # PostGIS's -- an unqualified name is resolved through the
        # search_path, and the search_path found the PostGIS type.
        my $schema = $col->{type_schema};
        unless (defined $schema) {
          if (defined $quoted) { ($schema = $quoted) =~ s/""/"/g }
          else                 { $schema = $plain }   # may be undef
        }
        next if defined $schema && $schema ne $postgis_schema;
      }

      my $address = [ column => $table_key, $col->{column_name} ];
      push @triples, [ $address, base_type => lc $base ];
      push @triples, [ $address, geometry_type => lc $gtype ] if $gtype;
      push @triples, [ $address, srid => $srid + 0 ] if defined $srid;
    }
  }
  return \@triples;
}


sub verdict {
  my ($class, $change, $ctx) = @_;
  return undef unless ($change->{kind} // '') eq 'column_type';

  my ($old, $new) = @{$change}{qw(old_info new_info)};
  return undef unless $old && $new
    && defined $old->{base_type} && defined $new->{base_type};

  my $column = $change->{column_name};

  # the one place that refuses a change of type
  if ($old->{base_type} ne $new->{base_type}
      || (defined $old->{geometry_type} && defined $new->{geometry_type}
          && $old->{geometry_type} ne $new->{geometry_type})) {
    my $what = sub {
      my ($i) = @_;
      join ' ', grep { defined } $i->{base_type}, $i->{geometry_type};
    };
    return { refuse => sprintf
        "column %s.%s changes from %s to %s. A change of the geometry type, "
      . "or between geometry and geography, has no conversion the diff can "
      . "write; the server refuses it on a table that holds rows. No "
      . "statement was generated. Add a column of the new type, fill it, "
      . "and drop the old one.",
      $change->{table} // '', $column, $what->($old), $what->($new) };
  }

  my ($from, $to) = ($old->{srid}, $new->{srid});
  return undef unless $from && $to && $from != $to;

  my $expr = DBIO::PostgreSQL::Util::quote_ident($column);
  return { using => $new->{base_type} eq 'geography'
    ? sprintf('ST_Transform(%s::geometry, %d)::geography', $expr, $to)
    : sprintf('ST_Transform(%s, %d)', $expr, $to) };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::Extension - The postgis extension for deploy, introspection and diff (DBIO extension interface)

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

An application states that its database has PostGIS in the schema's
declaration; that is all it writes:

  package MyApp::DB;
  use DBIO Schema => -pg;
  __PACKAGE__->pg_extensions(postgis => { schema => 'gis' });

The driver resolves the name C<postgis> to this class (its table of the
family's extensions), so the rules below apply to this schema and to no other.

=head1 DESCRIPTION

The model knowledge of PostGIS, as a class of the extension interface of
L<DBIO::Extension> (ADR 0066). It replaces the Deploy and Introspect
subclasses this distribution used to carry
(C<DBIO::PostgreSQL::PostGIS::Deploy>, C<::Introspect>), which are stubs now:
nothing is composed into a Deploy class, no introspector is synthesised, and
no hook is registered into a driver registry.

=head2 What each method answers

=over 4

=item C<inspect>

Nothing. The installed state (version, schema) is the driver's catalog read
and is in the extension's entry.

=item C<claims>

Nothing, by measurement and not by omission. The objects PostGIS puts into a
database -- C<spatial_ref_sys>, the views C<geometry_columns> and
C<geography_columns>, its types, functions and operators -- are members of the
extension in C<pg_depend>, and the driver's base filter keeps members out of
the model. PostGIS creates no objects at runtime in the application's
namespaces. (The topologies of C<postgis_topology> do; they are claimed by
L<DBIO::PostgreSQL::PostGIS::Topology::Extension>. The graph schemas of Apache
AGE belong to AGE; phase 2 sees the model after the claims of phase 1, so a
geometry column a user put into a label table is gone before PostGIS
annotates.)

=item C<annotate>

C<base_type> (C<geometry> or C<geography>), C<geometry_type> (lower case,
C<point>) and C<srid> on each column whose type lives in the PostGIS schema,
parsed from the C<data_type> string (C<geometry(Point,4326)>), at the address
C<< [ column => $table_key, $column_name ] >>. See L</annotate>.

=item C<verdict>

A column type change between spatial types: another SRID is converted with
C<ST_Transform>, anything else is refused. See L</verdict>.

=item C<activation>

Nothing. PostGIS needs no C<LOAD> and no C<search_path> entry of its own.

=item C<storage_layer>

L<DBIO::PostgreSQL::PostGIS::Storage> (C<ensure_postgis>, C<postgis_version>),
registered by the driver for a declared C<postgis>.

=item C<inflation_component>

L<DBIO::PostgreSQL::PostGIS>, the result-class component that inflates
C<geometry>/C<geography> columns to L<DBIO::PostgreSQL::PostGIS::Geometry>
objects. See L</inflation_component>.

=back

=head2 Peers

PostGIS reads no peer. The graph schemas of AGE are not its model because
AGE's claims run in phase 1; no code here depends on AGE being present.

=head1 METHODS

=head2 extension_interface

Returns C<1>.

=head2 name

Returns C<postgis>, the C<pg_extension.extname>.

=head2 driver

Returns C<DBIO::PostgreSQL>, the driver this extension belongs to (an
assertion, never a determination of the driver).

=head2 storage_layer

Returns C<DBIO::PostgreSQL::PostGIS::Storage>, the runtime layer of the
extension.

=head2 inflation_component

  my $component = DBIO::PostgreSQL::PostGIS::Extension->inflation_component;

The result-side part of PostGIS: the component that gives a C<geometry> or
C<geography> column its inflate/deflate handlers and the spatial resultset
helpers. ADR 0066 (Decisions, 2) has the extension class name it and the driver
apply it for a declared C<postgis>. Core's L<DBIO::Extension> has no method for
it (yet): this one is not part of interface version 1, the driver asks for it
with C<< ->can >>.

=head2 annotate

  my $triples = DBIO::PostgreSQL::PostGIS::Extension->annotate($model, $ctx);

Phase 2. For each column of C<< $model->{columns} >> whose C<data_type> is
C<geometry> or C<geography>, with or without the modifier and with a schema
prefix, quoted or not (C<public.geometry(Point,4326)>, C<"My Schema".geometry>),
the triples C<base_type>, C<geometry_type> (when the type has a modifier) and
C<srid> (when it has one), at C<< [ column => $table_key, $column_name ] >>.

A column is annotated only if its type lives in the PostGIS schema -- the
C<type_schema> of the column hash, else the prefix of the string -- so a
foreign type named C<geometry> in another schema is left alone. The PostGIS
schema is the one of the model's C<extensions> section, else the one of the
extension's entry. Without it (no PostGIS in the model, no installed state)
every type named C<geometry>/C<geography> is annotated, and so is a column
with neither C<type_schema> nor a prefix: when the evidence is missing the type
is taken as PostGIS's, because staying silent about an unclear case is how
this once skipped schema-qualified types unnoticed. A quoted prefix
is compared as written, case included.

The model is read, not changed.

=head2 verdict

  my $answer = DBIO::PostgreSQL::PostGIS::Extension->verdict($change, $ctx);

Phase 3, for a change C<< { kind => 'column_type', table, column_name,
old_info, new_info } >>. The infos carry the annotations of phase 2.

=over 4

=item * the same type (C<geometry> or C<geography>, the same geometry type)
under another SRID is B<converted>: C<< { using => 'ST_Transform(column, srid)' } >>,
for a geography through geometry and back. The coordinates are recomputed, not
relabelled.

=item * any other change between two spatial types -- another geometry type,
C<geometry> to C<geography> or back -- is B<refused>: C<< { refuse => ... } >>
naming the column and both types.

=item * everything else (not spatial on either side, an unconstrained
C<geometry> on either side, an SRID that is not given) is none of this
extension's business: C<undef>.

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
