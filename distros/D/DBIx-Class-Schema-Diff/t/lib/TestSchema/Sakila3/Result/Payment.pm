package # Hide from pause
     TestSchema::Sakila3::Result::Payment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

TestSchema::Sakila3::Result::Payment

=cut

__PACKAGE__->table("payment");

=head1 ACCESSORS

=head2 payment_id

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 customer_id

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 staff_id

  data_type: 'tinyint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 rental_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 amount

  data_type: 'decimal'
  is_nullable: 0
  size: [5,2]

=head2 payment_date

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
  "payment_id",
  {
    data_type => "smallint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "customer_id",
  {
    data_type => "smallint",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "staff_id",
  {
    data_type => "tinyint",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "rental_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "amount",
  { data_type => "decimal", is_nullable => 0, size => [5, 2] },
  "payment_date",
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
__PACKAGE__->set_primary_key("payment_id");

=head1 RELATIONS

=head2 rental

Type: belongs_to

Related object: L<TestSchema::Sakila3::Result::Rental>

=cut

__PACKAGE__->belongs_to(
  "rental",
  "TestSchema::Sakila3::Result::Rental",
  { rental_id => "rental_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 customer

Type: belongs_to

Related object: L<TestSchema::Sakila3::Result::Customer>

=cut

__PACKAGE__->belongs_to(
  "customer",
  "TestSchema::Sakila3::Result::Customer",
  { customer_id => "customer_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 staff

Type: belongs_to

Related object: L<TestSchema::Sakila3::Result::Staff>

=cut

__PACKAGE__->belongs_to(
  "staff",
  "TestSchema::Sakila3::Result::Staff",
  { staff_id => "staff_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-17 16:15:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:o58GSNyuoFFqYxC9gQiZ6g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
