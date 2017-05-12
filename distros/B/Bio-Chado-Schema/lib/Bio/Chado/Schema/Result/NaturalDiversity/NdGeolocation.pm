package Bio::Chado::Schema::Result::NaturalDiversity::NdGeolocation;
BEGIN {
  $Bio::Chado::Schema::Result::NaturalDiversity::NdGeolocation::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::NaturalDiversity::NdGeolocation::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::NaturalDiversity::NdGeolocation

=head1 DESCRIPTION

The geo-referencable location of the stock. NOTE: This entity is subject to change as a more general and possibly more OpenGIS-compliant geolocation module may be introduced into Chado.

=cut

__PACKAGE__->table("nd_geolocation");

=head1 ACCESSORS

=head2 nd_geolocation_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_geolocation_nd_geolocation_id_seq'

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 255

A textual representation of the location, if this is the original georeference. Optional if the original georeference is available in lat/long coordinates.

=head2 latitude

  data_type: 'real'
  is_nullable: 1

The decimal latitude coordinate of the georeference, using positive and negative sign to indicate N and S, respectively.

=head2 longitude

  data_type: 'real'
  is_nullable: 1

The decimal longitude coordinate of the georeference, using positive and negative sign to indicate E and W, respectively.

=head2 geodetic_datum

  data_type: 'varchar'
  is_nullable: 1
  size: 32

The geodetic system on which the geo-reference coordinates are based. For geo-references measured between 1984 and 2010, this will typically be WGS84.

=head2 altitude

  data_type: 'real'
  is_nullable: 1

The altitude (elevation) of the location in meters. If the altitude is only known as a range, this is the average, and altitude_dev will hold half of the width of the range.

=cut

__PACKAGE__->add_columns(
  "nd_geolocation_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_geolocation_nd_geolocation_id_seq",
  },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "latitude",
  { data_type => "real", is_nullable => 1 },
  "longitude",
  { data_type => "real", is_nullable => 1 },
  "geodetic_datum",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "altitude",
  { data_type => "real", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("nd_geolocation_id");

=head1 RELATIONS

=head2 nd_experiments

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperiment>

=cut

__PACKAGE__->has_many(
  "nd_experiments",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperiment",
  { "foreign.nd_geolocation_id" => "self.nd_geolocation_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_geolocationprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdGeolocationprop>

=cut

__PACKAGE__->has_many(
  "nd_geolocationprops",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdGeolocationprop",
  { "foreign.nd_geolocation_id" => "self.nd_geolocation_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ON4sQF043ybOTaJjiUnQcA


=head2 create_geolocationprops

  Usage: $set->create_geolocationprops({ baz => 2, foo => 'bar' });
  Desc : convenience method to create geolocation properties using cvterms
          from the ontology with the given name
  Args : hashref of { propname => value, ...},
         options hashref as:
          {
            autocreate => 0,
               (optional) boolean, if passed, automatically create cv,
               cvterm, and dbxref rows if one cannot be found for the
               given geolocationprop name.  Default false.

            cv_name => cv.name to use for the given geolocationprops.
                       Defaults to 'geolocation_property',

            db_name => db.name to use for autocreated dbxrefs,
                       default 'null',

            dbxref_accession_prefix => optional, default
                                       'autocreated:',
            definitions => optional hashref of:
                { cvterm_name => definition,
                }
             to load into the cvterm table when autocreating cvterms

             rank => force numeric rank. Be careful not to pass ranks that already exist
                     for the property type. The function will die in such case.

             allow_duplicate_values => default false.
                If true, allow duplicate instances of the same geolocation
                and value in the properties of the geolocation.  Duplicate
                values will have different ranks.
          }
  Ret  : hashref of { propname => new geolocationprop object }

=cut

sub create_geolocationprops {
    my ($self, $props, $opts) = @_;

    # process opts
    $opts->{cv_name} = 'geolocation_property'
        unless defined $opts->{cv_name};
    return Bio::Chado::Schema::Util->create_properties
        ( properties => $props,
          options    => $opts,
          row        => $self,
          prop_relation_name => 'nd_geolocationprops',
        );
}


# You can replace this text with custom content, and it will be preserved on regeneration
1;
