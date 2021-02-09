use utf8;
package # hide from PAUSE
    CDTest::Schema::Result::CDArtwork;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDTest::Schema::Result::CDArtwork

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cd_artwork>

=cut

__PACKAGE__->table("cd_artwork");

=head1 ACCESSORS

=head2 cd_id

  data_type: 'integer'
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cd_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_foreign_key    => 1,
    is_nullable       => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</cd_id>

=back

=cut

__PACKAGE__->set_primary_key("cd_id");

=head1 RELATIONS

=head2 artwork_to_artists

Type: has_many

Related object: L<CDTest::Schema::Result::ArtworkToArtist>

=cut

__PACKAGE__->has_many(
  "artwork_to_artists",
  "CDTest::Schema::Result::ArtworkToArtist",
  { "foreign.artwork_cd_id" => "self.cd_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cd

Type: belongs_to

Related object: L<CDTest::Schema::Result::CD>

=cut

__PACKAGE__->belongs_to(
  "cd",
  "CDTest::Schema::Result::CD",
  { cdid => "cd_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 images

Type: has_many

Related object: L<CDTest::Schema::Result::Image>

=cut

__PACKAGE__->has_many(
  "images",
  "CDTest::Schema::Result::Image",
  { "foreign.artwork_id" => "self.cd_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 artists

Type: many_to_many

Composing rels: L</artwork_to_artists> -> artist

=cut

__PACKAGE__->many_to_many("artists", "artwork_to_artists", "artist");


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:D3G3h66+MGbM0Hx3L1qRQA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
