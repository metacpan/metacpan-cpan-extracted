package Bio::Chado::Schema::Result::Map::Featuremap;
BEGIN {
  $Bio::Chado::Schema::Result::Map::Featuremap::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Map::Featuremap::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Map::Featuremap

=cut

__PACKAGE__->table("featuremap");

=head1 ACCESSORS

=head2 featuremap_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'featuremap_featuremap_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 unittype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "featuremap_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "featuremap_featuremap_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "unittype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("featuremap_id");
__PACKAGE__->add_unique_constraint("featuremap_c1", ["name"]);

=head1 RELATIONS

=head2 unittype

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "unittype",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "unittype_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 featuremap_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Map::FeaturemapPub>

=cut

__PACKAGE__->has_many(
  "featuremap_pubs",
  "Bio::Chado::Schema::Result::Map::FeaturemapPub",
  { "foreign.featuremap_id" => "self.featuremap_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 featurepos

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Map::Featurepos>

=cut

__PACKAGE__->has_many(
  "featurepos",
  "Bio::Chado::Schema::Result::Map::Featurepos",
  { "foreign.featuremap_id" => "self.featuremap_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 featureranges

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Map::Featurerange>

=cut

__PACKAGE__->has_many(
  "featureranges",
  "Bio::Chado::Schema::Result::Map::Featurerange",
  { "foreign.featuremap_id" => "self.featuremap_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jzw5KVXwkfOSDiJv7ymTeQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
