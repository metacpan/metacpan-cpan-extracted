CREATE TABLE widgets(
    id      SERIAL          NOT NULL PRIMARY KEY,
    name    VARCHAR(64)     NOT NULL,
    derived TEXT            GENERATED ALWAYS AS (lower(name)) STORED,

    UNIQUE(name)
);
