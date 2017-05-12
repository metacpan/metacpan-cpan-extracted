CREATE SEQUENCE migration_schema_log_seq;

CREATE TABLE migration_schema_log (
    id          INT NOT NULL DEFAULT NEXTVAL('migration_schema_log_seq'),
    schema_name VARCHAR(128) NOT NULL,
    event_time  TIMESTAMP WITH TIME ZONE NOT NULL,
    old_version REAL NOT NULL DEFAULT 0,
    new_version REAL NOT NULL,
    
    FOREIGN KEY (schema_name)
        REFERENCES  migration_schema_version (name)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE UNIQUE INDEX migration_schema_log_pkey ON migration_schema_log (id);
CREATE INDEX migration_schema_log_name ON migration_schema_log (schema_name);
