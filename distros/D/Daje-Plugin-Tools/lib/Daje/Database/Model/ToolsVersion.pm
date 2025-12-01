package Daje::Database::Model::ToolsVersion;
use Mojo::Base 'Daje::Database::Model::Super::ToolsVersion', -base, -signatures, -async_await;;


async sub load_current_version_p($self, $tools_projects_pkey) {
    return $self->load_from_index(
        $self->table_name(),
        $self->fields(),
        {
            tools_projects_fkey => $tools_projects_pkey,
            locked              => 0
        }
    );
}
1;

