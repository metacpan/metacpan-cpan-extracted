package Bio::Chado::Schema::Result::Mage::Biomaterial;
BEGIN {
  $Bio::Chado::Schema::Result::Mage::Biomaterial::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Mage::Biomaterial::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Mage::Biomaterial

=head1 DESCRIPTION

A biomaterial represents the MAGE concept of BioSource, BioSample, and LabeledExtract. It is essentially some biological material (tissue, cells, serum) that may have been processed. Processed biomaterials should be traceable back to raw biomaterials via the biomaterialrelationship table.

=cut

__PACKAGE__->table("biomaterial");

=head1 ACCESSORS

=head2 biomaterial_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'biomaterial_biomaterial_id_seq'

=head2 taxon_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 biosourceprovider_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "biomaterial_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "biomaterial_biomaterial_id_seq",
  },
  "taxon_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "biosourceprovider_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("biomaterial_id");
__PACKAGE__->add_unique_constraint("biomaterial_c1", ["name"]);

=head1 RELATIONS

=head2 assay_biomaterials

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::AssayBiomaterial>

=cut

__PACKAGE__->has_many(
  "assay_biomaterials",
  "Bio::Chado::Schema::Result::Mage::AssayBiomaterial",
  { "foreign.biomaterial_id" => "self.biomaterial_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 taxon

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Organism::Organism>

=cut

__PACKAGE__->belongs_to(
  "taxon",
  "Bio::Chado::Schema::Result::Organism::Organism",
  { organism_id => "taxon_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    join_type      => "LEFT",
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

=head2 biosourceprovider

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Contact::Contact>

=cut

__PACKAGE__->belongs_to(
  "biosourceprovider",
  "Bio::Chado::Schema::Result::Contact::Contact",
  { contact_id => "biosourceprovider_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 biomaterial_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::BiomaterialDbxref>

=cut

__PACKAGE__->has_many(
  "biomaterial_dbxrefs",
  "Bio::Chado::Schema::Result::Mage::BiomaterialDbxref",
  { "foreign.biomaterial_id" => "self.biomaterial_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 biomaterialprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Biomaterialprop>

=cut

__PACKAGE__->has_many(
  "biomaterialprops",
  "Bio::Chado::Schema::Result::Mage::Biomaterialprop",
  { "foreign.biomaterial_id" => "self.biomaterial_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 biomaterial_relationship_subjects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::BiomaterialRelationship>

=cut

__PACKAGE__->has_many(
  "biomaterial_relationship_subjects",
  "Bio::Chado::Schema::Result::Mage::BiomaterialRelationship",
  { "foreign.subject_id" => "self.biomaterial_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 biomaterial_relationship_objects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::BiomaterialRelationship>

=cut

__PACKAGE__->has_many(
  "biomaterial_relationship_objects",
  "Bio::Chado::Schema::Result::Mage::BiomaterialRelationship",
  { "foreign.object_id" => "self.biomaterial_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 biomaterial_treatments

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::BiomaterialTreatment>

=cut

__PACKAGE__->has_many(
  "biomaterial_treatments",
  "Bio::Chado::Schema::Result::Mage::BiomaterialTreatment",
  { "foreign.biomaterial_id" => "self.biomaterial_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 treatments

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Treatment>

=cut

__PACKAGE__->has_many(
  "treatments",
  "Bio::Chado::Schema::Result::Mage::Treatment",
  { "foreign.biomaterial_id" => "self.biomaterial_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/VQ8SGvWjdco22wrum1JHg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
