package Business::Cart::Generic::Schema::Result::StreetAddress;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::StreetAddress

=cut

__PACKAGE__->table("street_addresses");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'street_addresses_id_seq'

=head2 country_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 zone_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 locality

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 postcode

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 street_1

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 street_2

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 street_3

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 street_4

  data_type: 'varchar'
  is_nullable: 0
  size: 255

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
    sequence          => "street_addresses_id_seq",
  },
  "country_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "zone_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "locality",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "postcode",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "street_1",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "street_2",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "street_3",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "street_4",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "upper_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 customers

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::Customer>

=cut

__PACKAGE__->has_many(
  "customers",
  "Business::Cart::Generic::Schema::Result::Customer",
  { "foreign.default_street_address_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 orders_delivery_addresses

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::Order>

=cut

__PACKAGE__->has_many(
  "orders_delivery_addresses",
  "Business::Cart::Generic::Schema::Result::Order",
  { "foreign.delivery_address_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 orders_customer_addresses

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::Order>

=cut

__PACKAGE__->has_many(
  "orders_customer_addresses",
  "Business::Cart::Generic::Schema::Result::Order",
  { "foreign.customer_address_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 orders_billing_addresses

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::Order>

=cut

__PACKAGE__->has_many(
  "orders_billing_addresses",
  "Business::Cart::Generic::Schema::Result::Order",
  { "foreign.billing_address_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 country

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Country>

=cut

__PACKAGE__->belongs_to(
  "country",
  "Business::Cart::Generic::Schema::Result::Country",
  { id => "country_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 zone

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Zone>

=cut

__PACKAGE__->belongs_to(
  "zone",
  "Business::Cart::Generic::Schema::Result::Zone",
  { id => "zone_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MS8gQVgI9ZOBSM2IaHzUMA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
