CREATE TABLE example(
    id      INTEGER         NOT NULL PRIMARY KEY AUTOINCREMENT,
    name    VARCHAR(128)    NOT NULL,
    data    JSON            DEFAULT NULL,

    UNIQUE(name)
);
