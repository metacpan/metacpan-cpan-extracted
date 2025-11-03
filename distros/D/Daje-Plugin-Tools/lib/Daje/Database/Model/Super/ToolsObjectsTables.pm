package Daje::Database::Model::Super::ToolsObjectsTables;
use Mojo::Base 'Daje::Database::Model::Super::Common::Base', -base, -signatures, -async_await;;
use v5.40;

has 'fields' => "tools_object_tables_pkey, editnum, insby, insdatetime, modby, moddatetime, tools_version_fkey, tools_objects_fkey, fieldname, tools_objects_tables_datatypes_fkey, length, scale, active, visible";
has 'primary_key_name' => "tools_object_tables_pkey";
has 'table_name' => "tools_object_tables";

use Data::Dumper;

async sub load_tools_objects_tables_pkey_p($self, $primary_key) {
    return $self->load_pk(
        $self->table_name(), $self->fields(), $self->primary_key_name(), $primary_key
    );
}

async sub load_tools_objects_tables_pkey($self, $primary_key) {
    return $self->load_pk(
        $self->table_name(), $self->fields(), $self->primary_key_name(), $primary_key
    );
}

async sub load_tools_objects_tables_fkey_p($self, $tools_objects_pkey) {

    return $self->load_fkey(
        $self->table_name, $self->fields(), "tools_objects_fkey", $tools_objects_pkey
    );
}

sub load_tools_objects_tables_fkey($self, $tools_objects_pkey) {

    return $self->load_fkey(
        $self->table_name, $self->fields(), "tools_objects_fkey", $tools_objects_pkey
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