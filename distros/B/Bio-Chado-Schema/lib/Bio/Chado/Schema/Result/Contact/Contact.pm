package Bio::Chado::Schema::Result::Contact::Contact;
BEGIN {
  $Bio::Chado::Schema::Result::Contact::Contact::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Contact::Contact::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Contact::Contact - Model persons, institutes, groups, organizations, etc.

=cut

__PACKAGE__->table("contact");

=head1 ACCESSORS

=head2 contact_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'contact_contact_id_seq'

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

What type of contact is this?  E.g. "person", "lab".

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "contact_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "contact_contact_id_seq",
  },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("contact_id");
__PACKAGE__->add_unique_constraint("contact_c1", ["name"]);

=head1 RELATIONS

=head2 arraydesigns

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Arraydesign>

=cut

__PACKAGE__->has_many(
  "arraydesigns",
  "Bio::Chado::Schema::Result::Mage::Arraydesign",
  { "foreign.manufacturer_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 assays

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Assay>

=cut

__PACKAGE__->has_many(
  "assays",
  "Bio::Chado::Schema::Result::Mage::Assay",
  { "foreign.operator_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 biomaterials

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Biomaterial>

=cut

__PACKAGE__->has_many(
  "biomaterials",
  "Bio::Chado::Schema::Result::Mage::Biomaterial",
  { "foreign.biosourceprovider_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 contact_relationship_objects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Contact::ContactRelationship>

=cut

__PACKAGE__->has_many(
  "contact_relationship_objects",
  "Bio::Chado::Schema::Result::Contact::ContactRelationship",
  { "foreign.object_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 contact_relationship_subjects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Contact::ContactRelationship>

=cut

__PACKAGE__->has_many(
  "contact_relationship_subjects",
  "Bio::Chado::Schema::Result::Contact::ContactRelationship",
  { "foreign.subject_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_contacts

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentContact>

=cut

__PACKAGE__->has_many(
  "nd_experiment_contacts",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentContact",
  { "foreign.contact_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_contacts

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Project::ProjectContact>

=cut

__PACKAGE__->has_many(
  "project_contacts",
  "Bio::Chado::Schema::Result::Project::ProjectContact",
  { "foreign.contact_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 quantifications

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Quantification>

=cut

__PACKAGE__->has_many(
  "quantifications",
  "Bio::Chado::Schema::Result::Mage::Quantification",
  { "foreign.operator_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stockcollections

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::Stockcollection>

=cut

__PACKAGE__->has_many(
  "stockcollections",
  "Bio::Chado::Schema::Result::Stock::Stockcollection",
  { "foreign.contact_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studies

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Study>

=cut

__PACKAGE__->has_many(
  "studies",
  "Bio::Chado::Schema::Result::Mage::Study",
  { "foreign.contact_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7KIOnPWNyVs/NPhRJ3bFYg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
