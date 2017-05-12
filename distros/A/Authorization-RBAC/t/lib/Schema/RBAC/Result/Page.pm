package Schema::RBAC::Result::Page;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components;

=head1 NAME

Schema::RBAC::Result::Page

=cut

__PACKAGE__->table("page");


=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 parent_id

  data_type: 'integer'
  is_nullable: 0
  default_value: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: undef

=head2 active

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0 },
  "parent_id",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "active",
  { data_type => "tinyint", default_value => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("name_parent_unique", ["name", "parent_id"]);

=head1 RELATIONS

=head2 parent

=cut

__PACKAGE__->belongs_to(
  "parent",
  "Schema::RBAC::Result::Page",
  { id => "parent_id" },
);


=head2 obj_operations

Type: has_many

Related object: L<Schema::RBAC::Result::ObjOperation>

=cut

__PACKAGE__->has_many(
  "obj_operations",
  "Schema::RBAC::Result::ObjOperation",
  { "foreign.obj_id"     => "self.id"} ,
  {  where => { typeobj_id => 1 }},
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ops_to_access

Type: many_to_many

=cut

__PACKAGE__->many_to_many( ops_to_access => 'obj_operations', 'operation',);



1;
