package TestApp::M2MSchema::Album;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("album");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    is_auto_increment => 1,
    is_nullable => 0,
    size => undef,
  },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "recorded",
  { data_type => "date", is_nullable => 0, size => undef },
  "deleted",
  { data_type => "boolean", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "artist_albums",
  "TestApp::M2MSchema::ArtistAlbum",
  { "foreign.album_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_05 @ 2008-09-28 20:13:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:87gk1eOBuVWT8P2sRgX+vQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
