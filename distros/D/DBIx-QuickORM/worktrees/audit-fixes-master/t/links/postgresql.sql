CREATE TABLE foo (
    foo_id  SERIAL      NOT NULL PRIMARY KEY,
    name    VARCHAR(20) NOT NULL,

    UNIQUE(name)
);

CREATE TABLE has_foo (
    has_foo_id  SERIAL  NOT NULL PRIMARY KEY,
    foo_id      INTEGER REFERENCES foo(foo_id)
);
