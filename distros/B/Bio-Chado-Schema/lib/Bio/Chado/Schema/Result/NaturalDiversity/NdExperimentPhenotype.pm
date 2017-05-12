package Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentPhenotype;
BEGIN {
  $Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentPhenotype::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentPhenotype::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentPhenotype

=head1 DESCRIPTION

Linking table: experiments to the phenotypes they produce. There is a one-to-one relationship between an experiment and a phenotype since each phenotype record should point to one experiment. Add a new experiment_id for each phenotype record.

=cut

__PACKAGE__->table("nd_experiment_phenotype");

=head1 ACCESSORS

=head2 nd_experiment_phenotype_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_experiment_phenotype_nd_experiment_phenotype_id_seq'

=head2 nd_experiment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 phenotype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nd_experiment_phenotype_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_experiment_phenotype_nd_experiment_phenotype_id_seq",
  },
  "nd_experiment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "phenotype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("nd_experiment_phenotype_id");
__PACKAGE__->add_unique_constraint(
  "nd_experiment_phenotype_c1",
  ["nd_experiment_id", "phenotype_id"],
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/qqjm+693ZbJfe7mbEX6fQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
