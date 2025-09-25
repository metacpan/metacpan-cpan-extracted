package Daje::Database::Model::Super::ToolsObjects;
use Mojo::Base 'Daje::Database::Model::Super::Common::Base', -base, -signatures, -async_await;;

has 'fields' => "tools_objects_pkey, editnum, insby, insdatetime, modby, moddatetime, tools_version_fkey, name, type, active";
has 'primary_key_name' => "tools_objects_pkey";
has 'table_name' => "tools_objects";



sub load_tools_version_fkey($self, $tools_projects_pkey) {

    return $self->load_fkey(
        $self->table_name, $self->fields(), "tools_version_fkey", $tools_projects_pkey
    );
}

1;