use utf8;
package # hide from PAUSE
    CDTest::Schema::Result::ArtworkToArtist;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDTest::Schema::Result::ArtworkToArtist

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<artwork_to_artist>

=cut

__PACKAGE__->table("artwork_to_artist");

=head1 ACCESSORS

=head2 artwork_cd_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 artist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "artwork_cd_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "artist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</artwork_cd_id>

=item * L</artist_id>

=back

=cut

__PACKAGE__->set_primary_key("artwork_cd_id", "artist_id");

=head1 RELATIONS

=head2 artist

Type: belongs_to

Related object: L<CDTest::Schema::Result::Artist>

=cut

__PACKAGE__->belongs_to(
  "artist",
  "CDTest::Schema::Result::Artist",
  { artistid => "artist_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 artwork_cd

Type: belongs_to

Related object: L<CDTest::Schema::Result::CDArtwork>

=cut

__PACKAGE__->belongs_to(
  "artwork_cd",
  "CDTest::Schema::Result::CDArtwork",
  { cd_id => "artwork_cd_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Lf8595ObR/F3ZTNseh1wnw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
