package Business::Cart::Generic::Schema::Result::Customer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::Customer

=cut

__PACKAGE__->table("customers");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'customers_id_seq'

=head2 customer_status_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 customer_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 default_street_address_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 gender_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 date_added

  data_type: 'timestamp'
  is_nullable: 0

=head2 date_of_birth

  data_type: 'timestamp'
  default_value: '1900-01-01 00:00:00'
  is_nullable: 0

=head2 date_modified

  data_type: 'timestamp'
  is_nullable: 0

=head2 given_names

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 password

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 preferred_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 surname

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 upper_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 username

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
    sequence          => "customers_id_seq",
  },
  "customer_status_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "customer_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "default_street_address_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "gender_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "date_added",
  { data_type => "timestamp", is_nullable => 0 },
  "date_of_birth",
  {
    data_type     => "timestamp",
    default_value => "1900-01-01 00:00:00",
    is_nullable   => 0,
  },
  "date_modified",
  { data_type => "timestamp", is_nullable => 0 },
  "given_names",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "password",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "preferred_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "surname",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "upper_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 title

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Title>

=cut

__PACKAGE__->belongs_to(
  "title",
  "Business::Cart::Generic::Schema::Result::Title",
  { id => "title_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 gender

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Gender>

=cut

__PACKAGE__->belongs_to(
  "gender",
  "Business::Cart::Generic::Schema::Result::Gender",
  { id => "gender_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 default_street_address

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::StreetAddress>

=cut

__PACKAGE__->belongs_to(
  "default_street_address",
  "Business::Cart::Generic::Schema::Result::StreetAddress",
  { id => "default_street_address_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 customer_status

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::CustomerStatuse>

=cut

__PACKAGE__->belongs_to(
  "customer_status",
  "Business::Cart::Generic::Schema::Result::CustomerStatuse",
  { id => "customer_status_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 customer_type

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::CustomerType>

=cut

__PACKAGE__->belongs_to(
  "customer_type",
  "Business::Cart::Generic::Schema::Result::CustomerType",
  { id => "customer_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 email_lists

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::EmailList>

=cut

__PACKAGE__->has_many(
  "email_lists",
  "Business::Cart::Generic::Schema::Result::EmailList",
  { "foreign.customer_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 logons

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::Logon>

=cut

__PACKAGE__->has_many(
  "logons",
  "Business::Cart::Generic::Schema::Result::Logon",
  { "foreign.customer_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 orders

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::Order>

=cut

__PACKAGE__->has_many(
  "orders",
  "Business::Cart::Generic::Schema::Result::Order",
  { "foreign.customer_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phone_lists

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::PhoneList>

=cut

__PACKAGE__->has_many(
  "phone_lists",
  "Business::Cart::Generic::Schema::Result::PhoneList",
  { "foreign.customer_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IkTV9P0QPtH+OFw4aoSuSA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
