package DemoAppMusicSchema::Result::AlbumArtist;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppMusicSchema::Result::AlbumArtist

=cut

__PACKAGE__->table("album_artist");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 album_id

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 0

=head2 artist_id

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "album_id",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0 },
  "artist_id",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 artist

Type: belongs_to

Related object: L<DemoAppMusicSchema::Result::Artist>

=cut

__PACKAGE__->belongs_to(
  "artist",
  "DemoAppMusicSchema::Result::Artist",
  { id => "artist_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 album

Type: belongs_to

Related object: L<DemoAppMusicSchema::Result::Album>

=cut

__PACKAGE__->belongs_to(
  "album",
  "DemoAppMusicSchema::Result::Album",
  { id => "album_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 18:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ux7pQnUXyOB2FiZh5WT7aQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
