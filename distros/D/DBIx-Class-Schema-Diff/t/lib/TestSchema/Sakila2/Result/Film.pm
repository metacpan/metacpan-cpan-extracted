package # Hide from pause
     TestSchema::Sakila2::Result::Film;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

TestSchema::Sakila2::Result::Film

=cut

__PACKAGE__->table("film");

=head1 ACCESSORS

=head2 film_id

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 release_year

  data_type: 'year'
  is_nullable: 1

=head2 language_id

  data_type: 'tinyint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 original_language_id

  data_type: 'tinyint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 rental_duration

  data_type: 'tinyint'
  default_value: 3
  extra: {unsigned => 1}
  is_nullable: 0

=head2 rental_rate

  data_type: 'decimal'
  default_value: 4.99
  is_nullable: 0
  size: [4,2]

=head2 length

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 replacement_cost

  data_type: 'decimal'
  default_value: 19.99
  is_nullable: 0
  size: [5,2]

=head2 rating

  data_type: 'enum'
  default_value: 'G'
  extra: {list => ["G","PG","PG-13","R","NC-17"]}
  is_nullable: 1

=head2 special_features

  data_type: 'set'
  extra: {list => ["Trailers","Commentaries","Deleted Scenes","Behind the Scenes"]}
  is_nullable: 1

=head2 last_update

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "film_id",
  {
    data_type => "smallint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "release_year",
  { data_type => "year", is_nullable => 1 },
  "language_id",
  {
    data_type => "tinyint",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "original_language_id",
  {
    data_type => "tinyint",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "rental_duration",
  {
    data_type => "tinyint",
    default_value => 3,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "rental_rate",
  {
    data_type => "decimal",
    default_value => "4.99",
    is_nullable => 0,
    size => [4, 2],
  },
  "length",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 1 },
  "replacement_cost",
  {
    data_type => "decimal",
    default_value => "19.99",
    is_nullable => 0,
    size => [5, 2],
  },
  "rating",
  {
    data_type => "enum",
    default_value => "G",
    extra => { list => ["G", "PG", "PG-13", "R", "NC-17"] },
    is_nullable => 1,
  },
  "special_features",
  {
    data_type => "set",
    extra => {
      list => [
        "Trailers",
        "Commentaries",
        "Deleted Scenes",
        "Behind the Scenes",
      ],
    },
    is_nullable => 1,
  },
  "last_update",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("film_id");

=head1 RELATIONS

=head2 language

Type: belongs_to

Related object: L<TestSchema::Sakila2::Result::Language>

=cut

__PACKAGE__->belongs_to(
  "language",
  "TestSchema::Sakila2::Result::Language",
  { language_id => "language_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 original_language

Type: belongs_to

Related object: L<TestSchema::Sakila2::Result::Language>

=cut

__PACKAGE__->belongs_to(
  "original_language",
  "TestSchema::Sakila2::Result::Language",
  { language_id => "original_language_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 film_actors

Type: has_many

Related object: L<TestSchema::Sakila2::Result::FilmActor>

=cut

__PACKAGE__->has_many(
  "film_actors",
  "TestSchema::Sakila2::Result::FilmActor",
  { "foreign.film_id" => "self.film_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 film_categories

Type: has_many

Related object: L<TestSchema::Sakila2::Result::FilmCategory>

=cut

__PACKAGE__->has_many(
  "film_categories",
  "TestSchema::Sakila2::Result::FilmCategory",
  { "foreign.film_id" => "self.film_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 inventories

Type: has_many

Related object: L<TestSchema::Sakila2::Result::Inventory>

=cut

__PACKAGE__->has_many(
  "inventories",
  "TestSchema::Sakila2::Result::Inventory",
  { "foreign.film_id" => "self.film_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-17 16:15:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ulh+bL2NSPJo0qWtNss1pA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
