package DBIx::Cookbook::DBIC::Sakila::Result::FilmText;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBIx::Cookbook::DBIC::Sakila::Result::FilmText

=cut

__PACKAGE__->table("film_text");

=head1 ACCESSORS

=head2 film_id

  data_type: SMALLINT
  default_value: undef
  is_nullable: 0
  size: 6

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

=cut

__PACKAGE__->add_columns(
  "film_id",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 0,
    size => 6,
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
);
__PACKAGE__->set_primary_key("film_id");


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-24 17:44:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ezDkYAjN877KMQPyjRuvmQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
