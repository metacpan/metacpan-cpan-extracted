package # Hide from pause
     TestSchema::Sakila3::Result::Address;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

TestSchema::Sakila3::Result::Address

=cut

__PACKAGE__->table("sakila.address");

=head1 ACCESSORS

=head2 address_id

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 address

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 address2

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 district

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 city_id

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 postal_code

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 phone

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 last_update

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "address_id",
  {
    data_type => "smallint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "address",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "address2",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "district",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "city_id",
  {
    data_type => "smallint",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "postal_code",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "phone",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "last_update",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("address_id");

=head1 RELATIONS

=head2 city

Type: belongs_to

Related object: L<TestSchema::Sakila3::Result::City>

=cut

__PACKAGE__->belongs_to(
  "city",
  "TestSchema::Sakila3::Result::City",
  { city_id => "city_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 customers

Type: has_many

Related object: L<TestSchema::Sakila3::Result::Customer>

=cut

__PACKAGE__->has_many(
  "customers",
  "TestSchema::Sakila3::Result::Customer",
  { "foreign.address_id" => "self.address_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 staffs

Type: has_many

Related object: L<TestSchema::Sakila3::Result::Staff>

=cut

__PACKAGE__->has_many(
  "staffs",
  "TestSchema::Sakila3::Result::Staff",
  { "foreign.address_id" => "self.address_id" },
  { cascade_copy => 0, cascade_delete => 1 },
);

=head2 stores

Type: has_many

Related object: L<TestSchema::Sakila3::Result::Store>

=cut

__PACKAGE__->has_many(
  "stores",
  "TestSchema::Sakila3::Result::Store",
  { "foreign.address_id" => "self.address_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-17 16:15:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2IpqcMwZA7j+9RoW5A7Z7g

__PACKAGE__->has_many(
  "customers2",
  "TestSchema::Sakila3::Result::Customer",
  { "foreign.address_id" => "self.address_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

{ package Test::DummyClass; $INC{'Test/DummyClass.pm'} = __FILE__ }
__PACKAGE__->load_components("+Test::DummyClass");

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
