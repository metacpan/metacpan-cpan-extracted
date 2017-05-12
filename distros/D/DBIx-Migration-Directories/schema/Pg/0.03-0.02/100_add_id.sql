
CREATE SEQUENCE migration_schema_log_seq;

-- This will go on the end since postgres doesn't support column
-- re-ordering :-(

ALTER TABLE migration_schema_log 
  ADD id INT NOT NULL DEFAULT NEXTVAL('migration_schema_log_seq')
;


