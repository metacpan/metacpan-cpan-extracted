package Daje::Database::Model::Super::ToolsObjectTypes;
use Mojo::Base 'Daje::Database::Model::Super::Common::Base', -base, -signatures, -async_await;;

has 'fields' => "tools_object_types_pkey, editnum, insby, insdatetime, modby, moddatetime, type_name, type";
has 'primary_key_name' => "tools_object_types_pkey";
has 'table_name' => "tools_object_types";


async sub load_full_list_p($self) {
    my $result = $self->load_a_full_list(
        $self->table_name,
        $self->fields
    );

    #say "Daje::Database::Model::Super::ToolsObjectTypes; " . Dumper($result);
    return $result;
}


1;