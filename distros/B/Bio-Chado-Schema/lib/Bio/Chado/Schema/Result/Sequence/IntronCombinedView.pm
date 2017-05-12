package Bio::Chado::Schema::Result::Sequence::IntronCombinedView;
BEGIN {
  $Bio::Chado::Schema::Result::Sequence::IntronCombinedView::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Sequence::IntronCombinedView::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Sequence::IntronCombinedView

=cut

__PACKAGE__->table("intron_combined_view");

=head1 ACCESSORS

=head2 exon1_id

  data_type: 'integer'
  is_nullable: 1

=head2 exon2_id

  data_type: 'integer'
  is_nullable: 1

=head2 fmin

  data_type: 'integer'
  is_nullable: 1

=head2 fmax

  data_type: 'integer'
  is_nullable: 1

=head2 strand

  data_type: 'smallint'
  is_nullable: 1

=head2 srcfeature_id

  data_type: 'integer'
  is_nullable: 1

=head2 intron_rank

  data_type: 'integer'
  is_nullable: 1

=head2 transcript_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "exon1_id",
  { data_type => "integer", is_nullable => 1 },
  "exon2_id",
  { data_type => "integer", is_nullable => 1 },
  "fmin",
  { data_type => "integer", is_nullable => 1 },
  "fmax",
  { data_type => "integer", is_nullable => 1 },
  "strand",
  { data_type => "smallint", is_nullable => 1 },
  "srcfeature_id",
  { data_type => "integer", is_nullable => 1 },
  "intron_rank",
  { data_type => "integer", is_nullable => 1 },
  "transcript_id",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:d1Njr8yX2iTl9QBKHEc9XQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
