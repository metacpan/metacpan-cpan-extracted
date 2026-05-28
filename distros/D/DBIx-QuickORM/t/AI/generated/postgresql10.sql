-- PostgreSQL 10 does not support GENERATED ALWAYS AS ... STORED columns
-- (added in PG 12). This stub table lets the test framework load a schema;
-- the test detects the absent generated column and skips this version.
CREATE TABLE widgets(
    id      SERIAL          NOT NULL PRIMARY KEY,
    name    VARCHAR(64)     NOT NULL,

    UNIQUE(name)
);
