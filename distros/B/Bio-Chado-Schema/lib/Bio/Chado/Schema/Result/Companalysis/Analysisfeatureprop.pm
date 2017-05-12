package Bio::Chado::Schema::Result::Companalysis::Analysisfeatureprop;
BEGIN {
  $Bio::Chado::Schema::Result::Companalysis::Analysisfeatureprop::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Companalysis::Analysisfeatureprop::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Companalysis::Analysisfeatureprop

=cut

__PACKAGE__->table("analysisfeatureprop");

=head1 ACCESSORS

=head2 analysisfeatureprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'analysisfeatureprop_analysisfeatureprop_id_seq'

=head2 analysisfeature_id

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
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "analysisfeatureprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "analysisfeatureprop_analysisfeatureprop_id_seq",
  },
  "analysisfeature_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("analysisfeatureprop_id");
__PACKAGE__->add_unique_constraint(
  "analysisfeature_id_type_id_rank",
  ["analysisfeature_id", "type_id", "rank"],
);

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

=head2 analysisfeature

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Companalysis::Analysisfeature>

=cut

__PACKAGE__->belongs_to(
  "analysisfeature",
  "Bio::Chado::Schema::Result::Companalysis::Analysisfeature",
  { analysisfeature_id => "analysisfeature_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZefDx4TA4lpDiQTejlBTFg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
