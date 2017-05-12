package DBIx::Cookbook::DBIC::Sakila::Result::Actor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBIx::Cookbook::DBIC::Sakila::Result::Actor

=cut

__PACKAGE__->table("actor");

=head1 ACCESSORS

=head2 actor_id

  data_type: SMALLINT
  default_value: undef
  extra: HASH(0xa1204d8)
  is_auto_increment: 1
  is_nullable: 0
  size: 5

=head2 first_name

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 45

=head2 last_name

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 45

=head2 last_update

  data_type: TIMESTAMP
  default_value: CURRENT_TIMESTAMP
  is_nullable: 0
  size: 14

=cut

__PACKAGE__->add_columns(
  "actor_id",
  {
    data_type => "SMALLINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
    size => 5,
  },
  "first_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 45,
  },
  "last_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 45,
  },
  "last_update",
  {
    data_type => "TIMESTAMP",
    default_value => \"CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("actor_id");

=head1 RELATIONS

=head2 film_actors

Type: has_many

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::FilmActor>

=cut

__PACKAGE__->has_many(
  "film_actors",
  "DBIx::Cookbook::DBIC::Sakila::Result::FilmActor",
  { "foreign.actor_id" => "self.actor_id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-24 17:44:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:z/mxDv0uX0ZGoK3lnTprTQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
