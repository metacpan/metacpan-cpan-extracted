package SchemaLkpDetection::Result::User;

use strict;
use warnings;
use base qw/DBIx::Class::Core/;


__PACKAGE__->table("user");

__PACKAGE__->add_columns(
      "user_id",	{ data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
      "first_name",	{ data_type => "varchar2", is_nullable => 0, size => 45 },
      "last_name",	{ data_type => "varchar2", is_nullable => 0, size => 45 },
      "permission_type_id", { data_type => "integer", is_nullable => 0 },
      "department_type_id", { data_type => "integer", is_nullable => 0 }
);

__PACKAGE__->set_primary_key("user_id");

__PACKAGE__->belongs_to( "permissionType" => "SchemaLkpDetection::Result::PermissionType", {"foreign.permission_type_id" => "self.permission_type_id"} );
__PACKAGE__->belongs_to( "departmentType" => "SchemaLkpDetection::Result::DepartmentType", {"foreign.department_type_id" => "self.department_type_id"} );

__PACKAGE__->has_many( "studies" => "SchemaLkpDetection::Result::StudyType", {"foreign.user_id" => "self.user_id"} );


1;