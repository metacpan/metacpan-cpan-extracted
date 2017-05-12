package DemoAppOtherFeaturesSchema::Result::ArtistsCalledMike;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppOtherFeaturesSchema::Result::ArtistsCalledMike

=cut

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table("artists_called_mike");
__PACKAGE__->result_source_instance->view_definition(
  "SELECT * FROM artist WHERE forename ='Mike'"
);

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 1

=head2 forename

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 surname

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pseudonym

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 born

  data_type: 'date'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 1 },
  "forename",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "surname",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pseudonym",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "born",
  { data_type => "date", is_nullable => 1 },
);

__PACKAGE__->set_primary_key('id');


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 22:57:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YuPFnJoO2uc5E50RJPNKUA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
