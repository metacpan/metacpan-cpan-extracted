CREATE TABLE example(
    id      INTEGER         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name    VARCHAR(128)    NOT NULL,
    uuid    UUID            DEFAULT NULL,
    UNIQUE(name)
);
