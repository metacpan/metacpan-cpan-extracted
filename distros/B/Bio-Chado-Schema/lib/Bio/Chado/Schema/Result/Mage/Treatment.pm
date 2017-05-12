package Bio::Chado::Schema::Result::Mage::Treatment;
BEGIN {
  $Bio::Chado::Schema::Result::Mage::Treatment::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Mage::Treatment::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Mage::Treatment

=head1 DESCRIPTION

A biomaterial may undergo multiple
treatments. Examples of treatments: apoxia, fluorophore and biotin labeling.

=cut

__PACKAGE__->table("treatment");

=head1 ACCESSORS

=head2 treatment_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'treatment_treatment_id_seq'

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 biomaterial_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "treatment_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "treatment_treatment_id_seq",
  },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "biomaterial_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("treatment_id");

=head1 RELATIONS

=head2 biomaterial_treatments

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::BiomaterialTreatment>

=cut

__PACKAGE__->has_many(
  "biomaterial_treatments",
  "Bio::Chado::Schema::Result::Mage::BiomaterialTreatment",
  { "foreign.treatment_id" => "self.treatment_id" },
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

=head2 biomaterial

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Mage::Biomaterial>

=cut

__PACKAGE__->belongs_to(
  "biomaterial",
  "Bio::Chado::Schema::Result::Mage::Biomaterial",
  { biomaterial_id => "biomaterial_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WPwU6fqrHkdVhvYZc69hsQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
