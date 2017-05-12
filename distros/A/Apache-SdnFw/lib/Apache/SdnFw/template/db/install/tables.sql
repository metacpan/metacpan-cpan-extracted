CREATE LANGUAGE 'plpgsql';

CREATE TABLE object_cats (
	object_cat_id	serial primary key,
	name			varchar(255) not null);
GRANT ALL ON object_cats TO sdnfw;
GRANT ALL ON object_cats_object_cat_id_seq TO sdnfw;

CREATE TABLE objects (
	code	varchar(255) unique not null,
	name	varchar(255) not null,
	tab_order	int4,
	tab_name	varchar(255),
	object_cat_id	int4 references object_cats,
	home		boolean);
GRANT ALL ON objects TO sdnfw;

CREATE TABLE employees (
	employee_id		serial primary key,
	login			varchar(255) unique not null,
	passwd			varchar(32) not null,
	name			varchar(255) not null,
	email			varchar(255),
	passwd_expire	timestamp,
	cookie			varchar(32) unique,
	created_ts		timestamp not null default now(),
	expired_ts		timestamp);

GRANT ALL ON employees TO sdnfw;
GRANT ALL ON employees_employee_id_seq TO sdnfw;

SELECT setval('employees_employee_id_seq',1000,'false');

CREATE TABLE employee_sessions (
	employee_id		int4 unique references employees,
	last_update_ts	timestamp not null default now(),
	data			text);
GRANT ALL ON employee_sessions TO sdnfw;

CREATE TABLE groups (
	group_id		serial primary key,
	name			varchar(255) not null,
	admin			boolean);
GRANT ALL ON groups TO sdnfw;
GRANT ALL ON groups_group_id_seq TO sdnfw;

SELECT setval('groups_group_id_seq',1000,'false');

INSERT INTO groups (name, admin) VALUES ('Admin', TRUE);

CREATE TABLE actions (
	action_id	serial primary key,
	name		varchar(255) not null,
	a_object	varchar(60) not null,
	a_function	varchar(60) not null);
CREATE UNIQUE INDEX actions_idx ON actions (a_object, a_function);
GRANT ALL ON actions TO sdnfw;
GRANT ALL ON actions_action_id_seq TO sdnfw;

SELECT setval('actions_action_id_seq',1000,'false');

INSERT INTO actions (name, a_object, a_function) VALUES
('Create Actions','action','create');

CREATE TABLE group_actions (
	group_id	int4 not null references groups,
	action_id	int4 not null references actions);
CREATE UNIQUE INDEX group_actions_idx ON group_actions (group_id, action_id);
GRANT ALL ON group_actions TO sdnfw;
CREATE INDEX group_actions_group_id ON group_actions (group_id);
CREATE INDEX group_actions_action_id ON group_actions (action_id);

INSERT INTO group_actions (group_id, action_id) VALUES (1000,1000);

CREATE TABLE employee_groups (
	employee_id		int4 not null references employees,
	group_id		int4 not null references groups);
CREATE UNIQUE INDEX employee_groups_idx ON employee_groups (employee_id, group_id);
GRANT ALL ON employee_groups TO sdnfw;
CREATE INDEX employee_groups_employee_id ON employee_groups (employee_id);
CREATE INDEX employee_groups_group_id ON employee_groups (group_id);

CREATE TABLE database_releases (
	filename	varchar(255) unique not null,
	release_ts	timestamp not null default now());
