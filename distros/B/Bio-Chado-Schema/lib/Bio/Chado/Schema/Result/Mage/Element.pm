package Bio::Chado::Schema::Result::Mage::Element;
BEGIN {
  $Bio::Chado::Schema::Result::Mage::Element::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Mage::Element::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Mage::Element

=head1 DESCRIPTION

Represents a feature of the array. This is typically a region of the array coated or bound to DNA.

=cut

__PACKAGE__->table("element");

=head1 ACCESSORS

=head2 element_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'element_element_id_seq'

=head2 feature_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 arraydesign_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "element_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "element_element_id_seq",
  },
  "feature_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "arraydesign_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("element_id");
__PACKAGE__->add_unique_constraint("element_c1", ["feature_id", "arraydesign_id"]);

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
    join_type      => "LEFT",
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

=head2 arraydesign

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Mage::Arraydesign>

=cut

__PACKAGE__->belongs_to(
  "arraydesign",
  "Bio::Chado::Schema::Result::Mage::Arraydesign",
  { arraydesign_id => "arraydesign_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 dbxref

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::General::Dbxref>

=cut

__PACKAGE__->belongs_to(
  "dbxref",
  "Bio::Chado::Schema::Result::General::Dbxref",
  { dbxref_id => "dbxref_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 element_relationship_objects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::ElementRelationship>

=cut

__PACKAGE__->has_many(
  "element_relationship_objects",
  "Bio::Chado::Schema::Result::Mage::ElementRelationship",
  { "foreign.object_id" => "self.element_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 element_relationship_subjects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::ElementRelationship>

=cut

__PACKAGE__->has_many(
  "element_relationship_subjects",
  "Bio::Chado::Schema::Result::Mage::ElementRelationship",
  { "foreign.subject_id" => "self.element_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 elementresults

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Elementresult>

=cut

__PACKAGE__->has_many(
  "elementresults",
  "Bio::Chado::Schema::Result::Mage::Elementresult",
  { "foreign.element_id" => "self.element_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RRDh549Rn1su0y6fYGzk5Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
