package DemoAppOtherFeaturesSchema::Result::Twokey;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppOtherFeaturesSchema::Result::Twokey

=cut

__PACKAGE__->table("twokeys");

=head1 ACCESSORS

=head2 artist

  data_type: 'integer'
  is_nullable: 0

=head2 cd

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "artist",
  { data_type => "integer", is_nullable => 0 },
  "cd",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("artist", "cd");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 22:57:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xbXu2l/CiOT6x6P3VY1jlw


__PACKAGE__->has_many(
  'fourkeys_to_twokeys', 'DemoAppOtherFeaturesSchema::Result::FourkeysToTwokey', {
    'foreign.t_artist' => 'self.artist',
    'foreign.t_cd' => 'self.cd',
});

1;
