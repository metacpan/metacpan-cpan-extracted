package Schema::Abilities::Result::RoleAction;

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

Schema::Abilities::Result::RoleAction

=cut

__PACKAGE__->table("role_actions");

=head1 ACCESSORS

=head2 role_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 action_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "role_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "action_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("role_id", "action_id");

=head1 RELATIONS

=head2 action

Type: belongs_to

Related object: L<Schema::Abilities::Result::Action>

=cut

__PACKAGE__->belongs_to(
  "action",
  "Schema::Abilities::Result::Action",
  { id => "action_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 role

Type: belongs_to

Related object: L<Schema::Abilities::Result::Role>

=cut

__PACKAGE__->belongs_to(
  "role",
  "Schema::Abilities::Result::Role",
  { id => "role_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-17 10:52:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KxCk5w1t5qoJ8Ws8TgsGEA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
