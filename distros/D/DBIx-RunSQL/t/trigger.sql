-- This commented-out statement will not get passed through;
-- SECRET PRAGMA #foo will get passed through with the next statement
create table test (
    id integer unique not null,
    descr text default '',
    ts text
);

CREATE TRIGGER trg_test_1 AFTER INSERT ON test
     BEGIN
      UPDATE test SET ts = DATETIME('NOW')  WHERE rowid = new.rowid;
     END;

CREATE TRIGGER trg_test_2 AFTER INSERT ON test BEGIN
      UPDATE test SET ts = DATETIME('NOW')  WHERE rowid = new.rowid;
END;
