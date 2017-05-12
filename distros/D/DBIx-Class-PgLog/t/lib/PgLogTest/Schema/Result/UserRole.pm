use utf8;
package PgLogTest::Schema::Result::UserRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PgLogTest::Schema::Result::UserRole

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<UserRole>

=cut

__PACKAGE__->table("UserRole");

=head1 ACCESSORS

=head2 UserId

  accessor: 'user_id'
  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 RoleId

  accessor: 'role_id'
  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "UserId",
  {
    accessor       => "user_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "RoleId",
  {
    accessor       => "role_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</UserId>

=item * L</RoleId>

=back

=cut

__PACKAGE__->set_primary_key("UserId", "RoleId");

=head1 RELATIONS

=head2 role

Type: belongs_to

Related object: L<PgLogTest::Schema::Result::Role>

=cut

__PACKAGE__->belongs_to(
  "role",
  "PgLogTest::Schema::Result::Role",
  { Id => "RoleId" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 user

Type: belongs_to

Related object: L<PgLogTest::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "PgLogTest::Schema::Result::User",
  { Id => "UserId" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-11 14:35:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U1F69eSR7CYprrCuOZyC8w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->load_components(qw/ PgLog /);
1;
