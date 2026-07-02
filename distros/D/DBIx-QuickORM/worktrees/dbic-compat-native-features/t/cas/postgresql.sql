CREATE TABLE example(
    id       SERIAL          NOT NULL PRIMARY KEY,
    name     VARCHAR(128)    NOT NULL,
    revision INTEGER         NOT NULL DEFAULT 0,
    data     TEXT,
    UNIQUE(name)
);
