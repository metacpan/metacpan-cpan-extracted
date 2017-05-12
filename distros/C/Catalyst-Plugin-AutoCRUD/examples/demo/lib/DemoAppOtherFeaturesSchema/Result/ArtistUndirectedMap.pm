package DemoAppOtherFeaturesSchema::Result::ArtistUndirectedMap;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppOtherFeaturesSchema::Result::ArtistUndirectedMap

=cut

__PACKAGE__->table("artist_undirected_map");

=head1 ACCESSORS

=head2 id1

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 id2

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id1",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "id2",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id1", "id2");

=head1 RELATIONS

=head2 id2

Type: belongs_to

Related object: L<DemoAppOtherFeaturesSchema::Result::Artist>

=cut

__PACKAGE__->belongs_to(
  "id2",
  "DemoAppOtherFeaturesSchema::Result::Artist",
  { id => "id2" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 id1

Type: belongs_to

Related object: L<DemoAppOtherFeaturesSchema::Result::Artist>

=cut

__PACKAGE__->belongs_to(
  "id1",
  "DemoAppOtherFeaturesSchema::Result::Artist",
  { id => "id1" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 22:57:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VhZsXie8Ii05u8wJy/1fGA


__PACKAGE__->has_many(
  'mapped_artists', 'DemoAppOtherFeaturesSchema::Result::Artist',
  [ {'foreign.artistid' => 'self.id1'}, {'foreign.artistid' => 'self.id2'} ],
  { cascade_delete => 0 },
);

1;
