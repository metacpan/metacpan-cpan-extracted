CREATE TABLE example(
    id      SERIAL          NOT NULL PRIMARY KEY,
    name    VARCHAR(128)    NOT NULL,
    data    JSONB           DEFAULT NULL,

    UNIQUE(name)
);
