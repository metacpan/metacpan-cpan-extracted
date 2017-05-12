package Bio::Chado::Schema::Result::Genetic::PhenotypeComparison;
BEGIN {
  $Bio::Chado::Schema::Result::Genetic::PhenotypeComparison::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Genetic::PhenotypeComparison::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Genetic::PhenotypeComparison

=head1 DESCRIPTION

Comparison of phenotypes e.g., genotype1/environment1/phenotype1 "non-suppressible" with respect to genotype2/environment2/phenotype2.

=cut

__PACKAGE__->table("phenotype_comparison");

=head1 ACCESSORS

=head2 phenotype_comparison_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenotype_comparison_phenotype_comparison_id_seq'

=head2 genotype1_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 environment1_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 genotype2_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 environment2_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 phenotype1_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 phenotype2_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 organism_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "phenotype_comparison_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenotype_comparison_phenotype_comparison_id_seq",
  },
  "genotype1_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "environment1_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "genotype2_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "environment2_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "phenotype1_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "phenotype2_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "organism_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("phenotype_comparison_id");
__PACKAGE__->add_unique_constraint(
  "phenotype_comparison_c1",
  [
    "genotype1_id",
    "environment1_id",
    "genotype2_id",
    "environment2_id",
    "phenotype1_id",
    "pub_id",
  ],
);

=head1 RELATIONS

=head2 environment2

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Genetic::Environment>

=cut

__PACKAGE__->belongs_to(
  "environment2",
  "Bio::Chado::Schema::Result::Genetic::Environment",
  { environment_id => "environment2_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 genotype1

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Genetic::Genotype>

=cut

__PACKAGE__->belongs_to(
  "genotype1",
  "Bio::Chado::Schema::Result::Genetic::Genotype",
  { genotype_id => "genotype1_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 phenotype1

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Phenotype::Phenotype>

=cut

__PACKAGE__->belongs_to(
  "phenotype1",
  "Bio::Chado::Schema::Result::Phenotype::Phenotype",
  { phenotype_id => "phenotype1_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 environment1

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Genetic::Environment>

=cut

__PACKAGE__->belongs_to(
  "environment1",
  "Bio::Chado::Schema::Result::Genetic::Environment",
  { environment_id => "environment1_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 phenotype2

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Phenotype::Phenotype>

=cut

__PACKAGE__->belongs_to(
  "phenotype2",
  "Bio::Chado::Schema::Result::Phenotype::Phenotype",
  { phenotype_id => "phenotype2_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 organism

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Organism::Organism>

=cut

__PACKAGE__->belongs_to(
  "organism",
  "Bio::Chado::Schema::Result::Organism::Organism",
  { organism_id => "organism_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 genotype2

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Genetic::Genotype>

=cut

__PACKAGE__->belongs_to(
  "genotype2",
  "Bio::Chado::Schema::Result::Genetic::Genotype",
  { genotype_id => "genotype2_id" },
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

=head2 phenotype_comparison_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::PhenotypeComparisonCvterm>

=cut

__PACKAGE__->has_many(
  "phenotype_comparison_cvterms",
  "Bio::Chado::Schema::Result::Genetic::PhenotypeComparisonCvterm",
  {
    "foreign.phenotype_comparison_id" => "self.phenotype_comparison_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:euaz4GjE5GnXPi2DVp5DtA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
