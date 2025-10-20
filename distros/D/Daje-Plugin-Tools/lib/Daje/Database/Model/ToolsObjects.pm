package Daje::Database::Model::ToolsObjects;
use Mojo::Base 'Daje::Database::Model::Super::ToolsObjects', -base, -signatures, -async_await;;


async sub load_tools_object_pkey_p($self, $tools_objects_pkey) {
    return $self->load_tools_object_pkey($tools_objects_pkey)
}
1;