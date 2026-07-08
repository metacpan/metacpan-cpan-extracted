CREATE SEQUENCE example_id_seq;

CREATE TABLE example(
    id      INTEGER         NOT NULL PRIMARY KEY DEFAULT nextval('example_id_seq'),
    name    VARCHAR(128)    NOT NULL,
    uuid    UUID            DEFAULT NULL,
    UNIQUE(name)
);
