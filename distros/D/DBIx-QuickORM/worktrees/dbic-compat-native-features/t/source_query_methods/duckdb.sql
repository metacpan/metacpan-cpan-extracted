CREATE SEQUENCE users_id_seq;
CREATE SEQUENCE widgets_id_seq;

CREATE TABLE users(
    user_id INTEGER     NOT NULL PRIMARY KEY DEFAULT nextval('users_id_seq'),
    name    VARCHAR(32) NOT NULL,
    active  INTEGER     NOT NULL DEFAULT 0,
    org_id  INTEGER     NOT NULL DEFAULT 0
);

CREATE TABLE widgets(
    widget_id INTEGER     NOT NULL PRIMARY KEY DEFAULT nextval('widgets_id_seq'),
    name      VARCHAR(32) NOT NULL
);
