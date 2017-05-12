package Bio::Chado::Schema::Result::Cv::CvPathCount;
BEGIN {
  $Bio::Chado::Schema::Result::Cv::CvPathCount::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Cv::CvPathCount::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Cv::CvPathCount

=head1 DESCRIPTION

per-cv summary of number of
paths (cvtermpaths) broken down by relationship_type. num_paths is the
total # of paths of the specified type in which the subject_id of the
path is in the named cv. See also: cv_distinct_relations

=cut

__PACKAGE__->table("cv_path_count");

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

=head2 num_paths

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
  "num_paths",
  { data_type => "bigint", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TPlEH4vL0GI5Yb0miKxS4Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
