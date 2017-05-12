package DBIx::Cookbook::DBIC::Sakila::Result::Store;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBIx::Cookbook::DBIC::Sakila::Result::Store

=cut

__PACKAGE__->table("store");

=head1 ACCESSORS

=head2 store_id

  data_type: TINYINT
  default_value: undef
  extra: HASH(0xa132408)
  is_auto_increment: 1
  is_nullable: 0
  size: 3

=head2 manager_staff_id

  data_type: TINYINT
  default_value: undef
  extra: HASH(0xa138860)
  is_foreign_key: 1
  is_nullable: 0
  size: 3

=head2 address_id

  data_type: SMALLINT
  default_value: undef
  extra: HASH(0xa12c710)
  is_foreign_key: 1
  is_nullable: 0
  size: 5

=head2 last_update

  data_type: TIMESTAMP
  default_value: CURRENT_TIMESTAMP
  is_nullable: 0
  size: 14

=cut

__PACKAGE__->add_columns(
  "store_id",
  {
    data_type => "TINYINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
    size => 3,
  },
  "manager_staff_id",
  {
    data_type => "TINYINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
    size => 3,
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
  "last_update",
  {
    data_type => "TIMESTAMP",
    default_value => \"CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("store_id");
__PACKAGE__->add_unique_constraint("idx_unique_manager", ["manager_staff_id"]);

=head1 RELATIONS

=head2 customers

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Customer>

=cut

__PACKAGE__->has_many(
  "customers",
  "DBIx::Cookbook::DBIC::Sakila::Result::Customer",
  { "foreign.store_id" => "self.store_id" },
);

=head2 inventories

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Inventory>

=cut

__PACKAGE__->has_many(
  "inventories",
  "DBIx::Cookbook::DBIC::Sakila::Result::Inventory",
  { "foreign.store_id" => "self.store_id" },
);

=head2 staffs

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Staff>

=cut

__PACKAGE__->has_many(
  "staffs",
  "DBIx::Cookbook::DBIC::Sakila::Result::Staff",
  { "foreign.store_id" => "self.store_id" },
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

=head2 manager_staff

Type: belongs_to

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Staff>

=cut

__PACKAGE__->belongs_to(
  "manager_staff",
  "DBIx::Cookbook::DBIC::Sakila::Result::Staff",
  { staff_id => "manager_staff_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-24 17:44:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QGLgz+s6rP28FV/sNCYIfA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
