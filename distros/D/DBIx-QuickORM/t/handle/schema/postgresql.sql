CREATE TABLE example(
    id      SERIAL          NOT NULL PRIMARY KEY,
    name    VARCHAR(128)    NOT NULL,
    xxx     VARCHAR(6)      NOT NULL DEFAULT 'booger',
    UNIQUE(name)
);
