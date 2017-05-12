package Bio::Chado::Schema::Result::Genetic::Phenstatement;
BEGIN {
  $Bio::Chado::Schema::Result::Genetic::Phenstatement::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Genetic::Phenstatement::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Genetic::Phenstatement

=head1 DESCRIPTION

Phenotypes are things like "larval lethal".  Phenstatements are things like "dpp-1 is recessive larval lethal". So essentially phenstatement is a linking table expressing the relationship between genotype, environment, and phenotype.

=cut

__PACKAGE__->table("phenstatement");

=head1 ACCESSORS

=head2 phenstatement_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenstatement_phenstatement_id_seq'

=head2 genotype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 environment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 phenotype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "phenstatement_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenstatement_phenstatement_id_seq",
  },
  "genotype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "environment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "phenotype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("phenstatement_id");
__PACKAGE__->add_unique_constraint(
  "phenstatement_c1",
  [
    "genotype_id",
    "phenotype_id",
    "environment_id",
    "type_id",
    "pub_id",
  ],
);

=head1 RELATIONS

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

=head2 environment

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Genetic::Environment>

=cut

__PACKAGE__->belongs_to(
  "environment",
  "Bio::Chado::Schema::Result::Genetic::Environment",
  { environment_id => "environment_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
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

=head2 pub

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Pub::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "Bio::Chado::Schema::Result::Pub::Pub",
  { pub_id => "pub_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 genotype

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Genetic::Genotype>

=cut

__PACKAGE__->belongs_to(
  "genotype",
  "Bio::Chado::Schema::Result::Genetic::Genotype",
  { genotype_id => "genotype_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IU5IGB7RlGdeWYK5m8QKgA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
