package Business::Cart::Generic::Schema::Result::OrderItem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::OrderItem

=cut

__PACKAGE__->table("order_items");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'order_items_id_seq'

=head2 order_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

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

=head2 quantity

  data_type: 'integer'
  is_nullable: 0

=head2 tax_rate

  data_type: 'numeric'
  is_nullable: 1
  size: [7,4]

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
    sequence          => "order_items_id_seq",
  },
  "order_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "model",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "price",
  { data_type => "numeric", is_nullable => 0, size => [15, 4] },
  "quantity",
  { data_type => "integer", is_nullable => 0 },
  "tax_rate",
  { data_type => "numeric", is_nullable => 1, size => [7, 4] },
  "upper_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
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

=head2 order

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Order>

=cut

__PACKAGE__->belongs_to(
  "order",
  "Business::Cart::Generic::Schema::Result::Order",
  { id => "order_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JD6ObIE78s8n+bAFJt+gkA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
