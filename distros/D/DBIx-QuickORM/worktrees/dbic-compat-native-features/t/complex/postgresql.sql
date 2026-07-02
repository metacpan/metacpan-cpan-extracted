CREATE TABLE example(
    id      SERIAL          NOT NULL PRIMARY KEY,
    name    VARCHAR(128)    NOT NULL,
    uuid    UUID            DEFAULT NULL,
    data    JSONB           DEFAULT NULL,

    UNIQUE(name),
    UNIQUE(uuid)
);
