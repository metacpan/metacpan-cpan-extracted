-- Put this first to make sure multiple statements are processed.
-- DuckDB has no AUTOINCREMENT; use sequences for the id columns.

CREATE SEQUENCE seq_quick_testx START 1;
CREATE TABLE quick_testx (
    test_id     INTEGER NOT NULL PRIMARY KEY DEFAULT nextval('seq_quick_testx'),
    test_val    TEXT
);

CREATE SEQUENCE seq_quick_test START 1;
CREATE TABLE quick_test (
    test_id     INTEGER NOT NULL PRIMARY KEY DEFAULT nextval('seq_quick_test'),
    test_val    TEXT
);
