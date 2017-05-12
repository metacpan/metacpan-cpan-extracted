CREATE TABLE migration_schema_log (
    id          INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    schema_name VARCHAR(128) NOT NULL,
    event_time  TIMESTAMP NOT NULL,
    old_version REAL NOT NULL DEFAULT 0,
    new_version REAL NOT NULL,
    
    INDEX       (schema_name),
    
    FOREIGN KEY (schema_name)
        REFERENCES  migration_schema_version (name)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

