package DemoAppMusicSchema::Result::Artist;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppMusicSchema::Result::Artist

=cut

__PACKAGE__->table("artist");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 forename

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 surname

  data_type: 'varchar'
  is_nullable: 0
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
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "forename",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "surname",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "pseudonym",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "born",
  { data_type => "date", is_nullable => 1 },
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
  { "foreign.artist_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 18:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/cC4ho3u/1FpNRWfIFUSPA


sub display_name {
    my $row = shift;
    return join ' ', $row->forename, $row->surname;
}

1;
