package Bio::Chado::Schema::Result::Cv::CommonAncestorCvterm;
BEGIN {
  $Bio::Chado::Schema::Result::Cv::CommonAncestorCvterm::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Cv::CommonAncestorCvterm::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Cv::CommonAncestorCvterm

=head1 DESCRIPTION

The common ancestor of any
two terms is the intersection of both terms ancestors. Two terms can
have multiple common ancestors. Use total_pathdistance to get the
least common ancestor

=cut

__PACKAGE__->table("common_ancestor_cvterm");

=head1 ACCESSORS

=head2 cvterm1_id

  data_type: 'integer'
  is_nullable: 1

=head2 cvterm2_id

  data_type: 'integer'
  is_nullable: 1

=head2 ancestor_cvterm_id

  data_type: 'integer'
  is_nullable: 1

=head2 pathdistance1

  data_type: 'integer'
  is_nullable: 1

=head2 pathdistance2

  data_type: 'integer'
  is_nullable: 1

=head2 total_pathdistance

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cvterm1_id",
  { data_type => "integer", is_nullable => 1 },
  "cvterm2_id",
  { data_type => "integer", is_nullable => 1 },
  "ancestor_cvterm_id",
  { data_type => "integer", is_nullable => 1 },
  "pathdistance1",
  { data_type => "integer", is_nullable => 1 },
  "pathdistance2",
  { data_type => "integer", is_nullable => 1 },
  "total_pathdistance",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:I/RmAnp5GzYYhc0N7zoRMA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
