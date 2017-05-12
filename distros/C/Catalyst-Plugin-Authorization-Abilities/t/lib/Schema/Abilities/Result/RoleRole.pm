package Schema::Abilities::Result::RoleRole;

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

Schema::Abilities::Result::RoleRole

=cut

__PACKAGE__->table("role_roles");

=head1 ACCESSORS

=head2 role_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 inherits_from_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "role_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "inherits_from_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("role_id", "inherits_from_id");

=head1 RELATIONS

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

=head2 inherit_from

Type: belongs_to

Related object: L<Schema::Abilities::Result::Role>

=cut

__PACKAGE__->belongs_to(
  "inherit_from",
  "Schema::Abilities::Result::Role",
  { id => "inherits_from_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-17 10:52:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:b+SDV+D94YvMCIH5Uppz8Q


__PACKAGE__->belongs_to('parent' => 'Schema::Abilities::Result::Role', 'role_id',
                        { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" });

__PACKAGE__->belongs_to('role' => 'Schema::Abilities::Result::Role', 'inherits_from_id',
                        { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" });

__PACKAGE__->meta->make_immutable;
1;
