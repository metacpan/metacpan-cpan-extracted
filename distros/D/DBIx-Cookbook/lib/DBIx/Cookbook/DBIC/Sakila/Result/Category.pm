package DBIx::Cookbook::DBIC::Sakila::Result::Category;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBIx::Cookbook::DBIC::Sakila::Result::Category

=cut

__PACKAGE__->table("category");

=head1 ACCESSORS

=head2 category_id

  data_type: TINYINT
  default_value: undef
  extra: HASH(0xa129310)
  is_auto_increment: 1
  is_nullable: 0
  size: 3

=head2 name

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 25

=head2 last_update

  data_type: TIMESTAMP
  default_value: CURRENT_TIMESTAMP
  is_nullable: 0
  size: 14

=cut

__PACKAGE__->add_columns(
  "category_id",
  {
    data_type => "TINYINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
    size => 3,
  },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 25,
  },
  "last_update",
  {
    data_type => "TIMESTAMP",
    default_value => \"CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("category_id");

=head1 RELATIONS

=head2 film_categories

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::FilmCategory>

=cut

__PACKAGE__->has_many(
  "film_categories",
  "DBIx::Cookbook::DBIC::Sakila::Result::FilmCategory",
  { "foreign.category_id" => "self.category_id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-24 17:44:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1KzHQ15Ao10+/lBBtSjm+g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
