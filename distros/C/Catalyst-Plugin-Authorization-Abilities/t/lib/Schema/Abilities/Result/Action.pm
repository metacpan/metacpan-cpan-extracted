package Schema::Abilities::Result::Action;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(
  "InflateColumn::DateTime",
  "DateTime::Epoch",
  "TimeStamp",
  "EncodedColumn",
);

=head1 NAME

Schema::Abilities::Result::Action

=cut

__PACKAGE__->table("actions");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 40

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 254

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 40 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 254 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("name_unique", ["name"]);

=head1 RELATIONS

=head2 role_actions

Type: has_many

Related object: L<Schema::Abilities::Result::RoleAction>

=cut

__PACKAGE__->has_many(
  "role_actions",
  "Schema::Abilities::Result::RoleAction",
  { "foreign.action_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_actions

Type: has_many

Related object: L<Schema::Abilities::Result::UserAction>


=cut

__PACKAGE__->has_many(
  "user_actions",
  "Schema::Abilities::Result::UserAction",
  { "foreign.action_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-17 10:52:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9MkM7yJUfbHnQ25yYnVfKw


# __PACKAGE__->has_many(map_role_actions => 'Schema::Abilities::Result::RoleAction', 'role_id',
#                       { cascade_copy => 0, cascade_delete => 0 });

# __PACKAGE__->many_to_many(roles => 'map_role_actions', 'action');

__PACKAGE__->meta->make_immutable;
1;
