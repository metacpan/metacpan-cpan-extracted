package Daje::Database::Model::Super::ToolsProjects;
use Mojo::Base 'Daje::Database::Model::Super::Common::Base', -base, -signatures, -async_await;;

has 'fields' => "tools_projects_pkey, editnum, insby, insdatetime, modby, moddatetime, name, state";
has 'primary_key_name' => "tools_projects_pkey";
has 'table_name' => "tools_projects";


sub load_pkey($self, $tools_projects_pkey) {

    my $result = $self->load_pk(
        $self->table_name,
        $self->fields,
        $self->primary_key_name,
        $tools_projects_pkey
    );
    return $result;
}

async sub insert_tools_projects_p($self, $data) {
    my $result = $self->insert($self->table_name, $data, $self->primary_key_name);
    return $result;
}


async sub update_tools_projects_p($self, $data, $keys) {
    my $result = $self->update($self->table_name, $data, $keys);
    return $result;
}

sub insert_tools_projects($self, $data) {
    my $result = $self->insert($self->table_name, $data, $self->primary_key_name);
    return $result;
}


sub update_tools_projects($self, $data, $keys) {
    my $result = $self->update($self->table_name, $data, $keys);
    return $result;
}

sub load_list($self, $key_value) {
    my $result = $self->load_a_list(
        $self->table_name,
        $self->fields,
        $key_value
    );
    return $result;
}

async sub load_list_p($self, $key_value) {
    my $result = $self->load_a_list(
        $self->table_name,
        $self->fields,
        $key_value
    );
    return $result;
}

async sub load_full_list_p($self) {
    my $result = $self->load_a_full_list(
        $self->table_name,
        $self->fields
    );
    return $result;
}

1;