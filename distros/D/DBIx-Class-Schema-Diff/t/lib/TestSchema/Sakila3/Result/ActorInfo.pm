package # Hide from pause
     TestSchema::Sakila3::Result::ActorInfo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

TestSchema::Sakila3::Result::ActorInfo

=cut

__PACKAGE__->table("actor_info");

=head1 ACCESSORS

=head2 actor_id

  data_type: 'smallint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 first_name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 last_name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 film_info

  data_type: 'varchar'
  is_nullable: 1
  size: 341

=cut

__PACKAGE__->add_columns(
  "actor_id",
  {
    data_type => "smallint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "first_name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "last_name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "film_info",
  { data_type => "varchar", is_nullable => 1, size => 341 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-17 16:15:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lStSfm40bUPBYPd4KNPNNA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
