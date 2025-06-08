CREATE TABLE foo (
    foo_id  INTEGER     NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name    VARCHAR(20) NOT NULL,

    UNIQUE(name)
);

CREATE TABLE bar (
    bar_id  INTEGER     NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name    VARCHAR(20) NOT NULL,

    foo_id  INTEGER     DEFAULT NULL,

    UNIQUE(name),

    FOREIGN KEY(foo_id) REFERENCES foo(foo_id)
);

CREATE TABLE baz (
    baz_id  INTEGER     NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name    VARCHAR(20) NOT NULL,

    foo_id  INTEGER     DEFAULT NULL,
    bar_id  INTEGER     DEFAULT NULL,

    UNIQUE(name),

    FOREIGN KEY(foo_id) REFERENCES foo(foo_id),
    FOREIGN KEY(bar_id) REFERENCES bar(bar_id)
);
