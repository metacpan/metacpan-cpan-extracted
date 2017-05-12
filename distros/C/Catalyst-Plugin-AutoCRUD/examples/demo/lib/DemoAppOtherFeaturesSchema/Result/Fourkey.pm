package DemoAppOtherFeaturesSchema::Result::Fourkey;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppOtherFeaturesSchema::Result::Fourkey

=cut

__PACKAGE__->table("fourkeys");

=head1 ACCESSORS

=head2 foo

  data_type: 'integer'
  is_nullable: 0

=head2 bar

  data_type: 'integer'
  is_nullable: 0

=head2 hello

  data_type: 'integer'
  is_nullable: 0

=head2 goodbye

  data_type: 'integer'
  is_nullable: 0

=head2 sensors

  data_type: 'character'
  is_nullable: 0
  size: 10

=head2 read_count

  data_type: 'int'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "foo",
  { data_type => "integer", is_nullable => 0 },
  "bar",
  { data_type => "integer", is_nullable => 0 },
  "hello",
  { data_type => "integer", is_nullable => 0 },
  "goodbye",
  { data_type => "integer", is_nullable => 0 },
  "sensors",
  { data_type => "character", is_nullable => 0, size => 10 },
  "read_count",
  { data_type => "int", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("foo", "bar", "hello", "goodbye");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 22:57:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:02/pDDvFiK+be/hV7NQt9A


__PACKAGE__->has_many(
  'fourkeys_to_twokeys', 'DemoAppOtherFeaturesSchema::Result::FourkeysToTwokey', {
    'foreign.f_foo' => 'self.foo',
    'foreign.f_bar' => 'self.bar',
    'foreign.f_hello' => 'self.hello',
    'foreign.f_goodbye' => 'self.goodbye',
});

1;
