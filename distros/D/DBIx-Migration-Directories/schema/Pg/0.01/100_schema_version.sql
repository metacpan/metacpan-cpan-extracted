CREATE TABLE migration_schema_version (
    name        VARCHAR(128) NOT NULL,
    version     REAL NOT NULL
);

CREATE UNIQUE INDEX migration_schema_version_pkey ON migration_schema_version (name);

