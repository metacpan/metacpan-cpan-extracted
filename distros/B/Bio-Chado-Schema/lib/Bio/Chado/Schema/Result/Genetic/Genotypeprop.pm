package Bio::Chado::Schema::Result::Genetic::Genotypeprop;
BEGIN {
  $Bio::Chado::Schema::Result::Genetic::Genotypeprop::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Genetic::Genotypeprop::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Genetic::Genotypeprop

=cut

__PACKAGE__->table("genotypeprop");

=head1 ACCESSORS

=head2 genotypeprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'genotypeprop_genotypeprop_id_seq'

=head2 genotype_id

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
  "genotypeprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "genotypeprop_genotypeprop_id_seq",
  },
  "genotype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("genotypeprop_id");
__PACKAGE__->add_unique_constraint("genotypeprop_c1", ["genotype_id", "type_id", "rank"]);

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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-22 08:45:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cPJB/P4r7Oe6ZzCs4KR48w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
