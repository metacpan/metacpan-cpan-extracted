package Business::Cart::Generic::Schema::Result::Category;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::Category

=cut

__PACKAGE__->table("categories");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'categories_id_seq'

=head2 parent_id

  data_type: 'integer'
  is_nullable: 0

=head2 date_added

  data_type: 'timestamp'
  is_nullable: 0

=head2 date_modified

  data_type: 'timestamp'
  is_nullable: 0

=head2 image

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 sort_order

  data_type: 'integer'
  is_nullable: 0

=head2 upper_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "categories_id_seq",
  },
  "parent_id",
  { data_type => "integer", is_nullable => 0 },
  "date_added",
  { data_type => "timestamp", is_nullable => 0 },
  "date_modified",
  { data_type => "timestamp", is_nullable => 0 },
  "image",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "sort_order",
  { data_type => "integer", is_nullable => 0 },
  "upper_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 category_descriptions

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::CategoryDescription>

=cut

__PACKAGE__->has_many(
  "category_descriptions",
  "Business::Cart::Generic::Schema::Result::CategoryDescription",
  { "foreign.category_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 products_to_categories

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::ProductsToCategory>

=cut

__PACKAGE__->has_many(
  "products_to_categories",
  "Business::Cart::Generic::Schema::Result::ProductsToCategory",
  { "foreign.category_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wYPbDyD6TYFkzTfmL8Fg2w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
