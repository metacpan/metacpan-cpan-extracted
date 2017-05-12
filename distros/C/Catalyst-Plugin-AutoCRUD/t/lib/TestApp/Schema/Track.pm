package TestApp::Schema::Track;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("track");
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
  "length",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "album_id",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0, size => undef },
  "copyright_id",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0, size => undef },
  "sales",
  { data_type => "int", size => undef },
  "releasedate",
  { data_type => "date", is_nullable => 1, size => undef },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "parent_album" =>
  "TestApp::Schema::Album",
  { id => "album_id" }
);
__PACKAGE__->belongs_to(
  "copyright_id" =>
  "TestApp::Schema::Copyright",
  { id => "copyright_id" },
  { join_type => 'left' },
);


# Created by DBIx::Class::Schema::Loader v0.04999_05 @ 2008-08-03 20:38:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HVsAA+zaErkTkn0TAzd7qw

sub display_name {
     my $self = shift;
     return $self->title || '';
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
