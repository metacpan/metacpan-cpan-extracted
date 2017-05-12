package Schema::RBAC::Result::Permission;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components;

=head1 NAME

Schema::RBAC::Result::Permission

=cut

__PACKAGE__->table("permission");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 typeobject_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 obj_id

  data_type: 'integer'
  is_nullable: 0

=head2 role_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 operation_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'integer'
  is_nullable: 1

=head2 inheritable

  data_type: 'integer'
  is_nullable: 1


=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "role_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "typeobj_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "obj_id",
  { data_type => "integer", is_nullable => 0 },
  "operation_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "integer", is_nullable => 1 },
  "inheritable",
  { data_type => "integer", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( "object_role_operation_unique", ["typeobj_id", "obj_id", "role_id", "operation_id"]);

=head1 RELATIONS

=head2 typeobj

Type: belongs_to

Related typeobj: L<Schema::RBAC::Result::Typeobj>

=cut

__PACKAGE__->belongs_to(
  "typeobj",
  "Schema::RBAC::Result::Typeobj",
  { id => "typeobj_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 role

Type: belongs_to

Related role: L<Schema::RBAC::Result::Role>

=cut

__PACKAGE__->belongs_to(
  "role",
  "Schema::RBAC::Result::Role",
  { id => "role_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 operation

Type: belongs_to

Related object: L<Schema::RBAC::Result::Operation>

=cut

__PACKAGE__->belongs_to(
  "operation",
  "Schema::RBAC::Result::Operation",
  { id => "operation_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-02 18:58:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EaiSr/tH0ebsYXA8j3YawQ
#__PACKAGE__->resultset_class( 'DBIx::Class::ResultSet::HashRef' );


1;
