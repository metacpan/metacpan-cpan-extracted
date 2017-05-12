package DBIx::Cookbook::DBIC::Sakila::Result::FilmCategory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBIx::Cookbook::DBIC::Sakila::Result::FilmCategory

=cut

__PACKAGE__->table("film_category");

=head1 ACCESSORS

=head2 film_id

  data_type: SMALLINT
  default_value: undef
  extra: HASH(0xa132728)
  is_foreign_key: 1
  is_nullable: 0
  size: 5

=head2 category_id

  data_type: TINYINT
  default_value: undef
  extra: HASH(0xa137e30)
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
  "film_id",
  {
    data_type => "SMALLINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
    size => 5,
  },
  "category_id",
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
__PACKAGE__->set_primary_key("film_id", "category_id");

=head1 RELATIONS

=head2 category

Type: belongs_to

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Category>

=cut

__PACKAGE__->belongs_to(
  "category",
  "DBIx::Cookbook::DBIC::Sakila::Result::Category",
  { category_id => "category_id" },
  {},
);

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


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-24 17:44:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zD2DDf3tjiV20XU+otHc0w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
