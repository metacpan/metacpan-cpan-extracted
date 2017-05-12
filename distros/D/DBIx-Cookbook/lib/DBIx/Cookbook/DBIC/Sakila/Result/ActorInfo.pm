package DBIx::Cookbook::DBIC::Sakila::Result::ActorInfo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBIx::Cookbook::DBIC::Sakila::Result::ActorInfo

=cut

__PACKAGE__->table("actor_info");

=head1 ACCESSORS

=head2 actor_id

  data_type: SMALLINT
  default_value: 0
  extra: HASH(0xa123ff0)
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

=head2 film_info

  data_type: VARCHAR
  default_value: undef
  is_nullable: 1
  size: 341

=cut

__PACKAGE__->add_columns(
  "actor_id",
  {
    data_type => "SMALLINT",
    default_value => 0,
    extra => { unsigned => 1 },
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
  "film_info",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 341,
  },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-24 17:44:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kO/nG+tslGLZ560wArW8og


# You can replace this text with custom content, and it will be preserved on regeneration
1;
