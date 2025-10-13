package Daje::Database::Helper::TreeList;
use Mojo::Base  -base, -signatures, -async_await;
use v5.40;

use Data::Dumper;

use Daje::Database::Model::ToolsProjects;
use Daje::Database::View::VToolsVersion;

has 'db';

async sub load_treelist($self, $tools_projects_pkey) {

    my $treelist;
    # my $project = $self->_load_project($tools_projects_pkey);
    # $self->_add_node($treelist, $project->{data}, 'tools_projects');

    my $versions = $self->_load_versions($tools_projects_pkey);

    my $length = scalar @{$versions->{data}};
    for (my $i = 0; $i < $length; $i++) {

        my $node = $self->_add_node($treelist, @{$versions->{data}}[$i], 'tools_version', 0);
        push (@{$treelist->{data}}, $node);

    }

    return $treelist;
}


sub _add_node($self, $treelist, $data, $type, $level) {

    my $res->{id} = $data->{tools_version_pkey} . "-" . $type;
    $res->{label} = $data->{name} ;
    $res->{data} = $data ;
    $res->{icon} = 'pi pi-fw pi-folder';
    $res->{children} = [];

    my $test = 1;
    return $res;
}

sub _load_versions($self, $tools_projects_pkey) {
    return Daje::Database::View::VToolsVersion->new(
        db => $self->db
    )->load_tools_version_fkey($tools_projects_pkey)
}

sub _load_project($self, $tools_projects_pkey) {

    return Daje::Database::Model::ToolsProjects->new(
        db => $self->db
    )->load_pkey(
        $tools_projects_pkey
    );
}
1;