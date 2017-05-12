package # Hide from pause
     TestSchema::Sakila::Result::Customer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

TestSchema::Sakila::Result::Customer

=cut

__PACKAGE__->table("customer");

=head1 ACCESSORS

=head2 customer_id

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 store_id

  data_type: 'tinyint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 first_name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 last_name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 address_id

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 active

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 0

=head2 create_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 last_update

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "customer_id",
  {
    data_type => "smallint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "store_id",
  {
    data_type => "tinyint",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "first_name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "last_name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "address_id",
  {
    data_type => "smallint",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "active",
  { data_type => "tinyint", default_value => 1, is_nullable => 0 },
  "create_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "last_update",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("customer_id");

=head1 RELATIONS

=head2 address

Type: belongs_to

Related object: L<TestSchema::Sakila::Result::Address>

=cut

__PACKAGE__->belongs_to(
  "address",
  "TestSchema::Sakila::Result::Address",
  { address_id => "address_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 store

Type: belongs_to

Related object: L<TestSchema::Sakila::Result::Store>

=cut

__PACKAGE__->belongs_to(
  "store",
  "TestSchema::Sakila::Result::Store",
  { store_id => "store_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 payments

Type: has_many

Related object: L<TestSchema::Sakila::Result::Payment>

=cut

__PACKAGE__->has_many(
  "payments",
  "TestSchema::Sakila::Result::Payment",
  { "foreign.customer_id" => "self.customer_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rentals

Type: has_many

Related object: L<TestSchema::Sakila::Result::Rental>

=cut

__PACKAGE__->has_many(
  "rentals",
  "TestSchema::Sakila::Result::Rental",
  { "foreign.customer_id" => "self.customer_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-17 16:15:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VjyzmGea6edtdAUrjNJakQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
