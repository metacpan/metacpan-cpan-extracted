CREATE TABLE widgets(
    widget_id   INTEGER     NOT NULL PRIMARY KEY AUTO_INCREMENT,
    n           INTEGER,
    ver         INTEGER     NOT NULL DEFAULT 0,
    stamp       INTEGER
);
