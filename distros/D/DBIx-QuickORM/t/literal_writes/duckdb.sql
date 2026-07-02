CREATE SEQUENCE widgets_id_seq;

CREATE TABLE widgets(
    widget_id   INTEGER     NOT NULL PRIMARY KEY DEFAULT nextval('widgets_id_seq'),
    n           INTEGER,
    ver         INTEGER     NOT NULL DEFAULT 0,
    stamp       INTEGER
);
