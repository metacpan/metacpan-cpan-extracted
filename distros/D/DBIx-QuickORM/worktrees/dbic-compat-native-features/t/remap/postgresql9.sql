CREATE TABLE example(
    id      SERIAL          NOT NULL PRIMARY KEY,
    name    VARCHAR(128)    NOT NULL,
    uuid    BYTEA           DEFAULT NULL,
    data    JSON            DEFAULT NULL,
    UNIQUE(name)
);
