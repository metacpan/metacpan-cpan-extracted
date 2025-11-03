package Daje::Database::Model::Super::ToolsObjects;
use Mojo::Base 'Daje::Database::Model::Super::Common::Base', -base, -signatures, -async_await;;

has 'fields' => "tools_objects_pkey, editnum, insby, insdatetime, modby, moddatetime, tools_version_fkey, name, active, tools_object_types_fkey";
has 'primary_key_name' => "tools_objects_pkey";
has 'table_name' => "tools_objects";


sub load_tools_object_pkey($self, $tools_objects_pkey) {

    return $self->load_pk(
        $self->table_name, $self->fields(), $self->primary_key_name(), $tools_objects_pkey
    );
}

sub load_tools_objects_fkey($self, $tools_version_pkey) {

    return $self->load_fkey(
        $self->table_name, $self->fields(), "tools_version_fkey", $tools_version_pkey
    );
}

sub insert($self, $data) {
    my $result = $self->SUPER::insert($self->table_name, $data, $self->primary_key_name);
    return $result;
}


sub update($self, $data) {
    return $self->SUPER::update($self->table_name, $data, { $self->primary_key_name() => $data->{$self->primary_key_name()}});
}


1;