CREATE TABLE example(
    id       INTEGER         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name     VARCHAR(128)    NOT NULL,
    revision INTEGER         NOT NULL DEFAULT 0,
    data     TEXT,
    UNIQUE(name)
);
