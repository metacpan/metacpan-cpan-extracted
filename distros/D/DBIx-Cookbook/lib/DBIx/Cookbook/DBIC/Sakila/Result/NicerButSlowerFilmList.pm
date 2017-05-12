package DBIx::Cookbook::DBIC::Sakila::Result::NicerButSlowerFilmList;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBIx::Cookbook::DBIC::Sakila::Result::NicerButSlowerFilmList

=cut

__PACKAGE__->table("nicer_but_slower_film_list");

=head1 ACCESSORS

=head2 fid

  data_type: SMALLINT
  default_value: 0
  extra: HASH(0xa12a6e0)
  is_nullable: 1
  size: 5

=head2 title

  data_type: VARCHAR
  default_value: undef
  is_nullable: 1
  size: 255

=head2 description

  data_type: TEXT
  default_value: undef
  is_nullable: 1
  size: 65535

=head2 category

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 25

=head2 price

  data_type: DECIMAL
  default_value: 4.99
  is_nullable: 1
  size: 4

=head2 length

  data_type: SMALLINT
  default_value: undef
  extra: HASH(0xa137f90)
  is_nullable: 1
  size: 5

=head2 rating

  data_type: ENUM
  default_value: G
  extra: HASH(0xa12d0f0)
  is_nullable: 1
  size: 5

=head2 actors

  data_type: VARCHAR
  default_value: undef
  is_nullable: 1
  size: 341

=cut

__PACKAGE__->add_columns(
  "fid",
  {
    data_type => "SMALLINT",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
    size => 5,
  },
  "title",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "category",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 25,
  },
  "price",
  {
    data_type => "DECIMAL",
    default_value => "4.99",
    is_nullable => 1,
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
  "rating",
  {
    data_type => "ENUM",
    default_value => "G",
    extra => { list => ["G", "PG", "PG-13", "R", "NC-17"] },
    is_nullable => 1,
    size => 5,
  },
  "actors",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 341,
  },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-24 17:44:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AWsLH9nE5Wtu4lgv4SAjBw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
