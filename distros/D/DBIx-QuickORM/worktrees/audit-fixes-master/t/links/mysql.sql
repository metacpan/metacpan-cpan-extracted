CREATE TABLE foo (
    foo_id  INTEGER     NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name    VARCHAR(20) NOT NULL,

    UNIQUE(name)
);

CREATE TABLE has_foo (
    has_foo_id  INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
    foo_id      INTEGER,

    FOREIGN KEY(foo_id) REFERENCES foo(foo_id)
);
