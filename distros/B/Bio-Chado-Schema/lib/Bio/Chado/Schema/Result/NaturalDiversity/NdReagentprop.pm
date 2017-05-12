package Bio::Chado::Schema::Result::NaturalDiversity::NdReagentprop;
BEGIN {
  $Bio::Chado::Schema::Result::NaturalDiversity::NdReagentprop::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::NaturalDiversity::NdReagentprop::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::NaturalDiversity::NdReagentprop

=cut

__PACKAGE__->table("nd_reagentprop");

=head1 ACCESSORS

=head2 nd_reagentprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_reagentprop_nd_reagentprop_id_seq'

=head2 nd_reagent_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nd_reagentprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_reagentprop_nd_reagentprop_id_seq",
  },
  "nd_reagent_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("nd_reagentprop_id");
__PACKAGE__->add_unique_constraint("nd_reagentprop_c1", ["nd_reagent_id", "type_id", "rank"]);

=head1 RELATIONS

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

=head2 nd_reagent

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdReagent>

=cut

__PACKAGE__->belongs_to(
  "nd_reagent",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdReagent",
  { nd_reagent_id => "nd_reagent_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-22 08:45:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:flxma2G8iHyMGeyBYseviQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
