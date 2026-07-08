CREATE TABLE example(
    id      INTEGER         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name    VARCHAR(128)    NOT NULL,
    uuid    BINARY(16)      DEFAULT NULL,
    data    JSON            DEFAULT NULL,

    UNIQUE(name),
    UNIQUE(uuid)
);
