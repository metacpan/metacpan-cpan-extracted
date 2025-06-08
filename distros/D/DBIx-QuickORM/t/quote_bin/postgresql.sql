CREATE TABLE example(
    id      SERIAL          NOT NULL PRIMARY KEY,
    name    VARCHAR(128)    NOT NULL,
    uuid    BYTEA           DEFAULT NULL,
    UNIQUE(name)
);
