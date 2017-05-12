package DBIx::Cookbook::DBIC::Sakila::Result::FilmActor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBIx::Cookbook::DBIC::Sakila::Result::FilmActor

=cut

__PACKAGE__->table("film_actor");

=head1 ACCESSORS

=head2 actor_id

  data_type: SMALLINT
  default_value: undef
  extra: HASH(0xa132298)
  is_foreign_key: 1
  is_nullable: 0
  size: 5

=head2 film_id

  data_type: SMALLINT
  default_value: undef
  extra: HASH(0xa123650)
  is_foreign_key: 1
  is_nullable: 0
  size: 5

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
    is_foreign_key => 1,
    is_nullable => 0,
    size => 5,
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
  "last_update",
  {
    data_type => "TIMESTAMP",
    default_value => \"CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("actor_id", "film_id");

=head1 RELATIONS

=head2 actor

Type: belongs_to

Related object: L<DBIx::Cookbook::DBIC::Sakila::Result::Actor>

=cut

__PACKAGE__->belongs_to(
  "actor",
  "DBIx::Cookbook::DBIC::Sakila::Result::Actor",
  { actor_id => "actor_id" },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YQoq99ABT/m7b4ssxLhy/A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
