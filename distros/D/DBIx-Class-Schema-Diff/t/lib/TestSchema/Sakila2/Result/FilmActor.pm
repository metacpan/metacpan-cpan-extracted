package # Hide from pause
     TestSchema::Sakila2::Result::FilmActor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

TestSchema::Sakila2::Result::FilmActor

=cut

__PACKAGE__->table("film_actor");

=head1 ACCESSORS

=head2 actor_id

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 film_id

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 last_update

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "actor_id",
  {
    data_type => "smallint",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "film_id",
  {
    data_type => "smallint",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "last_update",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("actor_id", "film_id");

=head1 RELATIONS

=head2 actor

Type: belongs_to

Related object: L<TestSchema::Sakila2::Result::Actor>

=cut

__PACKAGE__->belongs_to(
  "actor",
  "TestSchema::Sakila2::Result::Actor",
  { actor_id => "actor_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 film

Type: belongs_to

Related object: L<TestSchema::Sakila2::Result::Film>

=cut

__PACKAGE__->belongs_to(
  "film",
  "TestSchema::Sakila2::Result::Film",
  { film_id => "film_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-17 16:15:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:byOXcXen2h/WbgCPtLAR4g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
