package DemoAppOtherFeaturesSchema::Result::PunctuatedColumnName;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppOtherFeaturesSchema::Result::PunctuatedColumnName

=cut

__PACKAGE__->table("punctuated_column_name");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 foo ' bar

  accessor: 'foo_bar'
  data_type: 'integer'
  is_nullable: 1

=head2 bar/baz

  accessor: 'bar_baz'
  data_type: 'integer'
  is_nullable: 1

=head2 baz;quux

  accessor: 'baz_quux'
  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "foo ' bar",
  { accessor => "foo_bar", data_type => "integer", is_nullable => 1 },
  "bar/baz",
  { accessor => "bar_baz", data_type => "integer", is_nullable => 1 },
  "baz;quux",
  { accessor => "baz_quux", data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 22:57:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZS8L35PSkWY1wHGjUSpO/w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
