package TestApp::Schema::SleeveNotes;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("sleeve_notes");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    is_auto_increment => 1,
    is_nullable => 0,
    size => undef,
  },
  "text",
  { data_type => "varchar", is_nullable => 0, size => 255, accessor => 'custom_text' },
  "album_id",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to("album_id", "TestApp::Schema::Album", { "foreign.id" => "self.album_id" });
__PACKAGE__->add_unique_constraint(['album_id']);

# Created by DBIx::Class::Schema::Loader v0.04999_05 @ 2008-08-03 20:38:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KHS2SrT7ZnxECLzSP58k3Q

# a fake releation which goes nowhere - to test the dangling rel code
__PACKAGE__->has_many(
    'nonexistent_things',
    'Nonexistent::Schema::Noggin',
    { "foreign.id" => 'self.noggin_id' },
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
