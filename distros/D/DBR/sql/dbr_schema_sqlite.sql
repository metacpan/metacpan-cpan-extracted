

CREATE TABLE dbr_schemas (
  schema_id INTEGER PRIMARY KEY AUTOINCREMENT,
  handle varchar(50) default NULL,
  display_name varchar(50) default NULL
);

CREATE TABLE dbr_instances (
  instance_id INTEGER PRIMARY KEY AUTOINCREMENT,
  schema_id int(10)  NOT NULL,
  handle varchar(50) NOT NULL,
  class varchar(50) NOT NULL,
  dbname varchar(250),
  username varchar(250),
  password varchar(250),
  host varchar(250),
  dbfile varchar(250),
  module varchar(50) NOT NULL,
  readonly boolean
);
CREATE TABLE dbr_tables (
  table_id INTEGER PRIMARY KEY AUTOINCREMENT,
  schema_id int(10)  NOT NULL,
  name varchar(250) NOT NULL,
  display_name varchar(250) default NULL,
  is_cachable tinyint(1)
);

CREATE TABLE dbr_fields (
  field_id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_id int(10)  NOT NULL,
  name varchar(250) NOT NULL,
  data_type tinyint(3)  NOT NULL,
  is_nullable tinyint(1) default '0',
  is_signed tinyint(1) default '0',
  max_value int(10)  NOT NULL,
  display_name varchar(250) default NULL,
  is_pkey tinyint(1) default '0',
  index_type tinyint(1) default NULL,
  trans_id tinyint(3)  default NULL,
  regex varchar(250) default NULL,
  default_val varchar(250) default NULL
);

CREATE TABLE dbr_relationships (
  relationship_id INTEGER PRIMARY KEY AUTOINCREMENT,

  from_name varchar(45) NOT NULL ,
  from_table_id int(10)  NOT NULL,
  from_field_id int(10) NOT NULL,
  
  to_name varchar(45) NOT NULL,
  to_table_id int(10)  NOT NULL,
  to_field_id int(10) NOT NULL,

  type tinyint(3)  NOT NULL
);

CREATE TABLE cache_scopes (
  scope_id INTEGER PRIMARY KEY AUTOINCREMENT,
  digest char(32) default NULL
);
CREATE TABLE cache_fielduse (
  row_id INTEGER PRIMARY KEY AUTOINCREMENT,
  scope_id int(10)  NOT NULL,
  field_id int(10)  NOT NULL
);

CREATE TABLE enum (
  enum_id INTEGER PRIMARY KEY AUTOINCREMENT,
  handle varchar(250) default NULL ,
  name varchar(250) default NULL,
  override_id int(10)  default NULL
);
CREATE TABLE enum_legacy_map (
  row_id INTEGER PRIMARY KEY AUTOINCREMENT,
  context varchar(250) default NULL,
  field varchar(250) default NULL,
  enum_id int(10)  NOT NULL,
  sortval int(11) default NULL
);
CREATE TABLE enum_map (
  row_id INTEGER PRIMARY KEY AUTOINCREMENT,
  field_id int(10)  NOT NULL,
  enum_id int(10)  NOT NULL,
  sortval int(11) default NULL
);

CREATE INDEX enum_handle on enum (handle);
CREATE UNIQUE INDEX digest on cache_scopes (digest);
CREATE UNIQUE INDEX handle on dbr_schemas (handle);
CREATE UNIQUE INDEX scope_id on cache_fielduse (scope_id,field_id);

insert into dbr_schemas (handle,display_name) values ('example','Example Database');
insert into dbr_instances (schema_id,handle,class,dbfile,module) values (1,'example','master','support/example_db.sqlite','SQLite');
insert into dbr_instances (schema_id,handle,class,dbfile,module) values (1,'example','query', 'support/example_db.sqlite','SQLite');
