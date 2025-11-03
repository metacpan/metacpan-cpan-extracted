package Daje::Database::Model::Super::ToolsVersion;
use Mojo::Base 'Daje::Database::Model::Super::Common::Base', -base, -signatures, -async_await;;

use Data::Dumper;

has 'fields' => "tools_version_pkey, editnum, insby, insdatetime, modby, moddatetime, tools_projects_fkey, version, locked, name";
has 'primary_key_name' => "tools_version_pkey";
has 'table_name' => "tools_version";


sub insert($self, $data) {

    my $result = $self->SUPER::insert(
        $self->table_name, $data, $self->primary_key_name
    );
    return $result;
}

sub load_tools_version_fkey($self, $tools_projects_pkey) {

    return $self->load_fkey(
        $self->table_name, $self->fields(), "tools_projects_fkey", $tools_projects_pkey
    );
}
1;