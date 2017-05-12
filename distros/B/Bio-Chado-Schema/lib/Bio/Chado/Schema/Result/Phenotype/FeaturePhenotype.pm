package Bio::Chado::Schema::Result::Phenotype::FeaturePhenotype;
BEGIN {
  $Bio::Chado::Schema::Result::Phenotype::FeaturePhenotype::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Phenotype::FeaturePhenotype::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Phenotype::FeaturePhenotype

=cut

__PACKAGE__->table("feature_phenotype");

=head1 ACCESSORS

=head2 feature_phenotype_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'feature_phenotype_feature_phenotype_id_seq'

=head2 feature_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 phenotype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "feature_phenotype_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "feature_phenotype_feature_phenotype_id_seq",
  },
  "feature_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "phenotype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("feature_phenotype_id");
__PACKAGE__->add_unique_constraint("feature_phenotype_c1", ["feature_id", "phenotype_id"]);

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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XBgUUH3vXS5RRgLHCEnYKA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
