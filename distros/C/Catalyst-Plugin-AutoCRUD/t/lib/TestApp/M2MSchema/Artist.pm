package TestApp::M2MSchema::Artist;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("artist");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    is_auto_increment => 1,
    is_nullable => 0,
    size => undef,
  },
  "forename",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "surname",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "pseudonym",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "born",
  { data_type => "date", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "artist_albums",
  "TestApp::M2MSchema::ArtistAlbum",
  { "foreign.artist_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_05 @ 2008-09-28 20:13:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fMI8nvStxo5lKrHIgSiZWg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
