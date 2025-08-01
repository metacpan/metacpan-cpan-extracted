CREATE TABLE example(
    id      INTEGER         NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name    VARCHAR(128)    NOT NULL,
    uuid    UUID            DEFAULT NULL,
    data    JSONB           DEFAULT NULL,

    UNIQUE(name),
    UNIQUE(uuid)
);
