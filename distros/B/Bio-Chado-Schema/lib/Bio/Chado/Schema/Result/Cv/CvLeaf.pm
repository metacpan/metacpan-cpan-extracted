package Bio::Chado::Schema::Result::Cv::CvLeaf;
BEGIN {
  $Bio::Chado::Schema::Result::Cv::CvLeaf::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Cv::CvLeaf::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Cv::CvLeaf

=head1 DESCRIPTION

the leaves of a cv are the set of terms
which have no children (terms that are not the object of a
relation). All cvs will have at least 1 leaf

=cut

__PACKAGE__->table("cv_leaf");

=head1 ACCESSORS

=head2 cv_id

  data_type: 'integer'
  is_nullable: 1

=head2 cvterm_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cv_id",
  { data_type => "integer", is_nullable => 1 },
  "cvterm_id",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9ZC3mPTVFGKpMtwF5gkx7A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
