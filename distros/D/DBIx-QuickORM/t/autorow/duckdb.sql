CREATE SEQUENCE foo_id_seq;
CREATE SEQUENCE baz_id_seq;

CREATE TABLE foo(
    foo_id      INTEGER     NOT NULL PRIMARY KEY DEFAULT nextval('foo_id_seq'),
    name        VARCHAR(32) NOT NULL
);

CREATE TABLE baz(
    baz_id      INTEGER     NOT NULL PRIMARY KEY DEFAULT nextval('baz_id_seq'),
    name        VARCHAR(32) NOT NULL,

    foo_id      INTEGER     DEFAULT NULL,
    bar_id      INTEGER     DEFAULT NULL,

    FOREIGN KEY(foo_id) REFERENCES foo(foo_id)
);
