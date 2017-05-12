package Bio::Chado::Schema::Result::NaturalDiversity::NdGeolocationprop;
BEGIN {
  $Bio::Chado::Schema::Result::NaturalDiversity::NdGeolocationprop::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::NaturalDiversity::NdGeolocationprop::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::NaturalDiversity::NdGeolocationprop

=head1 DESCRIPTION

Property/value associations for geolocations. This table can store the properties such as location and environment

=cut

__PACKAGE__->table("nd_geolocationprop");

=head1 ACCESSORS

=head2 nd_geolocationprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_geolocationprop_nd_geolocationprop_id_seq'

=head2 nd_geolocation_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The name of the property as a reference to a controlled vocabulary term.

=head2 value

  data_type: 'text'
  is_nullable: 1

The value of the property.

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

The rank of the property value, if the property has an array of values.

=cut

__PACKAGE__->add_columns(
  "nd_geolocationprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_geolocationprop_nd_geolocationprop_id_seq",
  },
  "nd_geolocation_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("nd_geolocationprop_id");
__PACKAGE__->add_unique_constraint(
  "nd_geolocationprop_c1",
  ["nd_geolocation_id", "type_id", "rank"],
);

=head1 RELATIONS

=head2 type

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "type_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 nd_geolocation

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdGeolocation>

=cut

__PACKAGE__->belongs_to(
  "nd_geolocation",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdGeolocation",
  { nd_geolocation_id => "nd_geolocation_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-22 08:45:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lkWxiu/JpcQtkdEj/OVkhQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
