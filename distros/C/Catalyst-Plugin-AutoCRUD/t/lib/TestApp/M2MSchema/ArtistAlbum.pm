package TestApp::M2MSchema::ArtistAlbum;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("artist_album");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    is_auto_increment => 1,
    is_nullable => 0,
    size => undef,
  },
  "artist_id",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0, size => undef },
  "album_id",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "artist_id",
  "TestApp::M2MSchema::Artist",
  { id => "artist_id" },
);
__PACKAGE__->belongs_to("album_id", "TestApp::M2MSchema::Album", { id => "album_id" });


# Created by DBIx::Class::Schema::Loader v0.04999_05 @ 2008-09-28 20:13:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2LzcMFts6ArIRTdzyDf8Iw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
