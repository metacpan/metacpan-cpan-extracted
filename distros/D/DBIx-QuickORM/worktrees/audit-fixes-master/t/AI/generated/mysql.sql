CREATE TABLE widgets(
    id      INTEGER         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name    VARCHAR(64)     NOT NULL,
    derived VARCHAR(64)     GENERATED ALWAYS AS (LOWER(name)) STORED,

    UNIQUE(name)
);
