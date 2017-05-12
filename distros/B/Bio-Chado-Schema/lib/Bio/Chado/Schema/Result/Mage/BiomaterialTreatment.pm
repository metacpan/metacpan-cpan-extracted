package Bio::Chado::Schema::Result::Mage::BiomaterialTreatment;
BEGIN {
  $Bio::Chado::Schema::Result::Mage::BiomaterialTreatment::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Mage::BiomaterialTreatment::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Mage::BiomaterialTreatment

=head1 DESCRIPTION

Link biomaterials to treatments. Treatments have an order of operations (rank), and associated measurements (unittype_id, value).

=cut

__PACKAGE__->table("biomaterial_treatment");

=head1 ACCESSORS

=head2 biomaterial_treatment_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'biomaterial_treatment_biomaterial_treatment_id_seq'

=head2 biomaterial_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 treatment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 unittype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 value

  data_type: 'real'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "biomaterial_treatment_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "biomaterial_treatment_biomaterial_treatment_id_seq",
  },
  "biomaterial_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "treatment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "unittype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "value",
  { data_type => "real", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("biomaterial_treatment_id");
__PACKAGE__->add_unique_constraint(
  "biomaterial_treatment_c1",
  ["biomaterial_id", "treatment_id"],
);

=head1 RELATIONS

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

=head2 treatment

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Mage::Treatment>

=cut

__PACKAGE__->belongs_to(
  "treatment",
  "Bio::Chado::Schema::Result::Mage::Treatment",
  { treatment_id => "treatment_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WtmDzrC052GEBuugTw29Jg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
