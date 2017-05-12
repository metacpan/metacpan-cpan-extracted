package Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentGenotype;
BEGIN {
  $Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentGenotype::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentGenotype::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentGenotype

=head1 DESCRIPTION

Linking table: experiments to the genotypes they produce. There is a one-to-one relationship between an experiment and a genotype since each genotype record should point to one experiment. Add a new experiment_id for each genotype record.

=cut

__PACKAGE__->table("nd_experiment_genotype");

=head1 ACCESSORS

=head2 nd_experiment_genotype_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_experiment_genotype_nd_experiment_genotype_id_seq'

=head2 nd_experiment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 genotype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nd_experiment_genotype_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_experiment_genotype_nd_experiment_genotype_id_seq",
  },
  "nd_experiment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "genotype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("nd_experiment_genotype_id");
__PACKAGE__->add_unique_constraint(
  "nd_experiment_genotype_c1",
  ["nd_experiment_id", "genotype_id"],
);

=head1 RELATIONS

=head2 nd_experiment

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperiment>

=cut

__PACKAGE__->belongs_to(
  "nd_experiment",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperiment",
  { nd_experiment_id => "nd_experiment_id" },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2fxA/XdhyBQDLxE4mosPwQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
