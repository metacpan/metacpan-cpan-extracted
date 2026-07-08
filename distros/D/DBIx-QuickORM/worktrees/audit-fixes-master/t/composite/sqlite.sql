CREATE TABLE example(
    id      INTEGER         NOT NULL PRIMARY KEY AUTOINCREMENT,
    name    VARCHAR(128)    NOT NULL,
    xxx     VARCHAR(6)      NOT NULL DEFAULT 'booger',
    UNIQUE(name)
);
