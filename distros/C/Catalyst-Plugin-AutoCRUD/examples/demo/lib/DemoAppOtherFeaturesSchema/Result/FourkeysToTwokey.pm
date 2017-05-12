package DemoAppOtherFeaturesSchema::Result::FourkeysToTwokey;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppOtherFeaturesSchema::Result::FourkeysToTwokey

=cut

__PACKAGE__->table("fourkeys_to_twokeys");

=head1 ACCESSORS

=head2 f_foo

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 f_bar

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 f_hello

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 f_goodbye

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 t_artist

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 t_cd

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 autopilot

  data_type: 'character'
  is_nullable: 0

=head2 pilot_sequence

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "f_foo",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "f_bar",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "f_hello",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "f_goodbye",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "t_artist",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "t_cd",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "autopilot",
  { data_type => "character", is_nullable => 0 },
  "pilot_sequence",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("f_foo", "f_bar", "f_hello", "f_goodbye", "t_artist", "t_cd");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 22:57:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qi6zW2fZquB5cvXXpyxs2A


__PACKAGE__->belongs_to('fourkeys', 'DemoAppOtherFeaturesSchema::Result::Fourkey', {
  'foreign.foo' => 'self.f_foo',
  'foreign.bar' => 'self.f_bar',
  'foreign.hello' => 'self.f_hello',
  'foreign.goodbye' => 'self.f_goodbye',
});

__PACKAGE__->belongs_to('twokeys', 'DemoAppOtherFeaturesSchema::Result::Twokey', {
  'foreign.artist' => 'self.t_artist',
  'foreign.cd' => 'self.t_cd',
});

1;
