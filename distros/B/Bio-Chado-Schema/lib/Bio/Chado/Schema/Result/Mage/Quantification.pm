package Bio::Chado::Schema::Result::Mage::Quantification;
BEGIN {
  $Bio::Chado::Schema::Result::Mage::Quantification::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Mage::Quantification::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Mage::Quantification

=head1 DESCRIPTION

Quantification is the transformation of an image acquisition to numeric data. This typically involves statistical procedures.

=cut

__PACKAGE__->table("quantification");

=head1 ACCESSORS

=head2 quantification_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'quantification_quantification_id_seq'

=head2 acquisition_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 operator_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 analysis_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 quantificationdate

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 uri

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "quantification_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "quantification_quantification_id_seq",
  },
  "acquisition_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "operator_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "analysis_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "quantificationdate",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "name",
  { data_type => "text", is_nullable => 1 },
  "uri",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("quantification_id");
__PACKAGE__->add_unique_constraint("quantification_c1", ["name", "analysis_id"]);

=head1 RELATIONS

=head2 elementresults

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Elementresult>

=cut

__PACKAGE__->has_many(
  "elementresults",
  "Bio::Chado::Schema::Result::Mage::Elementresult",
  { "foreign.quantification_id" => "self.quantification_id" },
  { cascade_copy => 0, cascade_delete => 0 },
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
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 analysis

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Companalysis::Analysis>

=cut

__PACKAGE__->belongs_to(
  "analysis",
  "Bio::Chado::Schema::Result::Companalysis::Analysis",
  { analysis_id => "analysis_id" },
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

=head2 acquisition

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Mage::Acquisition>

=cut

__PACKAGE__->belongs_to(
  "acquisition",
  "Bio::Chado::Schema::Result::Mage::Acquisition",
  { acquisition_id => "acquisition_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 quantificationprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Quantificationprop>

=cut

__PACKAGE__->has_many(
  "quantificationprops",
  "Bio::Chado::Schema::Result::Mage::Quantificationprop",
  { "foreign.quantification_id" => "self.quantification_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 quantification_relationship_subjects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::QuantificationRelationship>

=cut

__PACKAGE__->has_many(
  "quantification_relationship_subjects",
  "Bio::Chado::Schema::Result::Mage::QuantificationRelationship",
  { "foreign.subject_id" => "self.quantification_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 quantification_relationship_objects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::QuantificationRelationship>

=cut

__PACKAGE__->has_many(
  "quantification_relationship_objects",
  "Bio::Chado::Schema::Result::Mage::QuantificationRelationship",
  { "foreign.object_id" => "self.quantification_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:92+PlSTTq5w4uByxrfU3oA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
