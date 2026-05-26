CREATE SEQUENCE foo_id_seq;
CREATE SEQUENCE bar_id_seq;
CREATE SEQUENCE baz_id_seq;

CREATE TABLE foo (
    foo_id  INTEGER     NOT NULL PRIMARY KEY DEFAULT nextval('foo_id_seq'),
    name    VARCHAR(20) NOT NULL,

    UNIQUE(name)
);

CREATE TABLE bar (
    bar_id  INTEGER     NOT NULL PRIMARY KEY DEFAULT nextval('bar_id_seq'),
    name    VARCHAR(20) NOT NULL,

    foo_id  INTEGER     DEFAULT NULL REFERENCES foo(foo_id),

    UNIQUE(name)
);

CREATE TABLE baz (
    baz_id  INTEGER     NOT NULL PRIMARY KEY DEFAULT nextval('baz_id_seq'),
    name    VARCHAR(20) NOT NULL,

    foo_id  INTEGER     DEFAULT NULL REFERENCES foo(foo_id),
    bar_id  INTEGER     DEFAULT NULL REFERENCES bar(bar_id),

    UNIQUE(name)
);
