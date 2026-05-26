CREATE SEQUENCE foo_id_seq;
CREATE SEQUENCE has_foo_id_seq;

CREATE TABLE foo (
    foo_id  INTEGER     NOT NULL PRIMARY KEY DEFAULT nextval('foo_id_seq'),
    name    VARCHAR(20) NOT NULL,

    UNIQUE(name)
);

CREATE TABLE has_foo (
    has_foo_id  INTEGER NOT NULL PRIMARY KEY DEFAULT nextval('has_foo_id_seq'),
    foo_id      INTEGER REFERENCES foo(foo_id)
);
