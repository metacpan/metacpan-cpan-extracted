CREATE SEQUENCE widgets_id_seq;

CREATE TABLE widgets(
    id      INTEGER         NOT NULL PRIMARY KEY DEFAULT nextval('widgets_id_seq'),
    name    VARCHAR(64)     NOT NULL,
    derived VARCHAR         GENERATED ALWAYS AS (LOWER(name)) VIRTUAL,

    UNIQUE(name)
);
