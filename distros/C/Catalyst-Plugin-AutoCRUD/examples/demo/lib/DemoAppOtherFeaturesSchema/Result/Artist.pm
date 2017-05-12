package DemoAppOtherFeaturesSchema::Result::Artist;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppOtherFeaturesSchema::Result::Artist

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
  { data_type => "varchar", is_nullable => 1, size => 255, accessor => 'alias' },
  "born",
  { data_type => "date", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 22:57:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mp93WyFXfmIn3pMlS2v9Og


__PACKAGE__->has_many(
  artist_undirected_maps =>
      "DemoAppOtherFeaturesSchema::Result::ArtistUndirectedMap",
  [ {'foreign.id1' => 'self.artistid'}, {'foreign.id2' => 'self.artistid'} ],
  { cascade_copy => 0 } # this would *so* not make sense
);

1;
