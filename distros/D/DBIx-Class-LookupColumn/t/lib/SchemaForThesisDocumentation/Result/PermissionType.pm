package SchemaForThesisDocumentation::Result::PermissionType;

use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table("permissionType");

__PACKAGE__->add_columns(
	"permission_type_id",
		{ data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
	"name",
		{ data_type => "varchar2", is_nullable => 0, size => 50 }
);

__PACKAGE__->set_primary_key("permission_type_id");

__PACKAGE__->has_many( "users", "SchemaForThesisDocumentation::Result::User", {"foreign.permission_type_id" => "self.permission_type_id"} );


1;
