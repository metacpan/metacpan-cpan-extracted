package Business::Cart::Generic::Schema::Result::Product;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::Product

=cut

__PACKAGE__->table("products");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'products_id_seq'

=head2 currency_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 manufacturer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 parent_id

  data_type: 'integer'
  is_nullable: 0

=head2 product_status_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 tax_class_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 weight_class_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 date_added

  data_type: 'timestamp'
  is_nullable: 0

=head2 date_modified

  data_type: 'timestamp'
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 has_children

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 model

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 price

  data_type: 'numeric'
  is_nullable: 0
  size: [15,4]

=head2 quantity_on_hand

  data_type: 'integer'
  is_nullable: 0

=head2 quantity_ordered

  data_type: 'integer'
  is_nullable: 0

=head2 upper_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 weight

  data_type: 'numeric'
  is_nullable: 0
  size: [5,2]

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "products_id_seq",
  },
  "currency_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "manufacturer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "parent_id",
  { data_type => "integer", is_nullable => 0 },
  "product_status_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "tax_class_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "weight_class_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "date_added",
  { data_type => "timestamp", is_nullable => 0 },
  "date_modified",
  { data_type => "timestamp", is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "has_children",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "model",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "price",
  { data_type => "numeric", is_nullable => 0, size => [15, 4] },
  "quantity_on_hand",
  { data_type => "integer", is_nullable => 0 },
  "quantity_ordered",
  { data_type => "integer", is_nullable => 0 },
  "upper_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "weight",
  { data_type => "numeric", is_nullable => 0, size => [5, 2] },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 order_items

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::OrderItem>

=cut

__PACKAGE__->has_many(
  "order_items",
  "Business::Cart::Generic::Schema::Result::OrderItem",
  { "foreign.product_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 product_status

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::ProductStatuse>

=cut

__PACKAGE__->belongs_to(
  "product_status",
  "Business::Cart::Generic::Schema::Result::ProductStatuse",
  { id => "product_status_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 manufacturer

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Manufacturer>

=cut

__PACKAGE__->belongs_to(
  "manufacturer",
  "Business::Cart::Generic::Schema::Result::Manufacturer",
  { id => "manufacturer_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 weight_class

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::WeightClass>

=cut

__PACKAGE__->belongs_to(
  "weight_class",
  "Business::Cart::Generic::Schema::Result::WeightClass",
  { id => "weight_class_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 tax_class

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::TaxClass>

=cut

__PACKAGE__->belongs_to(
  "tax_class",
  "Business::Cart::Generic::Schema::Result::TaxClass",
  { id => "tax_class_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 currency

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Currency>

=cut

__PACKAGE__->belongs_to(
  "currency",
  "Business::Cart::Generic::Schema::Result::Currency",
  { id => "currency_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 products_to_categories

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::ProductsToCategory>

=cut

__PACKAGE__->has_many(
  "products_to_categories",
  "Business::Cart::Generic::Schema::Result::ProductsToCategory",
  { "foreign.product_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:y4djsv2ZE66lnkyeHWIQhw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
