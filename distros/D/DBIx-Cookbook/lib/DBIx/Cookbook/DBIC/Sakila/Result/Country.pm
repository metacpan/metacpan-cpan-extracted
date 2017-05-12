package DBIx::Cookbook::DBIC::Sakila::Result::Country;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBIx::Cookbook::DBIC::Sakila::Result::Country

=cut

__PACKAGE__->table("country");

=head1 ACCESSORS

=head2 country_id

  data_type: SMALLINT
  default_value: undef
  extra: HASH(0xa12a8a0)
  is_auto_increment: 1
  is_nullable: 0
  size: 5

=head2 country

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 50

=head2 last_update

  data_type: TIMESTAMP
  default_value: CURRENT_TIMESTAMP
  is_nullable: 0
  size: 14

=cut

__PACKAGE__->add_columns(
  "country_id",
  {
    data_type => "SMALLINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
    size => 5,
  },
  "country",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 50,
  },
  "last_update",
  {
    data_type => "TIMESTAMP",
    default_value => \"CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("country_id");

=head1 RELATIONS

=head2 cities

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::City>

=cut

__PACKAGE__->has_many(
  "cities",
  "DBIx::Cookbook::DBIC::Sakila::Result::City",
  { "foreign.country_id" => "self.country_id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-24 17:44:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9p8g6aRpy8a+BCNE/uD2nQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
