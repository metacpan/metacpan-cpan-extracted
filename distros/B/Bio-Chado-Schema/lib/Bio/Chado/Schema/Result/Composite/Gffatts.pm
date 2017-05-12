package Bio::Chado::Schema::Result::Composite::Gffatts;
BEGIN {
  $Bio::Chado::Schema::Result::Composite::Gffatts::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Composite::Gffatts::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Composite::Gffatts

=cut

__PACKAGE__->table("gffatts");

=head1 ACCESSORS

=head2 feature_id

  data_type: 'integer'
  is_nullable: 1

=head2 type

  data_type: 'text'
  is_nullable: 1

=head2 attribute

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "feature_id",
  { data_type => "integer", is_nullable => 1 },
  "type",
  { data_type => "text", is_nullable => 1 },
  "attribute",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FhOwMfzcV2VRUtgA79+Ing


# You can replace this text with custom content, and it will be preserved on regeneration
1;
