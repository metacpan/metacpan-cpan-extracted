-- https://www.postgresql.org/docs/current/ddl-schemas.html
CREATE SCHEMA ${dbix_migration_managed_schema};

CREATE TABLE products (
   id SERIAL,
   name VARCHAR(100) NOT NULL,
   price NUMERIC(10,2) NOT NULL,
   PRIMARY KEY(id)
);
