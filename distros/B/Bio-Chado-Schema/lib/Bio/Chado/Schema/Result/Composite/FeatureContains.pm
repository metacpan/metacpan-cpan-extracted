package Bio::Chado::Schema::Result::Composite::FeatureContains;
BEGIN {
  $Bio::Chado::Schema::Result::Composite::FeatureContains::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Composite::FeatureContains::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Composite::FeatureContains

=head1 DESCRIPTION

subject intervals contains (or is
same as) object interval. transitive,reflexive

=cut

__PACKAGE__->table("feature_contains");

=head1 ACCESSORS

=head2 subject_id

  data_type: 'integer'
  is_nullable: 1

=head2 object_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "subject_id",
  { data_type => "integer", is_nullable => 1 },
  "object_id",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uy6t8UinCMDI6QI5ejVGFA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
