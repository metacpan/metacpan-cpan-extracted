package Daje::Database::Model::Super::ToolsObjectViews;
use Mojo::Base 'Daje::Database::Model::Super::Common::Base', -base, -signatures, -async_await;;

has 'fields' => "tools_object_views_pkey, editnum, insby, insdatetime, modby, moddatetime, tools_version_fkey, tools_objects_fkey, name, fields, conditions";
has 'primary_key_name' => "tools_object_views_pkey";
has 'table_name' => "tools_object_views";

async sub load_tools_object_views_pkey_p($self, $tools_object_view_pkey) {
    return $self->load_tools_object_views_pkey($tools_object_view_pkey)
}

sub load_tools_object_views_pkey($self, $tools_object_view_pkey) {
    return $self->load_pk(
        $self->table_name, $self->fields(), $self->primary_key_name(), $tools_object_view_pkey
    );
}

sub load_tools_objects_views_fkey($self, $foregin_key_name, $tools_objects_fkey) {
    return $self->load_fkey(
        $self->table_name, $self->fields(), $foregin_key_name, $tools_objects_fkey
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