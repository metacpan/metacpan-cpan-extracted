package Bio::Chado::Schema::Result::Map::Featurepos;
BEGIN {
  $Bio::Chado::Schema::Result::Map::Featurepos::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Map::Featurepos::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Map::Featurepos

=cut

__PACKAGE__->table("featurepos");

=head1 ACCESSORS

=head2 featurepos_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'featurepos_featurepos_id_seq'

=head2 featuremap_id

  data_type: 'integer'
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 0
  sequence: 'featurepos_featuremap_id_seq'

=head2 feature_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 map_feature_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

map_feature_id
links to the feature (map) upon which the feature is being localized.

=head2 mappos

  data_type: 'double precision'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "featurepos_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "featurepos_featurepos_id_seq",
  },
  "featuremap_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_foreign_key    => 1,
    is_nullable       => 0,
    sequence          => "featurepos_featuremap_id_seq",
  },
  "feature_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "map_feature_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "mappos",
  { data_type => "double precision", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("featurepos_id");

=head1 RELATIONS

=head2 feature

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Sequence::Feature>

=cut

__PACKAGE__->belongs_to(
  "feature",
  "Bio::Chado::Schema::Result::Sequence::Feature",
  { feature_id => "feature_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 map_feature

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Sequence::Feature>

=cut

__PACKAGE__->belongs_to(
  "map_feature",
  "Bio::Chado::Schema::Result::Sequence::Feature",
  { feature_id => "map_feature_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 featuremap

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Map::Featuremap>

=cut

__PACKAGE__->belongs_to(
  "featuremap",
  "Bio::Chado::Schema::Result::Map::Featuremap",
  { featuremap_id => "featuremap_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jKXu0thkP5pIvZoMtuKe/Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
