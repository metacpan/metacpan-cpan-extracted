
CREATE TABLE dbr_schemas (
  schema_id int(10) unsigned NOT NULL auto_increment,
  handle varchar(50) default NULL,
  display_name varchar(50) default NULL,
  PRIMARY KEY  (schema_id),
  UNIQUE KEY handle (handle)
) Engine=InnoDB;

CREATE TABLE dbr_instances (
  instance_id int(10) unsigned NOT NULL auto_increment,
  schema_id int(10)  NOT NULL,
  handle varchar(50) NOT NULL,
  class varchar(50) NOT NULL COMMENT 'query, master, etc...',
  dbname varchar(250),
  username varchar(250),
  password varchar(250),
  host varchar(250),
  dbfile varchar(250),
  module varchar(50) NOT NULL COMMENT 'Which DB Module to use',
  readonly boolean,
  PRIMARY KEY  (instance_id),
  KEY (schema_id)
) Engine=InnoDB;

CREATE TABLE dbr_tables (
  table_id int(10) unsigned NOT NULL auto_increment,
  schema_id int(10) unsigned NOT NULL,
  name varchar(250) NOT NULL,
  display_name varchar(250) default NULL,
  is_cachable tinyint(1) NOT NULL,
  PRIMARY KEY  (table_id),
  KEY (schema_id)
) Engine=InnoDB;

CREATE TABLE dbr_fields (
  field_id int(10) unsigned NOT NULL auto_increment,
  table_id int(10) unsigned NOT NULL,
  name varchar(250) NOT NULL,
  data_type tinyint(3) unsigned NOT NULL,
  is_nullable tinyint(1) default NULL,
  is_signed tinyint(1) default NULL,
  max_value int(10) unsigned NOT NULL,
  display_name varchar(250) default NULL,
  is_pkey tinyint(1) default '0',
  index_type tinyint(1) default NULL,
  trans_id tinyint(3) unsigned default NULL,
  regex varchar(250) default NULL,
  default_val varchar(250) default NULL,
  PRIMARY KEY  (field_id),
  KEY (table_id)
) Engine=InnoDB;

CREATE TABLE dbr_relationships (
  relationship_id INT PRIMARY KEY auto_increment,

  from_name varchar(45) NOT NULL COMMENT 'reverse name of this relationship',
  from_table_id int(10)  NOT NULL,
  from_field_id int(10) NOT NULL,
  
  to_name varchar(45) NOT NULL COMMENT 'forward name of this relationship',
  to_table_id int(10)  NOT NULL,
  to_field_id int(10) NOT NULL,

  type tinyint(3)  NOT NULL,
  KEY (from_table_id),
  KEY (to_table_id)
) Engine=InnoDB;

CREATE TABLE cache_scopes (
  scope_id int(10) unsigned NOT NULL auto_increment,
  digest char(32) default NULL,
  PRIMARY KEY  (scope_id),
  UNIQUE KEY (digest)
) Engine=InnoDB;

CREATE TABLE cache_fielduse (
  row_id   int(10) unsigned NOT NULL auto_increment,
  scope_id int(10) unsigned NOT NULL,
  field_id int(10) unsigned NOT NULL,
  PRIMARY KEY  (row_id),
  UNIQUE KEY (scope_id,field_id)
) Engine=InnoDB;

CREATE TABLE enum (
  enum_id int(10) unsigned NOT NULL auto_increment,
  handle varchar(250) default NULL COMMENT 'ideally a unique key',
  name varchar(250) default NULL,
  override_id int(10) unsigned default NULL,
  PRIMARY KEY  (enum_id),
  KEY handle (handle)
) Engine=InnoDB;

CREATE TABLE enum_legacy_map (
  row_id int(10) unsigned NOT NULL auto_increment,
  context varchar(250) default NULL,
  field varchar(250) default NULL,
  enum_id int(10) unsigned NOT NULL,
  sortval int(11) default NULL,
  PRIMARY KEY  (row_id)
) Engine=InnoDB;

CREATE TABLE enum_map (
  row_id int(10) unsigned NOT NULL auto_increment,
  field_id int(10) unsigned NOT NULL,
  enum_id int(10) unsigned NOT NULL,
  sortval int(11) default NULL,
  PRIMARY KEY (row_id),
  KEY (field_id)
) Engine=InnoDB;

