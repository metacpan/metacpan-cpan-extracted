package Bio::Chado::Schema::Result::Cv::StatsPathsToRoot;
BEGIN {
  $Bio::Chado::Schema::Result::Cv::StatsPathsToRoot::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Cv::StatsPathsToRoot::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Cv::StatsPathsToRoot

=head1 DESCRIPTION

per-cvterm statistics on its
placement in the DAG relative to the root. There may be multiple paths
from any term to the root. This gives the total number of paths, and
the average minimum and maximum distances. Here distance is defined by
cvtermpath.pathdistance

=cut

__PACKAGE__->table("stats_paths_to_root");

=head1 ACCESSORS

=head2 cvterm_id

  data_type: 'integer'
  is_nullable: 1

=head2 total_paths

  data_type: 'bigint'
  is_nullable: 1

=head2 avg_distance

  data_type: 'numeric'
  is_nullable: 1

=head2 min_distance

  data_type: 'integer'
  is_nullable: 1

=head2 max_distance

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cvterm_id",
  { data_type => "integer", is_nullable => 1 },
  "total_paths",
  { data_type => "bigint", is_nullable => 1 },
  "avg_distance",
  { data_type => "numeric", is_nullable => 1 },
  "min_distance",
  { data_type => "integer", is_nullable => 1 },
  "max_distance",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fSYGZt0z2S/O8jRP/WecZQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
