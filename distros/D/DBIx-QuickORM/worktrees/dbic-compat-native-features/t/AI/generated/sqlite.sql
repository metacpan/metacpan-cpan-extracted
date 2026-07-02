CREATE TABLE widgets(
    id      INTEGER         NOT NULL PRIMARY KEY AUTOINCREMENT,
    name    VARCHAR(64)     NOT NULL,
    derived TEXT            GENERATED ALWAYS AS (lower(name)) STORED,

    UNIQUE(name)
);
