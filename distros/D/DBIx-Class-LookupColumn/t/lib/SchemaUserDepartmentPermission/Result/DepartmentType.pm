package SchemaUserDepartmentPermission::Result::DepartmentType;

use strict;
use warnings;
use base qw/DBIx::Class::Core/;


__PACKAGE__->table("departmentType");

__PACKAGE__->add_columns(
      "department_type_id",
      { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
      "name",
      { data_type => "varchar2", is_nullable => 0, size => 50 }

);

__PACKAGE__->set_primary_key("department_type_id");

__PACKAGE__->has_many( "departments" => "SchemaUserDepartmentPermission::Result::User", {"foreign.department_type_id" => "self.department_type_id"} );


1;
