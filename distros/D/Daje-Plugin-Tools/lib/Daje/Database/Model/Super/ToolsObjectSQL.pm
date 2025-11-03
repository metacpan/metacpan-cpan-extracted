package Daje::Database::Model::Super::ToolsObjectSQL;
use Mojo::Base 'Daje::Database::Model::Super::Common::Base', -base, -signatures, -async_await;;

has 'fields' => "tools_object_sql_pkey, editnum, insby, insdatetime, modby, moddatetime, tools_version_fkey, tools_objects_fkey, sql_string";
has 'primary_key_name' => "tools_object_sql_pkey";
has 'table_name' => "tools_object_sql";



async sub load_tools_object_sql_pkey_p($self, $tools_object_sql_pkey) {
    return $self->load_tools_object_pkey($tools_object_sql_pkey)
}

sub load_tools_object_sql_pkey($self, $tools_object_sql_pkey) {

    return $self->load_pk(
        $self->table_name, $self->fields(), $self->primary_key_name(), $tools_object_sql_pkey
    );
}

sub load_tools_objects_sql_fkey($self, $foregin_key_name, $tools_version_fkey) {

    return $self->load_fkey(
        $self->table_name, $self->fields(), $foregin_key_name, $tools_version_fkey
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