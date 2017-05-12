package # Hide from pause
     TestSchema::Sakila::Result::Staff;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

TestSchema::Sakila::Result::Staff

=cut

__PACKAGE__->table("staff");

=head1 ACCESSORS

=head2 staff_id

  data_type: 'tinyint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 first_name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 last_name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 address_id

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 picture

  data_type: 'blob'
  is_nullable: 1

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 store_id

  data_type: 'tinyint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 active

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=head2 password

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 last_update

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "staff_id",
  {
    data_type => "tinyint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "first_name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "last_name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "address_id",
  {
    data_type => "smallint",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "picture",
  { data_type => "blob", is_nullable => 1 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "store_id",
  {
    data_type => "tinyint",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "active",
  { data_type => "tinyint", default_value => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "last_update",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("staff_id");

=head1 RELATIONS

=head2 payments

Type: has_many

Related object: L<TestSchema::Sakila::Result::Payment>

=cut

__PACKAGE__->has_many(
  "payments",
  "TestSchema::Sakila::Result::Payment",
  { "foreign.staff_id" => "self.staff_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rentals

Type: has_many

Related object: L<TestSchema::Sakila::Result::Rental>

=cut

__PACKAGE__->has_many(
  "rentals",
  "TestSchema::Sakila::Result::Rental",
  { "foreign.staff_id" => "self.staff_id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

Type: might_have

Related object: L<TestSchema::Sakila::Result::Store>

=cut

__PACKAGE__->might_have(
  "store",
  "TestSchema::Sakila::Result::Store",
  { "foreign.manager_staff_id" => "self.staff_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-17 16:15:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vsAR5vX9nl/POAW1SXr5vA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
