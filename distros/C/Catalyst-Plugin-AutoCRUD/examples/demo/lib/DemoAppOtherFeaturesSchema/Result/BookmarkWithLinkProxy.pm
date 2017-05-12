package DemoAppOtherFeaturesSchema::Result::BookmarkWithLinkProxy;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppOtherFeaturesSchema::Result::Bookmark

=cut

__PACKAGE__->table("bookmark_with_link_proxy");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 link

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "link",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 link

Type: belongs_to

Related object: L<DemoAppOtherFeaturesSchema::Result::Link>

=cut

__PACKAGE__->belongs_to(
  "link",
  "DemoAppOtherFeaturesSchema::Result::Link",
  { id => "link" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
    proxy         => 'title',
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 22:57:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2RRMtB1gUlC5r0mYD8DN0g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
