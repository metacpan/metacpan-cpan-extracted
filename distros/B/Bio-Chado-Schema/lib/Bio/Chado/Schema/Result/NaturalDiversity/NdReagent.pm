package Bio::Chado::Schema::Result::NaturalDiversity::NdReagent;
BEGIN {
  $Bio::Chado::Schema::Result::NaturalDiversity::NdReagent::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::NaturalDiversity::NdReagent::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::NaturalDiversity::NdReagent

=head1 DESCRIPTION

A reagent such as a primer, an enzyme, an adapter oligo, a linker oligo. Reagents are used in genotyping experiments, or in any other kind of experiment.

=cut

__PACKAGE__->table("nd_reagent");

=head1 ACCESSORS

=head2 nd_reagent_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_reagent_nd_reagent_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 80

The name of the reagent. The name should be unique for a given type.

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The type of the reagent, for example linker oligomer, or forward primer.

=head2 feature_id

  data_type: 'integer'
  is_nullable: 1

If the reagent is a primer, the feature that it corresponds to. More generally, the corresponding feature for any reagent that has a sequence that maps to another sequence.

=cut

__PACKAGE__->add_columns(
  "nd_reagent_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_reagent_nd_reagent_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 80 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "feature_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("nd_reagent_id");

=head1 RELATIONS

=head2 nd_protocol_reagents

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdProtocolReagent>

=cut

__PACKAGE__->has_many(
  "nd_protocol_reagents",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdProtocolReagent",
  { "foreign.reagent_id" => "self.nd_reagent_id" },
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

=head2 nd_reagentprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdReagentprop>

=cut

__PACKAGE__->has_many(
  "nd_reagentprops",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdReagentprop",
  { "foreign.nd_reagent_id" => "self.nd_reagent_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_reagent_relationship_subject_reagents

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdReagentRelationship>

=cut

__PACKAGE__->has_many(
  "nd_reagent_relationship_subject_reagents",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdReagentRelationship",
  { "foreign.subject_reagent_id" => "self.nd_reagent_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_reagent_relationship_object_reagents

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdReagentRelationship>

=cut

__PACKAGE__->has_many(
  "nd_reagent_relationship_object_reagents",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdReagentRelationship",
  { "foreign.object_reagent_id" => "self.nd_reagent_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PMHkXnl3T1E1JzdmDsWTOw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
