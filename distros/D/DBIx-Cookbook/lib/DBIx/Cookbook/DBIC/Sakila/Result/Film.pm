package DBIx::Cookbook::DBIC::Sakila::Result::Film;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBIx::Cookbook::DBIC::Sakila::Result::Film

=cut

__PACKAGE__->table("film");

=head1 ACCESSORS

=head2 film_id

  data_type: SMALLINT
  default_value: undef
  extra: HASH(0xa1329f8)
  is_auto_increment: 1
  is_nullable: 0
  size: 5

=head2 title

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 255

=head2 description

  data_type: TEXT
  default_value: undef
  is_nullable: 1
  size: 65535

=head2 release_year

  data_type: YEAR
  default_value: undef
  is_nullable: 1
  size: 4

=head2 language_id

  data_type: TINYINT
  default_value: undef
  extra: HASH(0xa12a310)
  is_foreign_key: 1
  is_nullable: 0
  size: 3

=head2 original_language_id

  data_type: TINYINT
  default_value: undef
  extra: HASH(0xa123300)
  is_foreign_key: 1
  is_nullable: 1
  size: 3

=head2 rental_duration

  data_type: TINYINT
  default_value: 3
  extra: HASH(0xa12ce70)
  is_nullable: 0
  size: 3

=head2 rental_rate

  data_type: DECIMAL
  default_value: 4.99
  is_nullable: 0
  size: 4

=head2 length

  data_type: SMALLINT
  default_value: undef
  extra: HASH(0xa1234e0)
  is_nullable: 1
  size: 5

=head2 replacement_cost

  data_type: DECIMAL
  default_value: 19.99
  is_nullable: 0
  size: 5

=head2 rating

  data_type: ENUM
  default_value: G
  extra: HASH(0xa12d650)
  is_nullable: 1
  size: 5

=head2 special_features

  data_type: SET
  default_value: undef
  extra: HASH(0xa1324b8)
  is_nullable: 1
  size: 54

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
    is_auto_increment => 1,
    is_nullable => 0,
    size => 5,
  },
  "title",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "release_year",
  { data_type => "YEAR", default_value => undef, is_nullable => 1, size => 4 },
  "language_id",
  {
    data_type => "TINYINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
    size => 3,
  },
  "original_language_id",
  {
    data_type => "TINYINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
    size => 3,
  },
  "rental_duration",
  {
    data_type => "TINYINT",
    default_value => 3,
    extra => { unsigned => 1 },
    is_nullable => 0,
    size => 3,
  },
  "rental_rate",
  {
    data_type => "DECIMAL",
    default_value => "4.99",
    is_nullable => 0,
    size => 4,
  },
  "length",
  {
    data_type => "SMALLINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_nullable => 1,
    size => 5,
  },
  "replacement_cost",
  {
    data_type => "DECIMAL",
    default_value => "19.99",
    is_nullable => 0,
    size => 5,
  },
  "rating",
  {
    data_type => "ENUM",
    default_value => "G",
    extra => { list => ["G", "PG", "PG-13", "R", "NC-17"] },
    is_nullable => 1,
    size => 5,
  },
  "special_features",
  {
    data_type => "SET",
    default_value => undef,
    extra => {
          list => [
                "Trailers",
                "Commentaries",
                "Deleted Scenes",
                "Behind the Scenes",
              ],
        },
    is_nullable => 1,
    size => 54,
  },
  "last_update",
  {
    data_type => "TIMESTAMP",
    default_value => \"CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("film_id");

=head1 RELATIONS

=head2 language

Type: belongs_to

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Language>

=cut

__PACKAGE__->belongs_to(
  "language",
  "DBIx::Cookbook::DBIC::Sakila::Result::Language",
  { language_id => "language_id" },
  {},
);

=head2 original_language

Type: belongs_to

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Language>

=cut

__PACKAGE__->belongs_to(
  "original_language",
  "DBIx::Cookbook::DBIC::Sakila::Result::Language",
  { language_id => "original_language_id" },
  { join_type => "LEFT" },
);

=head2 film_actors

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::FilmActor>

=cut

__PACKAGE__->has_many(
  "film_actors",
  "DBIx::Cookbook::DBIC::Sakila::Result::FilmActor",
  { "foreign.film_id" => "self.film_id" },
);

=head2 film_categories

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::FilmCategory>

=cut

__PACKAGE__->has_many(
  "film_categories",
  "DBIx::Cookbook::DBIC::Sakila::Result::FilmCategory",
  { "foreign.film_id" => "self.film_id" },
);

=head2 inventories

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Inventory>

=cut

__PACKAGE__->has_many(
  "inventories",
  "DBIx::Cookbook::DBIC::Sakila::Result::Inventory",
  { "foreign.film_id" => "self.film_id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-24 17:44:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZW0YB898J0laYO132LD53Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
