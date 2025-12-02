package Daje::Plugin::Tools;
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use v5.42;


# NAME
# ====
#
# Daje::Plugin::Tools - Mojolicious Plugin
#
# SYNOPSIS
# ========
#
# Mojolicious
# ===========
#
#      $self->plugin('Tools');
#
# Mojolicious::Lite
# =================
#
#      plugin 'Tools';
#
# DESCRIPTION
# ===========
#
# Daje::Plugin::Tools is a Mojolicious plugin.
#
# METHODS
# =======
#
# Daje::Plugin::Tools inherits all methods from
# Mojolicious::Plugin and implements the following new ones.
#
# register
# ========
#  $plugin->register(Mojolicious->new);
#
# Register plugin in L<Mojolicious> application.
#
# SEE ALSO
# ========
#
# Mojolicious, Mojolicious::Guides, https://mojolicious.org.
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
# janeskil1525 E<lt>janeskil1525@gmail.com
#


our $VERSION = '0.21';

use Daje::Database::Model::ToolsProjects;
use Daje::Database::Helper::TreeList;
use Daje::Database::View::VToolsProjects;
use Daje::Database::View::VToolsVersion;
use Daje::Database::Model::ToolsVersion;
use Daje::Database::Model::ToolsObjectsTables;
use Daje::Database::Model::ToolsObjectsTablesDatatypes;
use Daje::Database::Model::ToolsObjects;
use Daje::Database::Model::ToolsObjectTypes;
use Daje::Database::Model::ToolsObjectIndex;
use Daje::Database::Model::ToolsObjectSQL;
use Daje::Database::Model::Super::ToolsParameters;
use Daje::Database::Model::ToolsParameterValues;
use Daje::Database::Model::ToolsObjectViews;
use Daje::Database::Helper::ParameterTreelist;

sub register ($self, $app, $config) {
    $app->log->debug("Daje::Plugin::Tools::register start");

    $app->helper(
        tools_projects => sub {
            state  $tools_projects = Daje::Database::Model::ToolsProjects->new(db => shift->pg->db)
        });
    $app->helper(
        tools_objects => sub {
            state  $tools_objects = Daje::Database::Model::ToolsObjects->new(db => shift->pg->db)
        });

    $app->helper(
        tools_helper_treelist => sub {
            state  $tools_helper_treelist = Daje::Database::Helper::TreeList->new(db => shift->pg->db)
        });

    $app->helper(
        tools_helper_parameter_treelist => sub {
            state  $tools_helper_parameter_treelist = Daje::Database::Helper::ParameterTreelist->new(db => shift->pg->db)
        });

    $app->helper(
        v_tools_projects => sub {
            state  $v_tools_projects = Daje::Database::View::VToolsProjects->new(db => shift->pg->db)
        });
    $app->helper(
        v_tools_versions => sub {
            state  $v_tools_versions = Daje::Database::View::VToolsVersion->new(db => shift->pg->db)
        });
    $app->helper(
        tools_versions => sub {
            state  $tools_versions = Daje::Database::Model::ToolsVersion->new(db => shift->pg->db)
        });
    $app->helper(
        tools_objects_tables => sub {
            state  $tools_objects_tables = Daje::Database::Model::ToolsObjectsTables->new(db => shift->pg->db)
        });

    $app->helper(
        tools_objects_tables_datatypes => sub {
            state  $tools_objects_tables_datatypes = Daje::Database::Model::ToolsObjectsTablesDatatypes->new(db => shift->pg->db)
        });

    $app->helper(
        tools_object_types => sub {
            state  $tools_objects_tables_datatypes =  Daje::Database::Model::ToolsObjectTypes->new(db => shift->pg->db)
        });

    $app->helper(
        tools_objects_index => sub {
            state  $tools_objects_index =  Daje::Database::Model::ToolsObjectIndex->new(db => shift->pg->db)
        });

    $app->helper(
        tools_objects_sql => sub {
            state  $tools_objects_sql =  Daje::Database::Model::ToolsObjectSQL->new(db => shift->pg->db)
        });

    $app->helper(
        tools_parameters => sub {
            state  $tools_parameters = Daje::Database::Model::Super::ToolsParameters->new(db => shift->pg->db)
        });

    $app->helper(
        tools_parameter_values => sub {
            state  $tools_parameter_values = Daje::Database::Model::ToolsParameterValues->new(db => shift->pg->db)
        });

    $app->helper(
        tools_objects_views => sub {
            state  $tools_objects_views = Daje::Database::Model::ToolsObjectViews->new(db => shift->pg->db)
        });

    my $r = $app->routes;
    $r->get('/tools/api/v1/projects')->to('ToolsProjects#load_projects');
    $r->get('/tools/api/v1/versions/')->to('ToolsVersions#load_versions_list');
    $r->get('/tools/api/v1/version/:tools_projects_pkey')->to('ToolsVersions#load_current_version');
    $r->get('/tools/api/v1/versions/:tools_version_pkey')->to('ToolsVersions#load_versions');
    $r->get('/tools/api/v1/treelist/:tools_projects_pkey')->to('ToolsTreelist#load_treelist');
    $r->get('/tools/api/v1/parameters/treelist/')->to('ToolsParameterTreelist#load_treelist');
    $r->get(
        '/tools/api/v1/parameters/value/:tools_projects_fkey/:tools_parameters_fkey'
    )->to(
        'ToolsParameterValues#load_parameter_value'
    );
    $r->get('/tools/api/v1/table/objects/:tools_objects_fkey')->to('ToolsTableObjects#load_table_objects');
    $r->get('/tools/api/v1/table/object/:tools_object_tables_pkey')->to('ToolsTableObjects#load_table_object');
    $r->get('/tools/api/v1/table/obj/datatypes/')->to('ToolsTableObjectDatatypes#load_table_object_datatypes');
    $r->get('/tools/api/v1/object/:tools_objects_pkey')->to('ToolsObjects#load_object');
    $r->get('/tools/api/v1/objects/types/')->to('ToolsObjectTypes#load_object_types');
    $r->get('/tools/api/v1/objects/index/:tools_object_index_pkey')->to('ToolsObjectIndex#load_object_index');
    $r->get('/tools/api/v1/objects/sql/:tools_object_sql_pkey')->to('ToolsObjectSQL#load_object_sql');
    $r->get('/tools/api/v1/objects/view/:tools_object_views_pkey')->to('ToolsObjectViews#load_object_view');
    $r->get('/tools/api/v1/objects/parameters/:tools_parameters_pkey')->to('ToolsParameters#load_parameter');
    $r->get('/tools/api/v1/objects/parameter/values/:tools_parameter_values_pkey')->to('ToolsParameterValues#load_parameter_value');

    $app->log->debug("route loading done");

    $app->log->debug("Daje::Plugin::Tools::register done");
}

1;

__DATA__

#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME


Daje::Plugin::Tools - Mojolicious Plugin



=head1 SYNOPSIS




=head1 DESCRIPTION


Daje::Plugin::Tools is a Mojolicious plugin.



=head1 REQUIRES

L<Daje::Database::Helper::ParameterTreelist> 

L<Daje::Database::Model::ToolsObjectViews> 

L<Daje::Database::Model::ToolsParameterValues> 

L<Daje::Database::Model::Super::ToolsParameters> 

L<Daje::Database::Model::ToolsObjectSQL> 

L<Daje::Database::Model::ToolsObjectIndex> 

L<Daje::Database::Model::ToolsObjectTypes> 

L<Daje::Database::Model::ToolsObjects> 

L<Daje::Database::Model::ToolsObjectsTablesDatatypes> 

L<Daje::Database::Model::ToolsObjectsTables> 

L<Daje::Database::Model::ToolsVersion> 

L<Daje::Database::View::VToolsVersion> 

L<Daje::Database::View::VToolsProjects> 

L<Daje::Database::Helper::TreeList> 

L<Daje::Database::Model::ToolsProjects> 

L<v5.42> 

L<Mojo::Base> 


=head1 METHODS


Daje::Plugin::Tools inherits all methods from
Mojolicious::Plugin and implements the following new ones.



=head1 Mojolicious


     $self->plugin('Tools');



=head1 Mojolicious::Lite


     plugin 'Tools';



=head1 register

 $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.



=head1 SEE ALSO


Mojolicious, Mojolicious::Guides, https://mojolicious.org.



=head1 AUTHOR


janeskil1525 E<lt>janeskil1525@gmail.com



=head1 LICENSE


Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=cut

