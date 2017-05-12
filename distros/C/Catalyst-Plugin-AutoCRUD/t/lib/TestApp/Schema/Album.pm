package TestApp::Schema::Album;

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
  { data_type => "varchar", is_nullable => 0, size => 255, accessor => 'custom_title' },
  "recorded",
  { data_type => "date", is_nullable => 0, size => undef },
  "deleted",
  { data_type => "boolean", is_nullable => 0, size => undef },
  "artist_id",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to("artist_id", "TestApp::Schema::Artist", { id => "artist_id" });
__PACKAGE__->might_have("sleeve_notes", "TestApp::Schema::SleeveNotes", { 'foreign.album_id' => 'self.id' });
__PACKAGE__->has_many(
  "tracks",
  "TestApp::Schema::Track",
  { "foreign.album_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_05 @ 2008-08-03 20:38:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KHS2SrT7ZnxECLzSP58k3Q

sub display_name {
     my $self = shift;
     return $self->custom_title || '';
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
