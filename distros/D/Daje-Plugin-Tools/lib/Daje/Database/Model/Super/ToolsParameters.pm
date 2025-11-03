package Daje::Database::Model::Super::ToolsParameters;
use Mojo::Base 'Daje::Database::Model::Super::Common::Base', -base, -signatures, -async_await;;

has 'fields' => "tools_parameters_pkey, editnum, insby, insdatetime, modby, moddatetime, tools_parameter_groups_fkey, parameter";
has 'primary_key_name' => "tools_parameters_pkey";
has 'table_name' => "tools_parameters";


async sub load_tools_parameters_pkey_p($self, $tools_parameters_pkey) {
    return $self->load_tools_parameters_pkey($self, $tools_parameters_pkey);
}

sub load_tools_parameters_pkey($self, $tools_parameters_pkey) {

    return $self->load_pk(
        $self->table_name, $self->fields(), $self->primary_key_name(), $tools_parameters_pkey
    );
}

sub load_tools_parameters_fkey($self, $tools_parameter_groups_pkey) {

    return $self->load_fkey(
        $self->table_name, $self->fields(), "tools_parameter_groups_fkey", $tools_parameter_groups_pkey
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