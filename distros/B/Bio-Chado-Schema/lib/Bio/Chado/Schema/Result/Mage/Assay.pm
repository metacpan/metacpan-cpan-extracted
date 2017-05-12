package Bio::Chado::Schema::Result::Mage::Assay;
BEGIN {
  $Bio::Chado::Schema::Result::Mage::Assay::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Mage::Assay::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Mage::Assay

=head1 DESCRIPTION

An assay consists of a physical instance of
an array, combined with the conditions used to create the array
(protocols, technician information). The assay can be thought of as a hybridization.

=cut

__PACKAGE__->table("assay");

=head1 ACCESSORS

=head2 assay_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'assay_assay_id_seq'

=head2 arraydesign_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 assaydate

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 arrayidentifier

  data_type: 'text'
  is_nullable: 1

=head2 arraybatchidentifier

  data_type: 'text'
  is_nullable: 1

=head2 operator_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

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
  "assay_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "assay_assay_id_seq",
  },
  "arraydesign_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "assaydate",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "arrayidentifier",
  { data_type => "text", is_nullable => 1 },
  "arraybatchidentifier",
  { data_type => "text", is_nullable => 1 },
  "operator_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("assay_id");
__PACKAGE__->add_unique_constraint("assay_c1", ["name"]);

=head1 RELATIONS

=head2 acquisitions

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Acquisition>

=cut

__PACKAGE__->has_many(
  "acquisitions",
  "Bio::Chado::Schema::Result::Mage::Acquisition",
  { "foreign.assay_id" => "self.assay_id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 operator

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Contact::Contact>

=cut

__PACKAGE__->belongs_to(
  "operator",
  "Bio::Chado::Schema::Result::Contact::Contact",
  { contact_id => "operator_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 protocol

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Mage::Protocol>

=cut

__PACKAGE__->belongs_to(
  "protocol",
  "Bio::Chado::Schema::Result::Mage::Protocol",
  { protocol_id => "protocol_id" },
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

=head2 assay_biomaterials

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::AssayBiomaterial>

=cut

__PACKAGE__->has_many(
  "assay_biomaterials",
  "Bio::Chado::Schema::Result::Mage::AssayBiomaterial",
  { "foreign.assay_id" => "self.assay_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 assay_projects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::AssayProject>

=cut

__PACKAGE__->has_many(
  "assay_projects",
  "Bio::Chado::Schema::Result::Mage::AssayProject",
  { "foreign.assay_id" => "self.assay_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 assayprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Assayprop>

=cut

__PACKAGE__->has_many(
  "assayprops",
  "Bio::Chado::Schema::Result::Mage::Assayprop",
  { "foreign.assay_id" => "self.assay_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 controls

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Control>

=cut

__PACKAGE__->has_many(
  "controls",
  "Bio::Chado::Schema::Result::Mage::Control",
  { "foreign.assay_id" => "self.assay_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 study_assays

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::StudyAssay>

=cut

__PACKAGE__->has_many(
  "study_assays",
  "Bio::Chado::Schema::Result::Mage::StudyAssay",
  { "foreign.assay_id" => "self.assay_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studyfactorvalues

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Studyfactorvalue>

=cut

__PACKAGE__->has_many(
  "studyfactorvalues",
  "Bio::Chado::Schema::Result::Mage::Studyfactorvalue",
  { "foreign.assay_id" => "self.assay_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tNB0k+0FwL4Nqs2ui/ahrQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
