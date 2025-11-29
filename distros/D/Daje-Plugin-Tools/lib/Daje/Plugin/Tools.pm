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


our $VERSION = '0.15';

use Daje::Database::Model::ToolsProjects;
use Daje::Database::Helper::TreeList;
use Daje::Database::View::VToolsProjects;
use Daje::Database::View::VToolsVersion;
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

-- 6 up

CREATE TABLE IF NOT EXISTS tools_objects_tables_datatypes
(
    tools_objects_tables_datatypes_pkey serial not null primary key,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    name varchar not null,
    length bigint NOT NULL DEFAULT 0,
    scale BIGINT NOT NULL DEFAULT 0
);

INSERT INTO tools_objects_tables_datatypes (name, length, scale) VALUES
    ('VARCHAR', 1, 0),
    ('BIGINT', 0, 0),
    ('NUMERIC', 1, 1),
    ('MONEY', 0, 0),
    ('BINARY', 0, 0),
    ('DATE', 0, 0),
    ('TIMESTAMP', 0, 0),
    ('BOOLEAN', 0, 0),
    ('UUID', 0, 0),
    ('JSON', 0, 0),
    ('XML', 0, 0);

ALTER TABLE tools_object_tables
    DROP COLUMN datatype;

ALTER TABLE tools_object_tables
    ADD COLUMN tools_objects_tables_datatypes_fkey BIGINT NOT NULL;

ALTER TABLE tools_object_tables
      ADD CONSTRAINT tools_object_tables_tools_objects_tables_datatypes_fkey FOREIGN KEY (tools_objects_tables_datatypes_fkey)
          REFERENCES tools_objects_tables_datatypes (tools_objects_tables_datatypes_pkey);

-- 6 down

-- 7 up

ALTER TABLE tools_object_tables DROP COLUMN active CASCADE;

ALTER TABLE tools_object_tables ADD COLUMN
    active boolean NOT NULL DEFAULT true;

ALTER TABLE tools_object_tables DROP COLUMN visible CASCADE;

ALTER TABLE tools_object_tables ADD COLUMN
    visible boolean NOT NULL DEFAULT true;

ALTER TABLE tools_objects DROP COLUMN active CASCADE;

ALTER TABLE tools_objects ADD COLUMN
    active boolean NOT NULL DEFAULT true;

ALTER TABLE tools_version DROP COLUMN locked CASCADE;

ALTER TABLE tools_version ADD COLUMN
    locked  boolean NOT NULL DEFAULT false;

CREATE OR REPLACE VIEW v_tools_projects_workflow_fkey AS
    SELECT tools_projects.*, workflow_fkey FROM tools_projects JOIN workflow_connections
	    ON connector_fkey = tools_projects_pkey AND connector = 'tools_projects';


CREATE OR REPLACE VIEW v_tools_version_workflow_fkey AS
    SELECT tools_version.*, workflow_fkey FROM tools_version JOIN workflow_connections
	    ON tools_projects_fkey = connector_fkey AND connector = 'tools_projects';

CREATE OR REPLACE VIEW v_tools_objects_workflow_fkey AS
	select tools_objects.*, workflow_fkey from tools_objects JOIN tools_version
		ON tools_version_fkey = tools_version_pkey
		JOIN workflow_connections ON connector_fkey = tools_projects_fkey AND connector = 'tools_projects';

-- 7 down

-- 8 up

CREATE TABLE IF NOT EXISTS tools_object_types
(
    tools_object_types_pkey serial not null primary key,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    type_name varchar not null UNIQUE,
    type bigint NOT NULL DEFAULT 0
);

INSERT INTO tools_object_types (type_name, type) VALUES
    ('Table', 1),
    ('Index', 2),
    ('SQL', 3),
    ('View', 4);

ALTER TABLE tools_objects
    ADD COLUMN tools_object_types_fkey BIGINT NOT NULL DEFAULT 0;

ALTER TABLE tools_objects
      ADD CONSTRAINT tools_objects_tools_object_types_fkey FOREIGN KEY (tools_object_types_fkey)
          REFERENCES tools_object_types (tools_object_types_pkey);

-- 8 down
-- 9 up

CREATE TABLE IF NOT EXISTS tools_object_index
(
    tools_object_index_pkey serial NOT NULL PRIMARY KEY,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    tools_version_fkey bigint not null,
    tools_objects_fkey bigint not null,
    table_name varchar not null,
    fields varchar not null,
    index_unique boolean not null default false,
    CONSTRAINT tools_object_index_tools_objects_fkey FOREIGN KEY (tools_objects_fkey)
        REFERENCES tools_objects (tools_objects_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE,
    CONSTRAINT tools_object_index_tools_version_fkey FOREIGN KEY (tools_version_fkey)
        REFERENCES tools_version (tools_version_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

CREATE TABLE IF NOT EXISTS tools_object_sql
(
    tools_object_sql_pkey serial NOT NULL PRIMARY KEY,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    tools_version_fkey bigint not null,
    tools_objects_fkey bigint not null,
    name varchar not null DEFAULT '',
    sql_string varchar not null DEFAULT '',
    CONSTRAINT tools_object_sql_tools_objects_fkey FOREIGN KEY (tools_objects_fkey)
        REFERENCES tools_objects (tools_objects_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE,
    CONSTRAINT tools_object_sql_tools_version_fkey FOREIGN KEY (tools_version_fkey)
        REFERENCES tools_version (tools_version_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

CREATE TABLE IF NOT EXISTS tools_parameters
(
    tools_parameters_pkey serial NOT NULL PRIMARY KEY,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    tools_projects_fkey BIGINT NOT NULL,
    parameter VARCHAR NOT NULL DEFAULT '',
    CONSTRAINT tools_parameters_tools_projects_fkey FOREIGN KEY (tools_projects_fkey)
        REFERENCES tools_projects (tools_projects_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

CREATE TABLE IF NOT EXISTS tools_parameter_values
(
    tools_parameter_values_pkey serial NOT NULL PRIMARY KEY,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    tools_parameters_fkey BIGINT NOT NULL,
    nane VARCHAR NOT NULL DEFAULT '',
    parameter_value VARCHAR NOT NULL DEFAULT '',
    CONSTRAINT tools_parameter_values_tools_parameters_fkey FOREIGN KEY (tools_parameters_fkey)
        REFERENCES tools_parameters (tools_parameters_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

-- 9 down
-- 10 up

DROP VIEW v_tools_objects_workflow_fkey;

ALTER TABLE tools_objects
    DROP COLUMN IF EXISTS type;

CREATE OR REPLACE VIEW v_tools_objects_workflow_fkey AS
	select tools_objects.*, workflow_fkey from tools_objects JOIN tools_version
		ON tools_version_fkey = tools_version_pkey
		JOIN workflow_connections ON connector_fkey = tools_version.tools_projects_fkey AND connector = 'tools_projects'
		ORDER BY tools_objects.tools_object_types_fkey;

ALTER TABLE tools_objects
    ADD COLUMN IF NOT EXISTS
        tools_projects_fkey BIGINT NOT NULL DEFAULT 0
    CONSTRAINT tools_objects_tools_projects_fkey
        REFERENCES tools_projects (tools_projects_pkey);

CREATE TABLE IF NOT EXISTS tools_object_views
(
    tools_object_views_pkey serial NOT NULL PRIMARY KEY,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    tools_version_fkey bigint not null,
    tools_objects_fkey bigint not null,
    name varchar not null DEFAULT '',
    fields varchar not null DEFAULT '',
    conditions varchar not null DEFAULT '',
    CONSTRAINT tools_object_views_tools_objects_fkey FOREIGN KEY (tools_objects_fkey)
        REFERENCES tools_objects (tools_objects_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE,
    CONSTRAINT tools_object_views_tools_version_fkey FOREIGN KEY (tools_version_fkey)
        REFERENCES tools_version (tools_version_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

-- 10 down
-- 11 up

CREATE TABLE IF NOT EXISTS tools_parameter_groups
(
    tools_parameter_groups_pkey serial NOT NULL PRIMARY KEY,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    parameter_group VARCHAR NOT NULL UNIQUE DEFAULT ''
);

INSERT INTO tools_parameter_groups (parameter_group) VALUES
    ('Project'),
    ('Sql'),
    ('Perl'),
    ('Angular');

CREATE TABLE IF NOT EXISTS tools_parameters
(
    tools_parameters_pkey serial NOT NULL PRIMARY KEY,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    tools_parameter_groups_fkey BIGINT NOT NULL,
    parameter VARCHAR NOT NULL UNIQUE DEFAULT '',
    CONSTRAINT tools_parameters_tools_parameter_groups_fkey FOREIGN KEY (tools_parameter_groups_fkey)
    REFERENCES tools_parameter_groups (tools_parameter_groups_pkey) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    DEFERRABLE
);

INSERT INTO tools_parameters (parameter, tools_parameter_groups_fkey) VALUES
    ('Database Connection', (select tools_parameter_groups_pkey from tools_parameter_groups WHERE parameter_group = 'Project')),
    ('Output Path', (select tools_parameter_groups_pkey from tools_parameter_groups WHERE parameter_group = 'Sql')),
    ('Template Source', (select tools_parameter_groups_pkey from tools_parameter_groups WHERE parameter_group = 'Sql')),
    ('Output file name', (select tools_parameter_groups_pkey from tools_parameter_groups WHERE parameter_group = 'Sql')),
    ('Output Name Space', (select tools_parameter_groups_pkey from tools_parameter_groups WHERE parameter_group = 'Sql')),
    ('Base file path', (select tools_parameter_groups_pkey from tools_parameter_groups WHERE parameter_group = 'Perl')),
    ('Model file path', (select tools_parameter_groups_pkey from tools_parameter_groups WHERE parameter_group = 'Perl')),
    ('Path to app', (select tools_parameter_groups_pkey from tools_parameter_groups WHERE parameter_group = 'Angular'));


CREATE TABLE IF NOT EXISTS tools_parameter_values
(
    tools_parameter_values_pkey serial NOT NULL PRIMARY KEY,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    tools_parameters_fkey BIGINT NOT NULL,
    tools_projects_fkey bigint NOT NULL,
    value VARCHAR NOT NULL UNIQUE DEFAULT '',
    description VARCHAR NOT NULL UNIQUE DEFAULT '',
    active boolean not null default false,
    CONSTRAINT tools_parameter_values_tools_parameters_fkey FOREIGN KEY (tools_parameters_fkey)
    REFERENCES tools_parameters (tools_parameters_pkey) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    DEFERRABLE,
    CONSTRAINT tools_parameter_values_tools_projects_fkey FOREIGN KEY (tools_projects_fkey)
    REFERENCES tools_projects (tools_projects_pkey) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    DEFERRABLE
);

-- 11 down
-- 12 up

ALTER TABLE tools_object_tables
    ADD COLUMN IF NOT EXISTS "notnull" BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS "default" VARCHAR NOT NULL DEFAULT '';

CREATE OR REPLACE VIEW v_tools_parameter_values AS
select tools_parameter_values_pkey, parameter_group, parameter, value, description, active, tools_projects_fkey  from tools_parameter_groups
	JOIN tools_parameters ON tools_parameter_groups_fkey = tools_parameter_groups_pkey
	JOIN tools_parameter_values ON tools_parameters_fkey = tools_parameters_pkey

CREATE OR REPLACE VIEW v_tools_objects_types AS
select tools_objects.name, active, type, tools_version_fkey, tools_projects_fkey, tools_objects_pkey  from tools_objects JOIN tools_object_types
	ON tools_object_types_pkey = tools_object_types_fkey

CREATE OR REPLACE VIEW v_tools_objects_tables_datatypes AS
	SELECT tools_object_tables_pkey, tools_version_fkey, tools_objects_fkey, fieldname, tools_object_tables.length, tools_object_tables.scale, tools_objects_tables_datatypes_fkey, active, visible, name as datatype, "notnull", "default"
		FROM tools_object_tables JOIN tools_objects_tables_datatypes
			ON tools_objects_tables_datatypes_fkey = tools_objects_tables_datatypes_pkey


-- 12 down
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

