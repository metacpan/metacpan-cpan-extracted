package Daje::Database::Model::Super::ToolsObjectsTablesDatatypes;
use Mojo::Base 'Daje::Database::Model::Super::Common::Base', -base, -signatures, -async_await;;

has 'fields' => "tools_objects_tables_datatypes_pkey, editnum, insby, insdatetime, modby, moddatetime, name, length, scale";
has 'primary_key_name' => "tools_objects_tables_datatypes_pkey";
has 'table_name' => "tools_objects_tables_datatypes";



async sub load_tools_objects_tables_datatypes_p($self) {

    return $self->load_a_full_list (
        $self->table_name, $self->fields()
    );
}

1;