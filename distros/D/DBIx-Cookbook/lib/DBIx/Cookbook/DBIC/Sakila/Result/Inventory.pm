package DBIx::Cookbook::DBIC::Sakila::Result::Inventory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBIx::Cookbook::DBIC::Sakila::Result::Inventory

=cut

__PACKAGE__->table("inventory");

=head1 ACCESSORS

=head2 inventory_id

  data_type: MEDIUMINT
  default_value: undef
  extra: HASH(0xa123620)
  is_auto_increment: 1
  is_nullable: 0
  size: 8

=head2 film_id

  data_type: SMALLINT
  default_value: undef
  extra: HASH(0xa123450)
  is_foreign_key: 1
  is_nullable: 0
  size: 5

=head2 store_id

  data_type: TINYINT
  default_value: undef
  extra: HASH(0xa132de8)
  is_foreign_key: 1
  is_nullable: 0
  size: 3

=head2 last_update

  data_type: TIMESTAMP
  default_value: CURRENT_TIMESTAMP
  is_nullable: 0
  size: 14

=cut

__PACKAGE__->add_columns(
  "inventory_id",
  {
    data_type => "MEDIUMINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "film_id",
  {
    data_type => "SMALLINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
    size => 5,
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
  "last_update",
  {
    data_type => "TIMESTAMP",
    default_value => \"CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("inventory_id");

=head1 RELATIONS

=head2 film

Type: belongs_to

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Film>

=cut

__PACKAGE__->belongs_to(
  "film",
  "DBIx::Cookbook::DBIC::Sakila::Result::Film",
  { film_id => "film_id" },
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

=head2 rentals

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Rental>

=cut

__PACKAGE__->has_many(
  "rentals",
  "DBIx::Cookbook::DBIC::Sakila::Result::Rental",
  { "foreign.inventory_id" => "self.inventory_id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-24 17:44:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wuMaOafoQvlVFTyzps2Fgg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
