CREATE TABLE foo (
    foo_id  SERIAL      NOT NULL PRIMARY KEY,
    name    VARCHAR(20) NOT NULL,

    UNIQUE(name)
);

CREATE TABLE bar (
    bar_id  SERIAL      NOT NULL PRIMARY KEY,
    name    VARCHAR(20) NOT NULL,

    foo_id  INTEGER     DEFAULT NULL REFERENCES foo(foo_id),

    UNIQUE(name)
);

CREATE TABLE baz (
    baz_id  SERIAL      NOT NULL PRIMARY KEY,
    name    VARCHAR(20) NOT NULL,

    foo_id  INTEGER     DEFAULT NULL REFERENCES foo(foo_id),
    bar_id  INTEGER     DEFAULT NULL REFERENCES bar(bar_id),

    UNIQUE(name)
);
