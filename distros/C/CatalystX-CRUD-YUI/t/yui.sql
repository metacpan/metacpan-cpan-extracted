BEGIN TRANSACTION;
CREATE TABLE foos (
    id       integer primary key autoincrement,
    name     varchar(16),
    static   char(8),
    my_int   integer not null default 0,
    my_dec   float,
    my_bool  boolean not null default 't',
    ctime    datetime
    );
INSERT INTO "foos" VALUES(1, 'green', '12345678', 999, 12.34, 1, '1972-03-29 06:30:00');
INSERT INTO "foos" VALUES(2, 'yellow', '87654321', 888, 56.78, 0, '1984-03-29 06:30:00');
DELETE FROM sqlite_sequence;
INSERT INTO "sqlite_sequence" VALUES('foos', 2);
INSERT INTO "sqlite_sequence" VALUES('bars', 2);
INSERT INTO "sqlite_sequence" VALUES('goos', 2);
CREATE TABLE bars (
    id      integer primary key autoincrement,
    name    varchar(16),
    foo_id  integer not null references foo(id)
    );
INSERT INTO "bars" VALUES(1, 'red', 1);
INSERT INTO "bars" VALUES(2, 'purple', 2);
CREATE TABLE goos (
    id      integer primary key autoincrement,
    name    varchar(16)
    );
INSERT INTO "goos" VALUES(1, 'blue');
INSERT INTO "goos" VALUES(2, 'orange');
CREATE TABLE foo_goos (
    foo_id  integer not null references foo(id),
    goo_id  integer not null references goo(id)
    );
INSERT INTO "foo_goos" VALUES(1, 1);
INSERT INTO "foo_goos" VALUES(1, 2);
INSERT INTO "foo_goos" VALUES(2, 2);
INSERT INTO "foo_goos" VALUES(2, 1);
COMMIT;
