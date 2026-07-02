CREATE TABLE example(
    id      SERIAL          NOT NULL PRIMARY KEY,
    name    VARCHAR(128)    NOT NULL,
    data    JSON            DEFAULT NULL,

    UNIQUE(name)
);
