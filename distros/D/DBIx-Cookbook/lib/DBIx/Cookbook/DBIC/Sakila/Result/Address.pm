package DBIx::Cookbook::DBIC::Sakila::Result::Address;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBIx::Cookbook::DBIC::Sakila::Result::Address

=cut

__PACKAGE__->table("address");

=head1 ACCESSORS

=head2 address_id

  data_type: SMALLINT
  default_value: undef
  extra: HASH(0xa128e90)
  is_auto_increment: 1
  is_nullable: 0
  size: 5

=head2 address

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 50

=head2 address2

  data_type: VARCHAR
  default_value: undef
  is_nullable: 1
  size: 50

=head2 district

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 20

=head2 city_id

  data_type: SMALLINT
  default_value: undef
  extra: HASH(0xa128ad0)
  is_foreign_key: 1
  is_nullable: 0
  size: 5

=head2 postal_code

  data_type: VARCHAR
  default_value: undef
  is_nullable: 1
  size: 10

=head2 phone

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 20

=head2 last_update

  data_type: TIMESTAMP
  default_value: CURRENT_TIMESTAMP
  is_nullable: 0
  size: 14

=cut

__PACKAGE__->add_columns(
  "address_id",
  {
    data_type => "SMALLINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
    size => 5,
  },
  "address",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 50,
  },
  "address2",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "district",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "city_id",
  {
    data_type => "SMALLINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
    size => 5,
  },
  "postal_code",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "phone",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "last_update",
  {
    data_type => "TIMESTAMP",
    default_value => \"CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("address_id");

=head1 RELATIONS

=head2 city

Type: belongs_to

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::City>

=cut

__PACKAGE__->belongs_to(
  "city",
  "DBIx::Cookbook::DBIC::Sakila::Result::City",
  { city_id => "city_id" },
  {},
);

=head2 customers

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Customer>

=cut

__PACKAGE__->has_many(
  "customers",
  "DBIx::Cookbook::DBIC::Sakila::Result::Customer",
  { "foreign.address_id" => "self.address_id" },
);

=head2 staffs

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Staff>

=cut

__PACKAGE__->has_many(
  "staffs",
  "DBIx::Cookbook::DBIC::Sakila::Result::Staff",
  { "foreign.address_id" => "self.address_id" },
);

=head2 stores

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Store>

=cut

__PACKAGE__->has_many(
  "stores",
  "DBIx::Cookbook::DBIC::Sakila::Result::Store",
  { "foreign.address_id" => "self.address_id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-24 17:44:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cQxGkVyPlKWV1MDRg+nXpA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
