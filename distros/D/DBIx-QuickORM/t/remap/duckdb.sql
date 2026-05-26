CREATE SEQUENCE example_id_seq;

CREATE TABLE example(
    id      INTEGER         NOT NULL PRIMARY KEY DEFAULT nextval('example_id_seq'),
    name    VARCHAR(128)    NOT NULL,
    uuid    BLOB            DEFAULT NULL,
    data    JSON            DEFAULT NULL,
    UNIQUE(name)
);
