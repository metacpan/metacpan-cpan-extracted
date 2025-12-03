package Daje::Database::Tools;
use Mojo::Base  -base;
use v5.42;

# NAME
# ====
#
# Daje::Database::Tools - Daje plugin tools database class
#
# SYNOPSIS
# ========
#          use Mojo::Pg::Migrations;
#
#          $migrations = $migrations->from_data('tools', 'Daje::Database::Tools');
#
#
# DESCRIPTION
# ===========
#
# Daje::Database::Tools contains the necessary migration
# scripts for Mojo::Pg::Migrations to create the
# database for Daje::Plugin::Tools
#
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

our $VERSION = '1';

1;

__DATA__

@@ tools

-- 1 up

CREATE TABLE IF NOT EXISTS tools_object_types
(
    tools_object_types_pkey serial NOT NULL,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    type_name character varying COLLATE pg_catalog."default" NOT NULL,
    type bigint NOT NULL DEFAULT 0,
    CONSTRAINT tools_object_types_pkey PRIMARY KEY (tools_object_types_pkey),
    CONSTRAINT tools_object_types_type_name_key UNIQUE (type_name)
);

CREATE TABLE IF NOT EXISTS tools_objects_tables_datatypes
(
    tools_objects_tables_datatypes_pkey serial NOT NULL,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    name character varying COLLATE pg_catalog."default" NOT NULL,
    length bigint NOT NULL DEFAULT 0,
    scale bigint NOT NULL DEFAULT 0,
    CONSTRAINT tools_objects_tables_datatypes_pkey PRIMARY KEY (tools_objects_tables_datatypes_pkey)
);

CREATE TABLE IF NOT EXISTS tools_projects
(
    tools_projects_pkey serial NOT NULL ,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    name character varying COLLATE pg_catalog."default" NOT NULL,
    state character varying COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT tools_projects_pkey PRIMARY KEY (tools_projects_pkey)
);

CREATE TABLE IF NOT EXISTS tools_version
(
    tools_version_pkey serial NOT NULL ,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    tools_projects_fkey bigint NOT NULL,
    version bigint NOT NULL DEFAULT 1,
    name character varying COLLATE pg_catalog."default" NOT NULL DEFAULT ''::character varying,
    locked boolean NOT NULL DEFAULT false,
    CONSTRAINT tools_version_pkey PRIMARY KEY (tools_version_pkey),
    CONSTRAINT tools_version_tools_projects_fkey FOREIGN KEY (tools_projects_fkey)
        REFERENCES tools_projects (tools_projects_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

CREATE UNIQUE INDEX IF NOT EXISTS tools_version_pkey_tools_projects_fkey
    ON tools_version USING btree
    (tools_projects_fkey ASC NULLS LAST, version ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True);

CREATE TABLE IF NOT EXISTS tools_objects
(
    tools_objects_pkey serial NOT NULL,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    tools_version_fkey bigint NOT NULL,
    name character varying COLLATE pg_catalog."default" NOT NULL,
    active boolean NOT NULL DEFAULT true,
    tools_object_types_fkey bigint NOT NULL DEFAULT 0,
    tools_projects_fkey bigint NOT NULL DEFAULT 0,
    CONSTRAINT tools_objects_pkey PRIMARY KEY (tools_objects_pkey),
    CONSTRAINT tools_objects_name_key UNIQUE (name),
    CONSTRAINT tools_objects_tools_object_types_fkey FOREIGN KEY (tools_object_types_fkey)
        REFERENCES tools_object_types (tools_object_types_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT tools_objects_tools_projects_fkey FOREIGN KEY (tools_projects_fkey)
        REFERENCES tools_projects (tools_projects_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT tools_objects_tools_version_fkey FOREIGN KEY (tools_version_fkey)
        REFERENCES tools_version (tools_version_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

CREATE TABLE IF NOT EXISTS tools_object_tables
(
    tools_object_tables_pkey serial NOT NULL,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    tools_version_fkey bigint NOT NULL,
    tools_objects_fkey bigint NOT NULL,
    fieldname character varying COLLATE pg_catalog."default" NOT NULL,
    length bigint NOT NULL DEFAULT 0,
    scale bigint NOT NULL DEFAULT 0,
    tools_objects_tables_datatypes_fkey bigint NOT NULL,
    active boolean NOT NULL DEFAULT true,
    visible boolean NOT NULL DEFAULT true,
    "notnull" boolean NOT NULL DEFAULT true,
    "default" character varying COLLATE pg_catalog."default" NOT NULL DEFAULT ''::character varying,
    foreign_key boolean NOT NULL DEFAULT false,
    CONSTRAINT tools_object_tables_pkey PRIMARY KEY (tools_object_tables_pkey),
    CONSTRAINT tools_object_tables_tools_objects_fkey FOREIGN KEY (tools_objects_fkey)
        REFERENCES tools_objects (tools_objects_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE,
    CONSTRAINT tools_object_tables_tools_objects_tables_datatypes_fkey FOREIGN KEY (tools_objects_tables_datatypes_fkey)
        REFERENCES tools_objects_tables_datatypes (tools_objects_tables_datatypes_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT tools_object_tables_tools_version_fkey FOREIGN KEY (tools_version_fkey)
        REFERENCES tools_version (tools_version_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

CREATE UNIQUE INDEX IF NOT EXISTS tools_object_tables_fieldbname_tools_objects_fkey
    ON tools_object_tables USING btree
    (tools_objects_fkey ASC NULLS LAST, fieldname COLLATE pg_catalog."default" ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True);

CREATE TABLE IF NOT EXISTS tools_parameter_groups
(
    tools_parameter_groups_pkey serial NOT NULL,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    parameter_group character varying COLLATE pg_catalog."default" NOT NULL DEFAULT ''::character varying,
    CONSTRAINT tools_parameter_groups_pkey PRIMARY KEY (tools_parameter_groups_pkey),
    CONSTRAINT tools_parameter_groups_parameter_group_key UNIQUE (parameter_group)
);

CREATE TABLE IF NOT EXISTS tools_parameters
(
    tools_parameters_pkey serial NOT NULL,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    tools_parameter_groups_fkey bigint NOT NULL,
    parameter character varying COLLATE pg_catalog."default" NOT NULL DEFAULT ''::character varying,
    CONSTRAINT tools_parameters_pkey PRIMARY KEY (tools_parameters_pkey),
    CONSTRAINT tools_parameters_parameter_key UNIQUE (parameter),
    CONSTRAINT tools_parameters_tools_parameter_groups_fkey FOREIGN KEY (tools_parameter_groups_fkey)
        REFERENCES tools_parameter_groups (tools_parameter_groups_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

CREATE TABLE IF NOT EXISTS tools_parameter_values
(
    tools_parameter_values_pkey serial NOT NULL,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    tools_parameters_fkey bigint NOT NULL,
    tools_projects_fkey bigint NOT NULL,
    "value" character varying COLLATE pg_catalog."default" NOT NULL DEFAULT ''::character varying,
    description character varying COLLATE pg_catalog."default" NOT NULL DEFAULT ''::character varying,
    active boolean NOT NULL DEFAULT false,
    CONSTRAINT tools_parameter_values_pkey PRIMARY KEY (tools_parameter_values_pkey),
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

CREATE TABLE IF NOT EXISTS tools_object_sql
(
    tools_object_sql_pkey serial NOT NULL,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    tools_version_fkey bigint NOT NULL,
    tools_objects_fkey bigint NOT NULL,
    name character varying COLLATE pg_catalog."default" NOT NULL DEFAULT ''::character varying,
    sql_string character varying COLLATE pg_catalog."default" NOT NULL DEFAULT ''::character varying,
    CONSTRAINT tools_object_sql_pkey PRIMARY KEY (tools_object_sql_pkey),
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

CREATE TABLE IF NOT EXISTS tools_object_index
(
    tools_object_index_pkey serial NOT NULL,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    tools_version_fkey bigint NOT NULL,
    tools_objects_fkey bigint NOT NULL,
    table_name character varying COLLATE pg_catalog."default" NOT NULL,
    fields character varying COLLATE pg_catalog."default" NOT NULL,
    index_unique boolean NOT NULL DEFAULT false,
    CONSTRAINT tools_object_index_pkey PRIMARY KEY (tools_object_index_pkey),
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

CREATE TABLE IF NOT EXISTS tools_object_views
(
    tools_object_views_pkey serial NOT NULL,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    tools_version_fkey bigint NOT NULL,
    tools_objects_fkey bigint NOT NULL,
    name character varying COLLATE pg_catalog."default" NOT NULL DEFAULT ''::character varying,
    fields character varying COLLATE pg_catalog."default" NOT NULL DEFAULT ''::character varying,
    conditions character varying COLLATE pg_catalog."default" NOT NULL DEFAULT ''::character varying,
    CONSTRAINT tools_object_views_pkey PRIMARY KEY (tools_object_views_pkey),
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

CREATE OR REPLACE VIEW v_tools_objects_tables_datatypes
 AS
 SELECT tools_object_tables.tools_object_tables_pkey,
    tools_object_tables.tools_version_fkey,
    tools_object_tables.tools_objects_fkey,
    tools_object_tables.fieldname,
    tools_object_tables.length,
    tools_object_tables.scale,
    tools_object_tables.tools_objects_tables_datatypes_fkey,
    tools_object_tables.active,
    tools_object_tables.visible,
    tools_objects_tables_datatypes.name AS datatype,
    tools_object_tables."notnull",
    tools_object_tables."default"
   FROM tools_object_tables
     JOIN tools_objects_tables_datatypes
     ON tools_object_tables.tools_objects_tables_datatypes_fkey = tools_objects_tables_datatypes.tools_objects_tables_datatypes_pkey;

CREATE OR REPLACE VIEW v_tools_objects_types
 AS
 SELECT tools_objects.name,
    tools_objects.active,
    tools_object_types.type,
    tools_objects.tools_version_fkey,
    tools_objects.tools_projects_fkey,
    tools_objects.tools_objects_pkey
   FROM tools_objects
     JOIN tools_object_types
     ON tools_object_types.tools_object_types_pkey = tools_objects.tools_object_types_fkey;

CREATE OR REPLACE VIEW v_tools_objects_workflow_fkey
 AS
 SELECT tools_objects.tools_objects_pkey,
    tools_objects.editnum,
    tools_objects.insby,
    tools_objects.insdatetime,
    tools_objects.modby,
    tools_objects.moddatetime,
    tools_objects.tools_version_fkey,
    tools_objects.name,
    tools_objects.active,
    tools_objects.tools_object_types_fkey,
    tools_objects.tools_projects_fkey,
    workflow_connections.workflow_fkey
   FROM tools_objects
     JOIN tools_version
     ON tools_objects.tools_version_fkey = tools_version.tools_version_pkey
     JOIN workflow_connections
     ON workflow_connections.connector_fkey = tools_objects.tools_projects_fkey
     AND workflow_connections.connector::text = 'tools_projects'::text;

CREATE OR REPLACE VIEW v_tools_parameter_values
 AS
 SELECT tools_parameter_values.tools_parameter_values_pkey,
    tools_parameter_groups.parameter_group,
    tools_parameters.parameter,
    tools_parameter_values.value,
    tools_parameter_values.description,
    tools_parameter_values.active,
    tools_parameter_values.tools_projects_fkey
   FROM tools_parameter_groups
     JOIN tools_parameters
     ON tools_parameters.tools_parameter_groups_fkey = tools_parameter_groups.tools_parameter_groups_pkey
     JOIN tools_parameter_values
     ON tools_parameter_values.tools_parameters_fkey = tools_parameters.tools_parameters_pkey;

CREATE OR REPLACE VIEW v_tools_projects_workflow_fkey
 AS
 SELECT tools_projects.tools_projects_pkey,
    tools_projects.editnum,
    tools_projects.insby,
    tools_projects.insdatetime,
    tools_projects.modby,
    tools_projects.moddatetime,
    tools_projects.name,
    tools_projects.state,
    workflow_connections.workflow_fkey
   FROM tools_projects
     JOIN workflow_connections
     ON workflow_connections.connector_fkey = tools_projects.tools_projects_pkey
     AND workflow_connections.connector::text = 'tools_projects'::text;

CREATE OR REPLACE VIEW v_tools_version_workflow_fkey
 AS
 SELECT tools_version.tools_version_pkey,
    tools_version.editnum,
    tools_version.insby,
    tools_version.insdatetime,
    tools_version.modby,
    tools_version.moddatetime,
    tools_version.tools_projects_fkey,
    tools_version.version,
    tools_version.name,
    tools_version.locked,
    workflow_connections.workflow_fkey
   FROM tools_version
     JOIN workflow_connections
     ON tools_version.tools_projects_fkey = workflow_connections.connector_fkey
     AND workflow_connections.connector::text = 'tools_projects'::text;

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


INSERT INTO tools_object_types (type_name, type) VALUES
    ('Table', 1),
    ('Index', 2),
    ('SQL', 3),
    ('View', 4);

INSERT INTO tools_parameter_groups (parameter_group) VALUES
    ('Project'),
    ('Sql'),
    ('Perl'),
    ('Angular');

INSERT INTO tools_parameters (parameter, tools_parameter_groups_fkey) VALUES
    ('Database Connection', (select tools_parameter_groups_pkey from tools_parameter_groups WHERE parameter_group = 'Project')),
    ('Output Path', (select tools_parameter_groups_pkey from tools_parameter_groups WHERE parameter_group = 'Sql')),
    ('Template Source', (select tools_parameter_groups_pkey from tools_parameter_groups WHERE parameter_group = 'Sql')),
    ('Output file name', (select tools_parameter_groups_pkey from tools_parameter_groups WHERE parameter_group = 'Sql')),
    ('Output Name Space', (select tools_parameter_groups_pkey from tools_parameter_groups WHERE parameter_group = 'Sql')),
    ('Base file path', (select tools_parameter_groups_pkey from tools_parameter_groups WHERE parameter_group = 'Perl')),
    ('Model file path', (select tools_parameter_groups_pkey from tools_parameter_groups WHERE parameter_group = 'Perl')),
    ('Path to app', (select tools_parameter_groups_pkey from tools_parameter_groups WHERE parameter_group = 'Angular'));


-- 1 down

#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME


Daje::Database::Tools - Daje plugin tools database class



=head1 SYNOPSIS

         use Mojo::Pg::Migrations;

         $migrations = $migrations->from_data('tools', 'Daje::Database::Tools');




=head1 DESCRIPTION


Daje::Database::Tools contains the necessary migration
scripts for Mojo::Pg::Migrations to create the
database for Daje::Plugin::Tools




=head1 REQUIRES

L<v5.42> 

L<Mojo::Base> 


=head1 METHODS


=head1 AUTHOR


janeskil1525 E<lt>janeskil1525@gmail.com



=head1 LICENSE


Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=cut

