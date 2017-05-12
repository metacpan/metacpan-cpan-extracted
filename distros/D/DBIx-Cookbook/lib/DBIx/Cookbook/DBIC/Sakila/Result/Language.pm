package DBIx::Cookbook::DBIC::Sakila::Result::Language;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBIx::Cookbook::DBIC::Sakila::Result::Language

=cut

__PACKAGE__->table("language");

=head1 ACCESSORS

=head2 language_id

  data_type: TINYINT
  default_value: undef
  extra: HASH(0xa137d50)
  is_auto_increment: 1
  is_nullable: 0
  size: 3

=head2 name

  data_type: CHAR
  default_value: undef
  is_nullable: 0
  size: 20

=head2 last_update

  data_type: TIMESTAMP
  default_value: CURRENT_TIMESTAMP
  is_nullable: 0
  size: 14

=cut

__PACKAGE__->add_columns(
  "language_id",
  {
    data_type => "TINYINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
    size => 3,
  },
  "name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 20 },
  "last_update",
  {
    data_type => "TIMESTAMP",
    default_value => \"CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("language_id");

=head1 RELATIONS

=head2 film_languages

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Film>

=cut

__PACKAGE__->has_many(
  "film_languages",
  "DBIx::Cookbook::DBIC::Sakila::Result::Film",
  { "foreign.language_id" => "self.language_id" },
);

=head2 film_original_languages

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Film>

=cut

__PACKAGE__->has_many(
  "film_original_languages",
  "DBIx::Cookbook::DBIC::Sakila::Result::Film",
  { "foreign.original_language_id" => "self.language_id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-24 17:44:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KHALFQmBaVYcwiG2hBUU5w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
