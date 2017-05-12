package Bio::Chado::Schema::Result::Phenotype::Phenotypeprop;
BEGIN {
  $Bio::Chado::Schema::Result::Phenotype::Phenotypeprop::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Phenotype::Phenotypeprop::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Phenotype::Phenotypeprop

=head1 DESCRIPTION

A phenotype can have any number of
slot-value property tags attached to it. This is an alternative to
hardcoding a list of columns in the relational schema, and is
completely extensible. There is a unique constraint, phenotypeprop_c1, for
the combination of phenotype_id, rank, and type_id. Multivalued property-value pairs must be differentiated by rank.

=cut

__PACKAGE__->table("phenotypeprop");

=head1 ACCESSORS

=head2 phenotypeprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenotypeprop_phenotypeprop_id_seq'

=head2 phenotype_id

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
  "phenotypeprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenotypeprop_phenotypeprop_id_seq",
  },
  "phenotype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("phenotypeprop_id");
__PACKAGE__->add_unique_constraint("phenotypeprop_c1", ["phenotype_id", "type_id", "rank"]);

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

=head2 phenotype

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Phenotype::Phenotype>

=cut

__PACKAGE__->belongs_to(
  "phenotype",
  "Bio::Chado::Schema::Result::Phenotype::Phenotype",
  { phenotype_id => "phenotype_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-07 13:19:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NDHb+iWsyTXU8gPq4qaqLw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
