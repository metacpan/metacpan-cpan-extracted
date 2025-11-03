package Daje::Database::Model::ToolsParameterValues;
use Mojo::Base 'Daje::Database::Model::Super::ToolsParameterValues', -base, -signatures, -async_await;;
use v5.42;


async sub load_tools_parameters_values_project_parameter_fkey($self, $tools_projects_fkey, $tools_parameters_fkey) {
    return $self->load_from_index(
        $self->table_name(), $self->fields(),
            {
                tools_projects_fkey   => $tools_projects_fkey,
                tools_parameters_fkey => $tools_parameters_fkey,
            }
    );
}


1;