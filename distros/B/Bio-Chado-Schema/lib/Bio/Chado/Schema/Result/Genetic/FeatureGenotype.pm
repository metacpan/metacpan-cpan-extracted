package Bio::Chado::Schema::Result::Genetic::FeatureGenotype;
BEGIN {
  $Bio::Chado::Schema::Result::Genetic::FeatureGenotype::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Genetic::FeatureGenotype::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Genetic::FeatureGenotype

=cut

__PACKAGE__->table("feature_genotype");

=head1 ACCESSORS

=head2 feature_genotype_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'feature_genotype_feature_genotype_id_seq'

=head2 feature_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 genotype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 chromosome_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

A feature of SO type "chromosome".

=head2 rank

  data_type: 'integer'
  is_nullable: 0

rank can be used for
n-ploid organisms or to preserve order.

=head2 cgroup

  data_type: 'integer'
  is_nullable: 0

Spatially distinguishable
group. group can be used for distinguishing the chromosomal groups,
for example (RNAi products and so on can be treated as different
groups, as they do not fall on a particular chromosome).

=head2 cvterm_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "feature_genotype_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "feature_genotype_feature_genotype_id_seq",
  },
  "feature_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "genotype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "chromosome_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "rank",
  { data_type => "integer", is_nullable => 0 },
  "cgroup",
  { data_type => "integer", is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("feature_genotype_id");
__PACKAGE__->add_unique_constraint(
  "feature_genotype_c1",
  [
    "feature_id",
    "genotype_id",
    "cvterm_id",
    "chromosome_id",
    "rank",
    "cgroup",
  ],
);

=head1 RELATIONS

=head2 cvterm

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "cvterm",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "cvterm_id" },
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

=head2 feature

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Sequence::Feature>

=cut

__PACKAGE__->belongs_to(
  "feature",
  "Bio::Chado::Schema::Result::Sequence::Feature",
  { feature_id => "feature_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 chromosome

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Sequence::Feature>

=cut

__PACKAGE__->belongs_to(
  "chromosome",
  "Bio::Chado::Schema::Result::Sequence::Feature",
  { feature_id => "chromosome_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gmrMMxo1beaPJKMPPovAmg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
