package Business::Cart::Generic::Schema::Result::ProductsToCategory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::ProductsToCategory

=cut

__PACKAGE__->table("products_to_categories");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'products_to_categories_id_seq'

=head2 category_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "products_to_categories_id_seq",
  },
  "category_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 product

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Product>

=cut

__PACKAGE__->belongs_to(
  "product",
  "Business::Cart::Generic::Schema::Result::Product",
  { id => "product_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 category

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Category>

=cut

__PACKAGE__->belongs_to(
  "category",
  "Business::Cart::Generic::Schema::Result::Category",
  { id => "category_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DgRh5w1YST8NPXioOGQQKw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
