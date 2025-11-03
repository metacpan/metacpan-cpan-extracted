package Daje::Database::Helper::TreeList;
use Mojo::Base  -base, -signatures, -async_await;
use v5.42;

use Data::Dumper;
use Scalar::Util qw{ reftype };

use Daje::Database::Model::ToolsProjects;
use Daje::Database::View::VToolsVersion;
use Daje::Database::View::VToolsObjects;
use Daje::Database::Model::ToolsObjectsTables;
use Daje::Database::Model::ToolsObjectIndex;
use Daje::Database::Model::ToolsObjectSQL;
use Daje::Database::Model::ToolsObjectViews;

has 'db';

async sub load_treelist($self, $tools_projects_pkey) {

    my $treelist;
    my $objects = $self->_load_objects_from_project($tools_projects_pkey);
    my $length = scalar @{$objects->{data}};
    for (my $i = 0; $i < $length; $i++) {
       my $node = $self->_add_objects(
            @{$objects->{data}}[$i], 'tools_objects'
        );

        if(@{$objects->{data}}[$i]->{tools_object_types_fkey} == 1) {
            $node = $self->_add_tools_object_tables(
                $node, @{$objects->{data}}[$i]->{tools_objects_pkey}
            );
        } elsif (@{$objects->{data}}[$i]->{tools_object_types_fkey} == 2) {
            $node = $self->_add_tools_object_indexes(
                $node, @{$objects->{data}}[$i]->{tools_objects_pkey}
            );
        } elsif (@{$objects->{data}}[$i]->{tools_object_types_fkey} == 3) {
            $node = $self->_add_tools_object_sql(
                $node, @{$objects->{data}}[$i]->{tools_objects_pkey}
            );
        } elsif (@{$objects->{data}}[$i]->{tools_object_types_fkey} == 4) {
            $node = $self->_add_tools_object_views(
                $node, @{$objects->{data}}[$i]->{tools_objects_pkey}
            );
        }
        push (@{$treelist->{data}}, $node);
    }

    return $treelist;
}

sub _add_tools_object_views($self, $node, $tools_objects_fkey) {
    my $objects_view = $self->_load_tools_object_view($tools_objects_fkey);
    if($objects_view->{result} > 0) {
        my $length = scalar @{$objects_view->{data}};
        for (my $i = 0; $i < $length; $i++) {
            my $res->{id} = @{$objects_view->{data}}[$i]->{tools_object_view_pkey} . "-tools_object_view";
            $res->{label} = @{$objects_view->{data}}[$i]->{name};
            $res->{data} = @{$objects_view->{data}}[$i];
            $res->{icon} = 'pi pi-fw pi-folder';
            $res->{children} = [];
            push(@{$node->{children}}, $res);
        }
    }
}

sub _add_tools_object_sql($self, $node, $tools_objects_fkey) {
    my $objects_index = $self->_load_tools_object_sql($tools_objects_fkey);

    if($objects_index->{result} > 0) {
        my $length = scalar @{$objects_index->{data}};
        for (my $i = 0; $i < $length; $i++) {
            my $res->{id} = @{$objects_index->{data}}[$i]->{tools_object_sql_pkey} . "-tools_object_sql";
            $res->{label} = @{$objects_index->{data}}[$i]->{name};
            $res->{data} = @{$objects_index->{data}}[$i];
            $res->{icon} = 'pi pi-fw pi-folder';
            $res->{children} = [];
            push(@{$node->{children}}, $res);
        }
    }
    return $node;
}

sub _add_tools_object_indexes($self, $node, $tools_objects_fkey) {
    my $objects_index = $self->_load_tools_object_indexes($tools_objects_fkey);

    if($objects_index->{result} > 0) {
        my $length = scalar @{$objects_index->{data}};
        for (my $i = 0; $i < $length; $i++) {
            my $res->{id} = @{$objects_index->{data}}[$i]->{tools_object_index_pkey} . "-tools_object_index";
            $res->{label} = @{$objects_index->{data}}[$i]->{tablename};
            $res->{data} = @{$objects_index->{data}}[$i];
            $res->{icon} = 'pi pi-fw pi-folder';
            $res->{children} = [];
            push(@{$node->{children}}, $res);
        }
    }
    return $node;
}

sub _add_tools_object_tables($self, $node, $tools_objects_fkey) {
    my $objects_tables = $self->_load_tools_object_tables($tools_objects_fkey);

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
sub _load_tools_object_view($self, $tools_objects_fkey) {
    return Daje::Database::Model::ToolsObjectViews->new(
        db => $self->db
    )->load_tools_objects_views_fkey('tools_objects_fkey', $tools_objects_fkey);
}

sub _load_tools_object_sql($self, $tools_objects_fkey) {
    return Daje::Database::Model::ToolsObjectSQL->new(
        db => $self->db
    )->load_tools_objects_sql_fkey('tools_objects_fkey', $tools_objects_fkey);
}

sub _load_tools_object_indexes($self, $tools_objects_fkey) {
    return Daje::Database::Model::ToolsObjectIndex->new(
        db => $self->db
    )->load_tools_objects_index_fkey('tools_objects_fkey', $tools_objects_fkey);
}

sub _load_tools_object_tables($self, $tools_objects_fkey) {
    return Daje::Database::Model::ToolsObjectsTables->new(
        db => $self->db
    )->load_tools_objects_tables_fkey($tools_objects_fkey);
}

sub _load_objects_from_project($self, $tools_projects_pkey) {
    return Daje::Database::View::VToolsObjects->new(
        db => $self->db
    )->load_tools_objects_fkey('tools_projects_fkey', $tools_projects_pkey);
}

sub _load_objects($self, $tools_versions_pkey) {
    return Daje::Database::View::VToolsObjects->new(
        db => $self->db
    )->load_tools_objects_fkey('tools_versions_fkey', $tools_versions_pkey);
}

sub _add_objects($self, $data, $type ) {

    my $res->{id} = $data->{tools_objects_pkey} . "-" . $type;
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