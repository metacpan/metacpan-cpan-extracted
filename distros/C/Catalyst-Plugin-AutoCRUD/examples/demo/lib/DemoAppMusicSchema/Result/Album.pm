package DemoAppMusicSchema::Result::Album;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppMusicSchema::Result::Album

=cut

__PACKAGE__->table("album");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 recorded

  data_type: 'date'
  is_nullable: 1

=head2 deleted

  data_type: 'boolean'
  default_value: 'false'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "recorded",
  { data_type => "date", is_nullable => 1 },
  "deleted",
  { data_type => "boolean", default_value => "false", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 album_artists

Type: has_many

Related object: L<DemoAppMusicSchema::Result::AlbumArtist>

=cut

__PACKAGE__->has_many(
  "album_artists",
  "DemoAppMusicSchema::Result::AlbumArtist",
  { "foreign.album_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sleeve_note

Type: might_have

Related object: L<DemoAppMusicSchema::Result::SleeveNote>

=cut

__PACKAGE__->might_have(
  "sleeve_note",
  "DemoAppMusicSchema::Result::SleeveNote",
  { "foreign.album_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tracks

Type: has_many

Related object: L<DemoAppMusicSchema::Result::Track>

=cut

__PACKAGE__->has_many(
  "tracks",
  "DemoAppMusicSchema::Result::Track",
  { "foreign.album_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 18:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Wx/g9tUF3BQeBJF1TGW+Ow


sub display_name {
    my $row = shift;
    return $row->title;
}

1;
