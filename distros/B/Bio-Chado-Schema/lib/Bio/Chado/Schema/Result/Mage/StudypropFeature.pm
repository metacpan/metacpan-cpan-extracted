package Bio::Chado::Schema::Result::Mage::StudypropFeature;
BEGIN {
  $Bio::Chado::Schema::Result::Mage::StudypropFeature::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Mage::StudypropFeature::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Mage::StudypropFeature

=cut

__PACKAGE__->table("studyprop_feature");

=head1 ACCESSORS

=head2 studyprop_feature_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'studyprop_feature_studyprop_feature_id_seq'

=head2 studyprop_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 feature_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "studyprop_feature_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "studyprop_feature_studyprop_feature_id_seq",
  },
  "studyprop_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "feature_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("studyprop_feature_id");
__PACKAGE__->add_unique_constraint(
  "studyprop_feature_studyprop_id_key",
  ["studyprop_id", "feature_id"],
);

=head1 RELATIONS

=head2 studyprop

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Mage::Studyprop>

=cut

__PACKAGE__->belongs_to(
  "studyprop",
  "Bio::Chado::Schema::Result::Mage::Studyprop",
  { studyprop_id => "studyprop_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

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
    join_type      => "LEFT",
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2KkGjfzCBXVFGheJUG8e5g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
