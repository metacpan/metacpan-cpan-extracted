use utf8;
package PgLogTest::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PgLogTest::Schema::Result::User

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<User>

=cut

__PACKAGE__->table("User");

=head1 ACCESSORS

=head2 Id

  accessor: 'id'
  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: '"User_Id_seq"'

=head2 Name

  accessor: 'name'
  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 Email

  accessor: 'email'
  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 PasswordSalt

  accessor: 'password_salt'
  data_type: 'bytea'
  is_nullable: 0

=head2 PasswordHash

  accessor: 'password_hash'
  data_type: 'bytea'
  is_nullable: 0

=head2 Status

  accessor: 'status'
  data_type: 'varchar'
  default_value: 'Active'
  is_nullable: 0
  size: 64

=head2 UserType

  accessor: 'user_type'
  data_type: 'usertype[]'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "Id",
  {
    accessor          => "id",
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "\"User_Id_seq\"",
  },
  "Name",
  { accessor => "name", data_type => "varchar", is_nullable => 0, size => 255 },
  "Email",
  { accessor => "email", data_type => "varchar", is_nullable => 0, size => 255 },
  "PasswordSalt",
  { accessor => "password_salt", data_type => "bytea", is_nullable => 0 },
  "PasswordHash",
  { accessor => "password_hash", data_type => "bytea", is_nullable => 0 },
  "Status",
  {
    accessor => "status",
    data_type => "varchar",
    default_value => "Active",
    is_nullable => 0,
    size => 64,
  },
  "UserType",
  { accessor => "user_type", data_type => "usertype[]", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</Id>

=back

=cut

__PACKAGE__->set_primary_key("Id");

=head1 UNIQUE CONSTRAINTS

=head2 C<User_Email_key>

=over 4

=item * L</Email>

=back

=cut

__PACKAGE__->add_unique_constraint("User_Email_key", ["Email"]);

=head1 RELATIONS

=head2 user_roles

Type: has_many

Related object: L<PgLogTest::Schema::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "PgLogTest::Schema::Result::UserRole",
  { "foreign.UserId" => "self.Id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 roles

Type: many_to_many

Composing rels: L</user_roles> -> role

=cut

__PACKAGE__->many_to_many("roles", "user_roles", "role");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-08-18 17:42:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IA6y4v3vSEZUWqvtY68O5Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->load_components(qw/ PgLog /);
__PACKAGE__->add_columns(
	"+PasswordHash",
	{ pg_log_column => 0, },
	"+PasswordSalt",
	{ pg_log_column => 0, },
);
1;
