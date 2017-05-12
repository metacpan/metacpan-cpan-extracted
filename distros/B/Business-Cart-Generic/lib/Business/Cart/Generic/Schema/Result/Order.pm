package Business::Cart::Generic::Schema::Result::Order;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::Order

=cut

__PACKAGE__->table("orders");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'orders_id_seq'

=head2 billing_address_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 customer_address_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 customer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 delivery_address_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 date_added

  data_type: 'timestamp'
  is_nullable: 0

=head2 date_completed

  data_type: 'timestamp'
  default_value: '1900-01-01 00:00:00'
  is_nullable: 0

=head2 date_modified

  data_type: 'timestamp'
  is_nullable: 0

=head2 order_status_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 payment_method_id

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
    sequence          => "orders_id_seq",
  },
  "billing_address_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "customer_address_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "customer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "delivery_address_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "date_added",
  { data_type => "timestamp", is_nullable => 0 },
  "date_completed",
  {
    data_type     => "timestamp",
    default_value => "1900-01-01 00:00:00",
    is_nullable   => 0,
  },
  "date_modified",
  { data_type => "timestamp", is_nullable => 0 },
  "order_status_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "payment_method_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 order_histories

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::OrderHistory>

=cut

__PACKAGE__->has_many(
  "order_histories",
  "Business::Cart::Generic::Schema::Result::OrderHistory",
  { "foreign.order_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 order_items

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::OrderItem>

=cut

__PACKAGE__->has_many(
  "order_items",
  "Business::Cart::Generic::Schema::Result::OrderItem",
  { "foreign.order_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 delivery_address

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::StreetAddress>

=cut

__PACKAGE__->belongs_to(
  "delivery_address",
  "Business::Cart::Generic::Schema::Result::StreetAddress",
  { id => "delivery_address_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 payment_method

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::PaymentMethod>

=cut

__PACKAGE__->belongs_to(
  "payment_method",
  "Business::Cart::Generic::Schema::Result::PaymentMethod",
  { id => "payment_method_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 customer_address

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::StreetAddress>

=cut

__PACKAGE__->belongs_to(
  "customer_address",
  "Business::Cart::Generic::Schema::Result::StreetAddress",
  { id => "customer_address_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 billing_address

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::StreetAddress>

=cut

__PACKAGE__->belongs_to(
  "billing_address",
  "Business::Cart::Generic::Schema::Result::StreetAddress",
  { id => "billing_address_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 order_status

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::OrderStatuse>

=cut

__PACKAGE__->belongs_to(
  "order_status",
  "Business::Cart::Generic::Schema::Result::OrderStatuse",
  { id => "order_status_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 customer

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Customer>

=cut

__PACKAGE__->belongs_to(
  "customer",
  "Business::Cart::Generic::Schema::Result::Customer",
  { id => "customer_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oPwVmehLObBuotsqFzkDew


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
