package Bio::Chado::Schema::Result::Genetic::Environment;
BEGIN {
  $Bio::Chado::Schema::Result::Genetic::Environment::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Genetic::Environment::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Genetic::Environment - The environmental component of a phenotype description.

=cut

__PACKAGE__->table("environment");

=head1 ACCESSORS

=head2 environment_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'environment_environment_id_seq'

=head2 uniquename

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "environment_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "environment_environment_id_seq",
  },
  "uniquename",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("environment_id");
__PACKAGE__->add_unique_constraint("environment_c1", ["uniquename"]);

=head1 RELATIONS

=head2 environment_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::EnvironmentCvterm>

=cut

__PACKAGE__->has_many(
  "environment_cvterms",
  "Bio::Chado::Schema::Result::Genetic::EnvironmentCvterm",
  { "foreign.environment_id" => "self.environment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phendescs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::Phendesc>

=cut

__PACKAGE__->has_many(
  "phendescs",
  "Bio::Chado::Schema::Result::Genetic::Phendesc",
  { "foreign.environment_id" => "self.environment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_comparison_environment2s

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::PhenotypeComparison>

=cut

__PACKAGE__->has_many(
  "phenotype_comparison_environment2s",
  "Bio::Chado::Schema::Result::Genetic::PhenotypeComparison",
  { "foreign.environment2_id" => "self.environment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_comparison_environment1s

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::PhenotypeComparison>

=cut

__PACKAGE__->has_many(
  "phenotype_comparison_environment1s",
  "Bio::Chado::Schema::Result::Genetic::PhenotypeComparison",
  { "foreign.environment1_id" => "self.environment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenstatements

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::Phenstatement>

=cut

__PACKAGE__->has_many(
  "phenstatements",
  "Bio::Chado::Schema::Result::Genetic::Phenstatement",
  { "foreign.environment_id" => "self.environment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cQ92ZxqRaNYVs+kOW/RmSg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
