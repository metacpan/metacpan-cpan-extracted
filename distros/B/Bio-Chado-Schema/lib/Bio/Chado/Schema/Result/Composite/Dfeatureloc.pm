package Bio::Chado::Schema::Result::Composite::Dfeatureloc;
BEGIN {
  $Bio::Chado::Schema::Result::Composite::Dfeatureloc::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Composite::Dfeatureloc::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Composite::Dfeatureloc

=cut

__PACKAGE__->table("dfeatureloc");

=head1 ACCESSORS

=head2 featureloc_id

  data_type: 'integer'
  is_nullable: 1

=head2 feature_id

  data_type: 'integer'
  is_nullable: 1

=head2 srcfeature_id

  data_type: 'integer'
  is_nullable: 1

=head2 nbeg

  data_type: 'integer'
  is_nullable: 1

=head2 is_nbeg_partial

  data_type: 'boolean'
  is_nullable: 1

=head2 nend

  data_type: 'integer'
  is_nullable: 1

=head2 is_nend_partial

  data_type: 'boolean'
  is_nullable: 1

=head2 strand

  data_type: 'smallint'
  is_nullable: 1

=head2 phase

  data_type: 'integer'
  is_nullable: 1

=head2 residue_info

  data_type: 'text'
  is_nullable: 1

=head2 locgroup

  data_type: 'integer'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "featureloc_id",
  { data_type => "integer", is_nullable => 1 },
  "feature_id",
  { data_type => "integer", is_nullable => 1 },
  "srcfeature_id",
  { data_type => "integer", is_nullable => 1 },
  "nbeg",
  { data_type => "integer", is_nullable => 1 },
  "is_nbeg_partial",
  { data_type => "boolean", is_nullable => 1 },
  "nend",
  { data_type => "integer", is_nullable => 1 },
  "is_nend_partial",
  { data_type => "boolean", is_nullable => 1 },
  "strand",
  { data_type => "smallint", is_nullable => 1 },
  "phase",
  { data_type => "integer", is_nullable => 1 },
  "residue_info",
  { data_type => "text", is_nullable => 1 },
  "locgroup",
  { data_type => "integer", is_nullable => 1 },
  "rank",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DqPOKM/oD300AzeNQouY+w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
