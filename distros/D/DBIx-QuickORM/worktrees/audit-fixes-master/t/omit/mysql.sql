CREATE TABLE example(
    id      INTEGER         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name    VARCHAR(128)    NOT NULL,
    data    JSON            DEFAULT NULL,

    UNIQUE(name)
);
