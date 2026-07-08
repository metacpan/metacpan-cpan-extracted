CREATE TABLE widgets(
    widget_id   SERIAL      NOT NULL PRIMARY KEY,
    n           INTEGER,
    ver         INTEGER     NOT NULL DEFAULT 0,
    stamp       INTEGER
);
