package DemoAppOtherFeaturesSchema::Result::Noprimarykey;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppOtherFeaturesSchema::Result::Noprimarykey

=cut

__PACKAGE__->table("noprimarykey");

=head1 ACCESSORS

=head2 foo

  data_type: 'integer'
  is_nullable: 0

=head2 bar

  data_type: 'integer'
  is_nullable: 0

=head2 baz

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "foo",
  { data_type => "integer", is_nullable => 0 },
  "bar",
  { data_type => "integer", is_nullable => 0 },
  "baz",
  { data_type => "integer", is_nullable => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 22:57:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5b1JCK+PdvIRVm6Ia/qALw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
