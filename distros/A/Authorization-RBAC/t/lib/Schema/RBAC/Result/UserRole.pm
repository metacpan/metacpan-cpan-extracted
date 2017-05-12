package Schema::RBAC::Result::UserRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components;

=head1 NAME

Schema::RBAC::Result::UserRole

=cut

__PACKAGE__->table("user_role");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 role_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "role_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("user_id", "role_id");

=head1 RELATIONS

=head2 role

Type: belongs_to

Related object: L<Schema::RBAC::Result::Role>

=cut

__PACKAGE__->belongs_to(
  "role",
  "Schema::RBAC::Result::Role",
  { id => "role_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 user

Type: belongs_to

Related object: L<Schema::RBAC::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Schema::RBAC::Result::User",
  { id => "user_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-02 18:58:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kuqGfpPTl5RIJPy/3Yvxkg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
