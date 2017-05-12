CREATE TABLE migration_schema_version (
    name        VARCHAR(128) NOT NULL PRIMARY KEY,
    version     REAL NOT NULL
) ENGINE=InnoDB;
