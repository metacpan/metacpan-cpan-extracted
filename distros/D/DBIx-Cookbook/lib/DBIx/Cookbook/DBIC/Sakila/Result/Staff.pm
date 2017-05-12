package DBIx::Cookbook::DBIC::Sakila::Result::Staff;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBIx::Cookbook::DBIC::Sakila::Result::Staff

=cut

__PACKAGE__->table("staff");

=head1 ACCESSORS

=head2 staff_id

  data_type: TINYINT
  default_value: undef
  extra: HASH(0xa132758)
  is_auto_increment: 1
  is_nullable: 0
  size: 3

=head2 first_name

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 45

=head2 last_name

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 45

=head2 address_id

  data_type: SMALLINT
  default_value: undef
  extra: HASH(0xa1384e0)
  is_foreign_key: 1
  is_nullable: 0
  size: 5

=head2 picture

  data_type: BLOB
  default_value: undef
  is_nullable: 1
  size: 65535

=head2 email

  data_type: VARCHAR
  default_value: undef
  is_nullable: 1
  size: 50

=head2 store_id

  data_type: TINYINT
  default_value: undef
  extra: HASH(0xa129630)
  is_foreign_key: 1
  is_nullable: 0
  size: 3

=head2 active

  data_type: TINYINT
  default_value: 1
  is_nullable: 0
  size: 1

=head2 username

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 16

=head2 password

  data_type: VARCHAR
  default_value: undef
  is_nullable: 1
  size: 40

=head2 last_update

  data_type: TIMESTAMP
  default_value: CURRENT_TIMESTAMP
  is_nullable: 0
  size: 14

=cut

__PACKAGE__->add_columns(
  "staff_id",
  {
    data_type => "TINYINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
    size => 3,
  },
  "first_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 45,
  },
  "last_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 45,
  },
  "address_id",
  {
    data_type => "SMALLINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
    size => 5,
  },
  "picture",
  {
    data_type => "BLOB",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "email",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "store_id",
  {
    data_type => "TINYINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
    size => 3,
  },
  "active",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 1 },
  "username",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 16,
  },
  "password",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
  "last_update",
  {
    data_type => "TIMESTAMP",
    default_value => \"CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("staff_id");

=head1 RELATIONS

=head2 payments

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Payment>

=cut

__PACKAGE__->has_many(
  "payments",
  "DBIx::Cookbook::DBIC::Sakila::Result::Payment",
  { "foreign.staff_id" => "self.staff_id" },
);

=head2 rentals

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Rental>

=cut

__PACKAGE__->has_many(
  "rentals",
  "DBIx::Cookbook::DBIC::Sakila::Result::Rental",
  { "foreign.staff_id" => "self.staff_id" },
);

=head2 address

Type: belongs_to

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Address>

=cut

__PACKAGE__->belongs_to(
  "address",
  "DBIx::Cookbook::DBIC::Sakila::Result::Address",
  { address_id => "address_id" },
  {},
);

=head2 store

Type: belongs_to

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Store>

=cut

__PACKAGE__->belongs_to(
  "store",
  "DBIx::Cookbook::DBIC::Sakila::Result::Store",
  { store_id => "store_id" },
  {},
);

=head2 store

Type: might_have

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Store>

=cut

__PACKAGE__->might_have(
  "store",
  "DBIx::Cookbook::DBIC::Sakila::Result::Store",
  { "foreign.manager_staff_id" => "self.staff_id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-24 17:44:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KhyG05qblWhextwwwHjF6g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
