package Daje::Database::Helper::TreeList;
use Mojo::Base  -base, -signatures, -async_await;
use v5.40;

use Data::Dumper;
use Scalar::Util qw{ reftype };

use Daje::Database::Model::ToolsProjects;
use Daje::Database::View::VToolsVersion;
use Daje::Database::View::VToolsObjects;
use Daje::Database::Model::ToolsObjectsTables;

has 'db';

async sub load_treelist($self, $tools_projects_pkey) {

    my $treelist;
    # my $project = $self->_load_project($tools_projects_pkey);
    # $self->_add_node($treelist, $project->{data}, 'tools_projects');

    my $versions = $self->_load_versions($tools_projects_pkey);

    my $length = scalar @{$versions->{data}};
    for (my $i = 0; $i < $length; $i++) {

        my $node = $self->_add_version($treelist, @{$versions->{data}}[$i], 'tools_version', 0);
        $node = $self->_add_objects($node, @{$versions->{data}}[$i]->{tools_version_pkey});
        push (@{$treelist->{data}}, $node);

    }

    return $treelist;
}

sub _add_objects($self, $node, $tools_versions_pkey) {

    my $objects = $self->_load_objects($tools_versions_pkey);
    if($objects->{result} > 0) {
        my $length = scalar @{$objects->{data}};
        for (my $i = 0; $i < $length; $i++) {
            my $res->{id} = @{$objects->{data}}[$i]->{tools_objects_pkey} . "-tools_objects";
            $res->{label} = @{$objects->{data}}[$i]->{name};
            $res->{data} = @{$objects->{data}}[$i];
            $res->{icon} = 'pi pi-fw pi-folder';
            $res->{children} = [];
            $res = $self->_add_tools_object_tables($res, @{$objects->{data}}[$i]->{tools_objects_pkey});
            push(@{$node->{children}}, $res);
        }
    }

    return $node;
}

sub _add_tools_object_tables($self, $node, $tools_objects_fkey) {
    my $objects_tables = $self->_load_tools_object_tables($tools_objects_fkey);
    say "Daje::Database::Helper::TreeList::_add_tools_object_tables " . Dumper($objects_tables);
    if($objects_tables->{result} > 0) {
        my $length = scalar @{$objects_tables->{data}};
        for (my $i = 0; $i < $length; $i++) {
            my $res->{id} = @{$objects_tables->{data}}[$i]->{tools_object_tables_pkey} . "-tools_object_tables";
            $res->{label} = @{$objects_tables->{data}}[$i]->{fieldname};
            $res->{data} = @{$objects_tables->{data}}[$i];
            $res->{icon} = 'pi pi-fw pi-folder';
            $res->{children} = [];
            push(@{$node->{children}}, $res);
        }
    }
    return $node;
}

sub _load_tools_object_tables($self, $tools_objects_fkey) {
    return Daje::Database::Model::ToolsObjectsTables->new(
        db => $self->db
    )->load_tools_objects_tables_fkey($tools_objects_fkey);
}

sub _load_objects($self, $tools_versions_pkey) {
    return Daje::Database::View::VToolsObjects->new(
        db => $self->db
    )->load_tools_objects_fkey($tools_versions_pkey);
}

sub _add_version($self, $treelist, $data, $type, $level) {

    my $res->{id} = $data->{tools_version_pkey} . "-" . $type;
    $res->{label} = $data->{name} ;
    $res->{data} = $data ;
    $res->{icon} = 'pi pi-fw pi-folder';
    $res->{children} = [];


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