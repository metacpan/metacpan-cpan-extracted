package DemoAppOtherFeaturesSchema::Result::Link;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppOtherFeaturesSchema::Result::Link

=cut

__PACKAGE__->table("link");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 url

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 title

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "url",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 bookmarks

Type: has_many

Related object: L<DemoAppOtherFeaturesSchema::Result::Bookmark>

=cut

__PACKAGE__->has_many(
  "bookmarks",
  "DemoAppOtherFeaturesSchema::Result::Bookmark",
  { "foreign.link" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 22:57:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fTj7wkc3cVkTC5JFlHFOtA


use overload '""' => sub { shift->url }, fallback=> 1;

1;
