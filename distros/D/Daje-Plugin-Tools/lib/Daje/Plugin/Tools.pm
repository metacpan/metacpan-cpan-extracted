package Daje::Plugin::Tools;
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use v5.40;


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


our $VERSION = '0.07';

use Daje::Database::Model::ToolsProjects;
use Daje::Database::Helper::TreeList;
use Daje::Database::View::VToolsProjects;
use Daje::Database::View::VToolsVersion;

sub register ($self, $app, $config) {
    $app->log->debug("Daje::Plugin::Tools::register start");

    $app->helper(
        tools_projects => sub {
            state  $tools_projects = Daje::Database::Model::ToolsProjects->new(db => shift->pg->db)
        });
    $app->helper(
        tools_helper_treelist => sub {
            state  $tools_helper_treelist = Daje::Database::Helper::TreeList->new(db => shift->pg->db)
        });

    $app->helper(
        v_tools_projects => sub {
            state  $v_tools_projects = Daje::Database::View::VToolsProjects->new(db => shift->pg->db)
        });
    $app->helper(
        v_tools_versions => sub {
            state  $v_tools_versions = Daje::Database::View::VToolsVersion->new(db => shift->pg->db)
        });


    ;
    my $r = $app->routes;
    $r->get('/tools/api/v1/projects')->to('ToolsProjects#load_projects');
    $r->put('/tools/api/v1/projects')->to('ToolsProjects#save_projects');
    $r->get('/tools/api/v1/treelist/:tools_projects_pkey')->to('ToolsTreelist#load_treelist');

    $app->log->debug("route loading done");
}

1;

__DATA__
@@ tools

-- 1 up

CREATE TABLE IF NOT EXISTS tools_projects
(
    tools_projects_pkey serial not null primary key,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    name varchar not null,
    state varchar not null
);

-- 1 down

-- 2 up
CREATE TABLE IF NOT EXISTS tools_version
(
    tools_version_pkey serial NOT NULL PRIMARY KEY,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    tools_projects_fkey BIGINT NOT NULL,
    version BIGINT NOT NULL DEFAULT 1,
    locked BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT tools_version_tools_projects_fkey FOREIGN KEY (tools_projects_fkey)
        REFERENCES tools_projects (tools_projects_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

CREATE UNIQUE INDEX IF NOT EXISTS tools_version_pkey_tools_projects_fkey
    ON tools_version (tools_projects_fkey, version);

CREATE TABLE IF NOT EXISTS tools_objects
(
    tools_objects_pkey serial NOT NULL PRIMARY KEY,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    tools_version_fkey bigint not null,
    type varchar NOT NULL DEFAULT 'Table',
    name varchar NOT NULL UNIQUE,
    active bigint NOT NULL DEFAULT 1,
    CONSTRAINT tools_objects_tools_version_fkey FOREIGN KEY (tools_version_fkey)
        REFERENCES tools_version (tools_version_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

CREATE TABLE IF NOT EXISTS tools_object_tables
(
    tools_object_tables_pkey serial NOT NULL PRIMARY KEY,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    tools_version_fkey bigint not null,
    tools_objects_fkey bigint not null,
    fieldname varchar not null,
    datatype varchar not null,
    length bigint not null default 0,
    scale bigint not null default 0,
    active bigint not null default 1,
    visible bigint not null default 0,
    CONSTRAINT tools_object_tables_tools_objects_fkey FOREIGN KEY (tools_objects_fkey)
        REFERENCES tools_objects (tools_objects_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE,
    CONSTRAINT tools_object_tables_tools_version_fkey FOREIGN KEY (tools_version_fkey)
        REFERENCES tools_version (tools_version_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

CREATE UNIQUE INDEX tools_object_tables_fieldbname_tools_objects_fkey
    ON tools_object_tables (tools_objects_fkey, fieldname);

-- 2 down

-- 3 up

ALTER TABLE tools_version
    ADD COLUMN name varchar NOT NULL DEFAULT '';

-- 3 down

-- 4 up
CREATE OR REPLACE VIEW v_tools_projects_workflow_fkey AS
    SELECT tools_projects.*, workflow_fkey FROM tools_projects JOIN workflow_connections
	    ON connector_fkey = tools_projects_pkey AND connector = 'tools_projects';


CREATE OR REPLACE VIEW v_tools_version_workflow_fkey AS
    SELECT tools_version.*, workflow_fkey FROM tools_version JOIN workflow_connections
	    ON tools_projects_fkey = connector_fkey AND connector = 'tools_projects';

-- 4 down

-- 5 up
CREATE OR REPLACE VIEW v_tools_objects_workflow_fkey AS
	select tools_objects.*, workflow_fkey from tools_objects JOIN tools_version
		ON tools_version_fkey = tools_version_pkey
		JOIN workflow_connections ON connector_fkey = tools_projects_fkey AND connector = 'tools_projects';

-- 5 down

#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME


Daje::Plugin::Tools - Mojolicious Plugin



=head1 SYNOPSIS




=head1 DESCRIPTION


Daje::Plugin::Tools is a Mojolicious plugin.



=head1 REQUIRES

L<v5.40> 

L<Mojo::Base> 


=head1 METHODS


Daje::Plugin::Tools inherits all methods from
Mojolicious::Plugin and implements the following new ones.



=head1 Mojolicious::Lite


     plugin 'Tools';



=head1 Mojolicious


     $self->plugin('Tools');



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

