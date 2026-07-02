CREATE TABLE example(
    id       INTEGER         NOT NULL PRIMARY KEY AUTOINCREMENT,
    name     VARCHAR(128)    NOT NULL,
    revision INTEGER         NOT NULL DEFAULT 0,
    data     TEXT,
    UNIQUE(name)
);
