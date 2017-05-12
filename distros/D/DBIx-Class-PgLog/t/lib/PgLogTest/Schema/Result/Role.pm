use utf8;
package PgLogTest::Schema::Result::Role;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PgLogTest::Schema::Result::Role

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<Role>

=cut

__PACKAGE__->table("Role");

=head1 ACCESSORS

=head2 Id

  accessor: 'id'
  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: '"Role_Id_seq"'

=head2 Name

  accessor: 'name'
  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "Id",
  {
    accessor          => "id",
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "\"Role_Id_seq\"",
  },
  "Name",
  { accessor => "name", data_type => "varchar", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</Id>

=back

=cut

__PACKAGE__->set_primary_key("Id");

=head1 RELATIONS

=head2 user_roles

Type: has_many

Related object: L<PgLogTest::Schema::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "PgLogTest::Schema::Result::UserRole",
  { "foreign.RoleId" => "self.Id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 users

Type: many_to_many

Composing rels: L</user_roles> -> user

=cut

__PACKAGE__->many_to_many("users", "user_roles", "user");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-11 14:35:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8cemD6oPxi3NI/QyvOStew


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
