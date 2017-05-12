package Bio::Chado::Schema::Result::Map::Featurerange;
BEGIN {
  $Bio::Chado::Schema::Result::Map::Featurerange::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Map::Featurerange::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Map::Featurerange

=head1 DESCRIPTION

In cases where the start and end of a mapped feature is a range, leftendf and rightstartf are populated. leftstartf_id, leftendf_id, rightstartf_id, rightendf_id are the ids of features with respect to which the feature is being mapped. These may be cytological bands.

=cut

__PACKAGE__->table("featurerange");

=head1 ACCESSORS

=head2 featurerange_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'featurerange_featurerange_id_seq'

=head2 featuremap_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

featuremap_id is the id of the feature being mapped.

=head2 feature_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 leftstartf_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 leftendf_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 rightstartf_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 rightendf_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 rangestr

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "featurerange_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "featurerange_featurerange_id_seq",
  },
  "featuremap_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "feature_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "leftstartf_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "leftendf_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "rightstartf_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "rightendf_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "rangestr",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("featurerange_id");

=head1 RELATIONS

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

=head2 leftendf

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Sequence::Feature>

=cut

__PACKAGE__->belongs_to(
  "leftendf",
  "Bio::Chado::Schema::Result::Sequence::Feature",
  { feature_id => "leftendf_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 rightstartf

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Sequence::Feature>

=cut

__PACKAGE__->belongs_to(
  "rightstartf",
  "Bio::Chado::Schema::Result::Sequence::Feature",
  { feature_id => "rightstartf_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 rightendf

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Sequence::Feature>

=cut

__PACKAGE__->belongs_to(
  "rightendf",
  "Bio::Chado::Schema::Result::Sequence::Feature",
  { feature_id => "rightendf_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 leftstartf

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Sequence::Feature>

=cut

__PACKAGE__->belongs_to(
  "leftstartf",
  "Bio::Chado::Schema::Result::Sequence::Feature",
  { feature_id => "leftstartf_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7AFKlnRnIayzBusw0IrRvA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
