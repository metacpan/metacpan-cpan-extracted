package Bio::Chado::Schema::Result::Cv::CvLinkCount;
BEGIN {
  $Bio::Chado::Schema::Result::Cv::CvLinkCount::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Cv::CvLinkCount::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Cv::CvLinkCount

=head1 DESCRIPTION

per-cv summary of number of
links (cvterm_relationships) broken down by
relationship_type. num_links is the total # of links of the specified
type in which the subject_id of the link is in the named cv

=cut

__PACKAGE__->table("cv_link_count");

=head1 ACCESSORS

=head2 cv_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 relation_name

  data_type: 'varchar'
  is_nullable: 1
  size: 1024

=head2 relation_cv_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 num_links

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cv_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "relation_name",
  { data_type => "varchar", is_nullable => 1, size => 1024 },
  "relation_cv_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "num_links",
  { data_type => "bigint", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6f8rJ5IMu723zbTPJt0JdQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
