package Schema::RBAC::Result::Role;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components;

=head1 NAME

Schema::RBAC::Result::Role

=cut

__PACKAGE__->table("role");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 active

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "active",
  { data_type => "tinyint", default_value => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("name", ["name"]);

=head1 RELATIONS

=head2 user_roles

Type: has_many

Related object: L<Schema::RBAC::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "Schema::RBAC::Result::UserRole",
  { "foreign.role_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-02 18:58:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:P4malBcvj08fykAzZ3RDlw

__PACKAGE__->many_to_many( users => 'user_roles', 'user');

sub permissions{
  my $self = shift;
  $self->allpermissions->search({ active => 1});
}

1;
