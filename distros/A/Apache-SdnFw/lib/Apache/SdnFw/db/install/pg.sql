CREATE USER sdnfw;
CREATE LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION pop_last(text) RETURNS text
    AS ' SELECT x.str[array_upper(x.str,1)] FROM (SELECT string_to_array($1,'','') as str) x; '
    LANGUAGE sql;

--DROP AGGREGATE concat(int4);
--DROP AGGREGATE concat(varchar);
--DROP AGGREGATE concat(float8);

CREATE OR REPLACE FUNCTION join_array(anyarray) RETURNS text
    AS ' SELECT array_to_string($1,'',''); '
    LANGUAGE sql;

CREATE AGGREGATE concat (
    BASETYPE = anyelement,
    SFUNC = array_append,
    STYPE = anyarray,
    FINALFUNC = join_array,
    INITCOND = '{}'
);

CREATE OR REPLACE FUNCTION sum_array(anyarray,anyelement) RETURNS anyarray
    AS ' SELECT array_append($1,COALESCE($1[array_upper($1,1)],0)+$2); '
    LANGUAGE sql;

--DROP AGGREGATE concat_sum(int4);
--DROP AGGREGATE concat_sum(varchar);
--DROP AGGREGATE concat_sum(float8);

CREATE AGGREGATE concat_sum (
    BASETYPE = anyelement,
    SFUNC = sum_array,
    STYPE = anyarray,
    FINALFUNC = join_array,
    INITCOND = '{}'
);

-------------------------------
-- EMPLOYEE
-------------------------------
CREATE TABLE employees (
	employee_id		serial primary key,
	login			varchar(255) unique not null,
	passwd			varchar(32) not null,
	name			varchar(255) not null,
	email			varchar(255),
	passwd_expire	timestamp,
	locked_out		boolean,
	remote_addr		inet,
	last_bad_pass	date,
	bad_pass_count	int4,
	cookie			varchar(32) unique,
	created_ts		timestamp not null default now(),
	expired_ts		timestamp);

GRANT INSERT,UPDATE,SELECT,DELETE ON employees TO sdnfw;
GRANT ALL ON employees_employee_id_seq TO sdnfw;

SELECT setval('employees_employee_id_seq',1000,'false');

CREATE TABLE employee_sessions (
	employee_id		int4 unique references employees,
	last_update_ts	timestamp not null default now(),
	data			text);
GRANT ALL ON employee_sessions TO sdnfw;

CREATE VIEW employees_v (employee_id, login, passwd, name, email) AS
SELECT employee_id, login, passwd, name, email
FROM employees
ORDER BY name;
GRANT ALL ON employees_v TO sdnfw;

CREATE VIEW employees_v_keyval (id, name) AS
SELECT employee_id, name
FROM employees
ORDER BY name;
GRANT ALL ON employees_v_keyval TO sdnfw;

-------------------------------
-- LOCATION
-------------------------------
CREATE TABLE locations (
	location_id		serial primary key,
	employee_id		int4 references employees,
	name			varchar(255) not null,
	b_address			varchar(255),
	b_address2		varchar(255),
	b_city			varchar(255),
	b_state			varchar(2),
	b_zipcode			varchar(12),
	s_address			varchar(255),
	s_address2		varchar(255),
	s_city			varchar(255),
	s_state			varchar(2),
	s_zipcode			varchar(12),
	phone			int8,
	fax				int8,
	email			varchar(255),
	website			varchar(255),
	created_ts		timestamp not null default now(),
	closed_ts		timestamp);
GRANT INSERT,UPDATE,SELECT ON locations TO sdnfw;
GRANT ALL ON locations_location_id_seq TO sdnfw;

SELECT setval('locations_location_id_seq',1000,'false');

CREATE VIEW locations_v (location_id, name,
	b_address, b_address2, b_city, b_state, b_zipcode, 
	s_address, s_address2, s_city, s_state, s_zipcode, 
	phone, fax, email, website) AS
SELECT location_id, name,
	b_address, b_address2, b_city, b_state, b_zipcode, 
	s_address, s_address2, s_city, s_state, s_zipcode, 
	phone, fax, email, website
FROM locations
ORDER BY name;
GRANT ALL ON locations_v TO sdnfw;

CREATE VIEW locations_v_keyval (id, name) AS
SELECT location_id, name
FROM locations
ORDER BY name;
GRANT ALL ON locations_v_keyval TO sdnfw;

-------------------------------
-- GROUP
-------------------------------
CREATE TABLE groups (
	group_id		serial primary key,
	name			varchar(255) not null,
	admin			boolean);
GRANT INSERT,UPDATE,SELECT ON groups TO sdnfw;
GRANT ALL ON groups_group_id_seq TO sdnfw;

SELECT setval('groups_group_id_seq',1000,'false');

INSERT INTO groups (name, admin) VALUES ('Admin', TRUE);

CREATE VIEW groups_v (group_id, name) AS
SELECT group_id, name
FROM groups;
GRANT ALL ON groups_v TO sdnfw;

-------------------------------
-- ACTION
-------------------------------
CREATE TABLE actions (
	action_id	serial primary key,
	name		varchar(255) not null,
	a_object	varchar(60) not null,
	a_function	varchar(60) not null);
CREATE UNIQUE INDEX actions_idx ON actions (a_object, a_function);
GRANT INSERT,UPDATE,SELECT ON actions TO sdnfw;
GRANT ALL ON actions_action_id_seq TO sdnfw;

SELECT setval('actions_action_id_seq',1000,'false');

INSERT INTO actions (name, a_object, a_function) VALUES
('Create Actions','action','create');

CREATE VIEW actions_v (action_id, name, a_object, a_function) AS
SELECT action_id, name, a_object, a_function
FROM actions;
GRANT ALL ON actions_v TO sdnfw;

-------------------------------
-- EMPLOYEE LOCATION
-------------------------------
CREATE TABLE employee_locations (
	employee_id		int4 not null references employees,
	location_id		int4 not null references locations);
CREATE UNIQUE INDEX employee_locations_idx ON employee_locations (employee_id, location_id);
GRANT ALL ON employee_locations TO sdnfw;
CREATE INDEX employee_locations_location_id ON employee_locations (location_id);
CREATE INDEX employee_locations_employee_id ON employee_locations (employee_id);

CREATE VIEW employee_locations_v (employee_id, location_id, 
	employee_name, location_name) AS
SELECT el.employee_id, el.location_id, e.name as employee_name,
	l.name as location_name
FROM employee_locations el
	JOIN employees e ON el.employee_id=e.employee_id
	JOIN locations l ON el.location_id=l.location_id
ORDER BY employee_name, location_name;
GRANT ALL ON employee_locations_v TO sdnfw;

CREATE VIEW employee_locations_v_employee (employee_id, location_id, 
	location_name, checked) AS
SELECT e.employee_id, l.location_id, l.name as location_name,
	CASE WHEN el.employee_id IS NOT NULL THEN TRUE ELSE FALSE END as checked
FROM employees e
	JOIN locations l ON COALESCE(l.closed_ts,now()) >= now()
	LEFT JOIN employee_locations el ON l.location_id=el.location_id
		AND e.employee_id=el.employee_id
ORDER BY location_name;
GRANT ALL ON employee_locations_v_employee TO sdnfw;

CREATE VIEW employee_locations_v_location (location_id, employee_id, 
	employee_name, checked) AS
SELECT l.location_id, e.employee_id, e.name as employee_name,
	CASE WHEN el.location_id IS NOT NULL THEN TRUE ELSE FALSE END as checked
FROM locations l
	JOIN employees e ON COALESCE(e.expired_ts,now()) >= now()
	LEFT JOIN employee_locations el ON l.location_id=el.location_id
		AND e.employee_id=el.employee_id
ORDER BY employee_name;
GRANT ALL ON employee_locations_v_location TO sdnfw;

-------------------------------
-- GROUP ACTION
-------------------------------
CREATE TABLE group_actions (
	group_id	int4 not null references groups,
	action_id	int4 not null references actions);
CREATE UNIQUE INDEX group_actions_idx ON group_actions (group_id, action_id);
GRANT ALL ON group_actions TO sdnfw;
CREATE INDEX group_actions_group_id ON group_actions (group_id);
CREATE INDEX group_actions_action_id ON group_actions (action_id);

INSERT INTO group_actions (group_id, action_id) VALUES (1000,1000);

CREATE VIEW group_actions_v (group_id, action_id, group_name, action_name) AS
SELECT ga.group_id, ga.action_id, g.name as group_name, a.name as action_name
FROM group_actions ga
	JOIN groups g ON ga.group_id=g.group_id
	JOIN actions a ON a.action_id=ga.action_id
ORDER BY group_name, action_name;
GRANT ALL ON group_actions_v TO sdnfw;

CREATE VIEW group_actions_v_group (group_id, action_id, action_name, checked) AS
SELECT g.group_id, a.action_id, a.name as action_name,
	CASE WHEN ga.group_id IS NOT NULL THEN TRUE ELSE FALSE END AS checked
FROM groups g
	JOIN actions a ON a.action_id>0
	LEFT JOIN group_actions ga ON a.action_id=ga.action_id
		AND g.group_id=ga.group_id
ORDER BY a.name;
GRANT ALL ON group_actions_v_group TO sdnfw;

CREATE VIEW group_actions_v_action (action_id, group_id, group_name, checked) AS
SELECT a.action_id, g.group_id, g.name as group_name,
	CASE WHEN ga.action_id IS NOT NULL THEN TRUE ELSE FALSE END AS checked
FROM actions a
	JOIN groups g ON g.group_id>0
	LEFT JOIN group_actions ga ON a.action_id=ga.action_id
		AND g.group_id=ga.group_id
ORDER BY g.name;
GRANT ALL ON group_actions_v_action TO sdnfw;

-------------------------------
-- EMPLOYEE GROUP
-------------------------------
CREATE TABLE employee_groups (
	employee_id		int4 not null references employees,
	group_id		int4 not null references groups);
CREATE UNIQUE INDEX employee_groups_idx ON employee_groups (employee_id, group_id);
GRANT ALL ON employee_groups TO sdnfw;
CREATE INDEX employee_groups_employee_id ON employee_groups (employee_id);
CREATE INDEX employee_groups_group_id ON employee_groups (group_id);

CREATE VIEW employees_v_login (employee_id, login, cookie, passwd, name, email,
	password_expired, locked_out, account_expired, groups, admin) AS
SELECT e.employee_id, e.login, e.cookie, e.passwd, e.name, e.email,
	CASE WHEN passwd_expire < now() THEN TRUE ELSE NULL END as password_expired,
	e.locked_out,
	CASE WHEN expired_ts < now() THEN TRUE ELSE NULL END as account_expired,
	concat(eg.group_id) as groups,
	CASE WHEN count(g.admin) > 0 THEN TRUE ELSE NULL END as admin
FROM employees e
	LEFT JOIN employee_groups eg ON e.employee_id=eg.employee_id
	LEFT JOIN groups g ON eg.group_id=g.group_id
GROUP BY 1,2,3,4,5,6,7,8,9;
GRANT ALL ON employees_v_login TO sdnfw;

CREATE VIEW employee_groups_v (employee_id, group_id,
	employee_name, group_name) AS
SELECT eg.employee_id, eg.group_id, 
	e.name as employee_name, g.name as group_name
FROM employee_groups eg
	JOIN employees e ON eg.employee_id=e.employee_id
	JOIN groups g ON eg.group_id=g.group_id
ORDER BY employee_name, group_name;
GRANT ALL ON employee_groups_v TO sdnfw;

CREATE VIEW employee_groups_v_employee (employee_id, group_id, group_name, checked) AS
SELECT e.employee_id, g.group_id, g.name as group_name,
	CASE WHEN eg.employee_id IS NOT NULL THEN TRUE ELSE FALSE END as checked
FROM employees e
	JOIN groups g ON g.group_id>0
	LEFT JOIN employee_groups eg ON e.employee_id=eg.employee_id
		AND eg.group_id=g.group_id
ORDER BY g.name;
GRANT ALL ON employee_groups_v_employee TO sdnfw;

CREATE VIEW employee_groups_v_group (group_id, employee_id, employee_name, checked) AS
SELECT g.group_id, e.employee_id, e.name as employee_name,
	CASE WHEN eg.group_id IS NOT NULL THEN TRUE ELSE FALSE END as checked
FROM groups g
	JOIN employees e ON COALESCE(e.expired_ts,now()) >= now()
	LEFT JOIN employee_groups eg ON e.employee_id=eg.employee_id
		AND eg.group_id=g.group_id
ORDER BY e.name;
GRANT ALL ON employee_groups_v_group TO sdnfw;

-------------------------------
-- COUNTRY
-------------------------------
CREATE TABLE countries (
	country		varchar(2) primary key,
	name		varchar(255) not null,
	sort_order	int4 not null default 99);
GRANT SELECT ON countries TO sdnfw;
INSERT INTO countries (country, name, sort_order) VALUES
('US','United States',1),
('CA','Canada',2);

-------------------------------
-- STATE
-------------------------------
CREATE TABLE states (
	state		varchar(2) primary key,
	country		varchar(2) not null references countries,
	name		varchar(255));
GRANT SELECT ON states TO sdnfw;
INSERT INTO states (state, country, name) VALUES
('AL','US','Alabama'),
('AK','US','Alaska'),
('AZ','US','Arizona'),
('AR','US','Arkansas'),
('CA','US','California'),
('CO','US','Colorado'),
('CT','US','Connecticut'),
('DE','US','Delaware'),
('DC','US','District of Columbia'),
('FL','US','Florida'),
('GA','US','Georgia'),
('HI','US','Hawaii'),
('ID','US','Idaho'),
('IL','US','Illinois'),
('IN','US','Indiana'),
('IA','US','Iowa'),
('KS','US','Kansas'),
('KY','US','Kentucky'),
('LA','US','Louisiana'),
('ME','US','Maine'),
('MD','US','Maryland'),
('MA','US','Massachusetts'),
('MI','US','Michigan'),
('MN','US','Minnesota'),
('MS','US','Mississippi'),
('MO','US','Missouri'),
('MT','US','Montana'),
('NE','US','Nebraska'),
('NV','US','Nevada'),
('NH','US','New Hampshire'),
('NJ','US','New Jersey'),
('NM','US','New Mexico'),
('NY','US','New York'),
('NC','US','North Carolina'),
('ND','US','North Dakota'),
('OH','US','Ohio'),
('OK','US','Oklahoma'),
('OR','US','Oregon'),
('PA','US','Pennsylvania'),
('PR','US','Puerto Rico'),
('RI','US','Rhode Island'),
('SC','US','South Carolina'),
('SD','US','South Dakota'),
('TN','US','Tennessee'),
('TX','US','Texas'),
('UT','US','Utah'),
('VT','US','Vermont'),
('VI','US','Virgin Islands'),
('VA','US','Virginia'),
('WA','US','Washington'),
('WV','US','West Virginia'),
('WI','US','Wisconsin'),
('WY','US','Wyoming'),
('AB','CA','Alberta'),
('BC','CA','British Columbia'),
('MB','CA','Manitoba'),
('NB','CA','New Brunswick'),
('NL','CA','Newfoundland And Labrador'),
('NS','CA','Nova Scotia'),
('NT','CA','Northwest Territories'),
('NU','CA','Nunavut'),
('ON','CA','Ontario'),
('PE','CA','Prince Edward Island'),
('QC','CA','Quebec'),
('SK','CA','Saskatchewan'),
('YT','CA','Yukon');

CREATE VIEW states_v (state, country, name, country_name, fullname, sort_order) AS
SELECT s.state, s.country, s.name, c.name as country_name,
	s.name || ', ' || s.country as fullname, c.sort_order
FROM states s
	JOIN countries c ON s.country=c.country
ORDER BY c.sort_order, s.name;
GRANT ALL ON states_v TO sdnfw;

-------------------------------
-- ZIPCODE
-------------------------------
CREATE TABLE zipcode_import_ca (
	zipcode	varchar(12) not null,
	latitude	numeric(12,6),
	longitude	numeric(12,6),
	state		varchar(2) not null,
	city		varchar(60));

CREATE TABLE zipcode_import_us (
	zipcode	varchar(12) not null,
	primary_rec	char(1),
	latitude	numeric(12,6),
	longitude	numeric(12,6),
	state		varchar(2) not null,
	city		varchar(60));

CREATE TABLE zipcodes (
	zipcode	varchar(12) not null primary key,
	latitude	numeric(12,6) not null,
	longitude	numeric(12,6) not null,
	state		varchar(2) not null references states,
	city		varchar(60) not null,
	county		varchar(60));
GRANT SELECT ON zipcodes TO sdnfw;

-------------------------------
-- NOTE
-------------------------------
CREATE TABLE notes (
	note_id			serial primary key,
	created_ts		timestamp not null default now(),
	employee_id		int4 references employees,
	ref				varchar(30) not null,
	ref_id			int4 not null,
	note_text		text not null);
CREATE INDEX notes_idx ON notes(ref, ref_id);
GRANT INSERT, SELECT ON notes TO sdnfw;
GRANT ALL ON notes_note_id_seq TO sdnfw;

CREATE VIEW notes_v (note_id, created_ts, employee_id, ref, ref_id, note_text,
	employee_name) AS
SELECT n.note_id, n.created_ts, n.employee_id, n.ref, n.ref_id, n.note_text,
	COALESCE(e.name,'system') as employee_name
FROM notes n
	LEFT JOIN employees e ON n.employee_id=e.employee_id
ORDER BY created_ts asc;
GRANT ALL ON notes_v TO sdnfw;

SELECT setval('notes_note_id_seq',1000,'false');
-------------------------------
-- LOG
-------------------------------
CREATE TABLE logs (
	created_ts		timestamp not null default now(),
	employee_id		int4 references employees,
	ref				varchar(30) not null,
	ref_id			int4 not null,
	log_msg			varchar(255) not null);
CREATE INDEX logs_idx ON logs(ref, ref_id);
GRANT INSERT, SELECT ON logs TO sdnfw;

CREATE VIEW logs_v (created_ts, employee_id, ref, ref_id, log_msg, employee_name) AS
SELECT l.created_ts, l.employee_id, l.ref, l.ref_id, l.log_msg, 
	COALESCE(e.name,'system') as employee_name
FROM logs l
	LEFT JOIN employees e ON l.employee_id=e.employee_id
ORDER BY created_ts asc;
GRANT ALL ON logs_v TO sdnfw;


-------------------------------
-- CUSTOMER
-------------------------------
CREATE TABLE customers (
	customer_id		serial primary key,
	email_phone		varchar(255) unique not null,
	customer_type	varchar(20) not null,
	is_customer		boolean,
	first_name		varchar(60),
	last_name		varchar(60),
	company			varchar(255),
	employee_id		int4 references employees,
	location_id		int4 references locations,
	created_ts		timestamp not null default now());
GRANT INSERT, UPDATE, SELECT ON customers TO sdnfw;
GRANT ALL ON customers_customer_id_seq TO sdnfw;
CREATE INDEX customers_employee_id ON customers (employee_id);
CREATE INDEX customers_created_ts ON customers (created_ts);

CREATE VIEW customers_v (customer_id, email_phone, customer_type, is_customer,
	first_name, last_name, company, employee_id, employee_name, location_id,
	location_name, created_ts) AS
SELECT c.customer_id, c.email_phone, c.customer_type, c.is_customer,
	c.first_name, c.last_name, c.company, c.employee_id, e.name as employee_name,
	c.location_id, l.name as location_name, c.created_ts
FROM customers c
	LEFT JOIN employees e ON c.employee_id=e.employee_id
	LEFT JOIN locations l ON c.location_id=l.location_id;
GRANT ALL ON customers_v TO sdnfw;

CREATE VIEW customers_v_keyval (id, name) AS
SELECT i.customer_id, 
	COALESCE(i.first_name || ' ' || i.last_name, 
		i.first_name, 
		i.last_name, 
		i.email_phone) as name
FROM customers i
ORDER BY name;
GRANT ALL ON customers_v_keyval TO sdnfw;

CREATE TABLE customer_addresses (
	customer_address_id	serial primary key,
	customer_id		int4 not null references customers,
	address_type	varchar(12) not null,
	address			varchar(255),
	address2		varchar(255),
	city			varchar(255),
	state			varchar(2),
	country			varchar(2),
	zipcode			varchar(12));
CREATE INDEX customer_addresses_customer_id ON customer_addresses (customer_id);
GRANT ALL ON customer_addresses TO sdnfw;
GRANT ALL ON customer_addresses_customer_address_id_seq TO sdnfw;

CREATE VIEW customer_addresses_v (customer_id, first_name, last_name, company, 
	address_type, address, address2, city, state, zipcode, customer_address_id,
	state_name, country, country_name) AS
SELECT a.customer_id, c.first_name, c.last_name, c.company, a.address_type,
	a.address, a.address2, a.city, a.state, a.zipcode, a.customer_address_id,
	s.name as state_name, COALESCE(a.country,s.country) as country, 
	COALESCE(acn.name,cn.name) as country_name
FROM customer_addresses a
	JOIN customers c ON a.customer_id=c.customer_id
	LEFT JOIN states s ON a.state=s.state
	LEFT JOIN countries cn ON s.country=cn.country
	LEFT JOIN countries acn ON a.country=acn.country;
GRANT ALL ON customer_addresses_v TO sdnfw;

CREATE TABLE customer_phones (
	customer_phone_id	serial primary key,
	customer_id		int4 not null references customers,
	phone_type		varchar(12) not null,
	phone_number	int8 not null,
	phone_extra		varchar(30));
CREATE INDEX customer_phones_customer_id ON customer_phones (customer_id);
CREATE INDEX customer_phones_phone_number ON customer_phones (phone_number);
GRANT ALL ON customer_phones TO sdnfw;
GRANT ALL ON customer_phones_customer_phone_id_seq TO sdnfw;

CREATE VIEW customer_phones_v (customer_id, first_name, last_name, company, 
	phone_number, phone_type, phone_extra, customer_phone_id) AS
SELECT p.customer_id, c.first_name, c.last_name, c.company, p.phone_number,
	p.phone_type, p.phone_extra, p.customer_phone_id
FROM customer_phones p
	JOIN customers c ON p.customer_id=c.customer_id;
GRANT ALL ON customer_phones_v TO sdnfw;

CREATE TABLE customer_emails (
	customer_email_id	serial primary key,
	customer_id		int4 not null references customers,
	email_type		varchar(12) not null,
	email			varchar(255) not null);
CREATE INDEX customer_emails_customer_id ON customer_emails (customer_id);
GRANT ALL ON customer_emails TO sdnfw;
GRANT ALL ON customer_emails_customer_email_id_seq TO sdnfw;

CREATE VIEW customer_emails_v (customer_id, first_name, last_name, company, 
	email, email_type, customer_email_id) AS
SELECT e.customer_id, c.first_name, c.last_name, c.company, e.email,
	e.email_type, e.customer_email_id
FROM customer_emails e
	JOIN customers c ON e.customer_id=c.customer_id;
GRANT ALL ON customer_emails_v TO sdnfw;

-------------------------------
-- EMPLOYEE SAVE TRIGGER
-------------------------------
CREATE OR REPLACE FUNCTION employee_save () RETURNS TRIGGER AS $$
BEGIN
	NEW.login := regexp_replace(lower(NEW.login),'[^a-z]','','g');
	IF TG_OP = 'UPDATE' THEN
		IF NEW.passwd != OLD.passwd THEN
			NEW.passwd := md5(NEW.login || NEW.passwd);
		END IF;
	ELSE
		NEW.passwd := md5(NEW.login || NEW.passwd);
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER employee_save BEFORE UPDATE OR INSERT 
ON employees FOR EACH ROW EXECUTE PROCEDURE employee_save();

-------------------------------
-- DISTANCE
-------------------------------
CREATE OR REPLACE FUNCTION distance (numeric(12,6), numeric(12,6), numeric(12,6), numeric(12,6))
RETURNS integer AS $$
BEGIN
	
	IF $1=$3 AND $2=$4 THEN
		RETURN 0;
	ELSE
		RETURN (3986 * acos(
			cos(radians($1))*cos(radians($3))*cos(radians($2)-radians($4))
			+ sin(radians($1))*sin(radians($3))))::int4;
	END IF;
END;
$$ LANGUAGE 'plpgsql';

CREATE TABLE database_releases (
	filename	varchar(255) unique not null,
	release_ts	timestamp not null default now());
