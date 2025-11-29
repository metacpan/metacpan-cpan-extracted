package Daje::Workflow::Activities::Tools::Generate::Base;
use Mojo::Base 'Daje::Workflow::Common::Activity::Base', -base, -signatures;
use v5.42;

# NAME
# ====
#
# Daje::Workflow::Activities::Tools::Generate::Base - Base class fro generate activities
#
# SYNOPSIS
# ========
#
#     use Daje::Workflow::Activities::Tools::Generate::Base
#
# DESCRIPTION
# ===========
#
# Daje::Workflow::Activities::Tools::Generate::Base is a base class holding common methods
#
# LICENSE
# =======
#
# Copyright (C) janeskil1525.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# AUTHOR
# ======
#
# janeskil1525 E<lt>janeskil1525@gmail.comE<gt>
#

use Daje::Database::View::VToolsParameterValues;
use Daje::Database::Model::ToolsProjects;
use Daje::Database::View::VToolsVersion;
use Daje::Database::View::VToolsObjectsTypes;
use Daje::Database::View::VToolsObjectsTables;
use Daje::Database::Helper::LoadParameters;


has 'versions';
has 'tables';
has 'parameters';

sub get_parameter($self, $group, $parameter, $tools_projects_pkey) {
    my $param = Daje::Database::Helper::LoadParameters->new(
        db => $self->db
    );
    my $result = $param->load_parameter(
        $group, $parameter, $tools_projects_pkey
    );

    return $param->parameters->{value};
}

sub load_generate_data($self, $tools_projects_pkey) {
    my $versions;
    my $version;

    if ($self->load_versions($tools_projects_pkey)) {
        my $length = scalar @{$self->versions};
        for (my $i = 0; $i < $length; $i++) {
            my $data->{version} = @{$self->versions}[$i]->{version};
            if ($self->load_tables($tools_projects_pkey, @{$self->versions}[$i]->{tools_version_pkey})) {
                my $tables;
                my $len = scalar @{$self->tables};
                for (my $j = 0; $j < $len; $j++) {
                    my $table = $self->process_table(@{$self->tables}[$j], @{$self->versions}[$i]);
                    push @{$tables}, $table;
                }
                $data->{tables} = $tables;
            }
            push @{$version}, $data;
        }
        $versions->{versions} = $version;
        $versions->{project_name} = $self->load_project_name($tools_projects_pkey);
        $self->versions($versions);
    }
    return 1;
}

sub load_project_name($self,$tools_projects_pkey) {
    return Daje::Database::Model::ToolsProjects->new(
        db => $self->db
    )->load_pkey(
        $tools_projects_pkey
    )->{data}->{name};
}

sub process_table($self, $table, $tools_version) {
    my $fields = Daje::Database::View::VToolsObjectsTables->new(
        db => $self->db
    )->load_objects_tables(
        $table->{tools_objects_pkey}, $tools_version->{tools_version_pkey}
    );
    my $arr = [];
    my $fieldarray = $fields->{data};
    my $test = ref($fieldarray);
    if(ref($fieldarray) ne 'ARRAY') {
        $fieldarray->each(sub($e, $num) {
            push @{$arr}, $e;
        });
    }

    $table->{fields} = $arr;
    return $table;
}

sub load_tables($self, $tools_projects_pkey, $tools_version_pkey) {
    my $objects = Daje::Database::View::VToolsObjectsTypes->new(
        db => $self->db
    )->load_objects_type(
        1,$tools_projects_pkey,$tools_version_pkey
    );
    my $tables = $objects->{data};
    my $length = scalar @{$tables};
    for(my $i = 0; $i < $length; $i++) {
        @{$tables}[$i]->{table_name} = @{$tables}[$i]->{name};
        delete @{$tables}[$i]->{name};
    }
    $self->tables($tables);
    return $objects->{result};
}

sub load_versions($self, $tools_projects_pkey) {
    my $versions = Daje::Database::View::VToolsVersion->new(
        db => $self->db
    )->load_tools_version_fkey(
        $tools_projects_pkey
    );
    $self->versions($versions->{data});
    return $versions->{result};
}

1;