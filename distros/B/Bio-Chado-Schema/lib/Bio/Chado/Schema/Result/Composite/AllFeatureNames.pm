package Bio::Chado::Schema::Result::Composite::AllFeatureNames;
BEGIN {
  $Bio::Chado::Schema::Result::Composite::AllFeatureNames::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Composite::AllFeatureNames::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Composite::AllFeatureNames

=cut

__PACKAGE__->table("all_feature_names");

=head1 ACCESSORS

=head2 feature_id

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 organism_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "feature_id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "organism_id",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+LtyxBf83iW9yyQtvUXgiQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
