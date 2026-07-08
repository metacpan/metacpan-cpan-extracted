CREATE TABLE users(
    user_id SERIAL      NOT NULL PRIMARY KEY,
    name    VARCHAR(32) NOT NULL,
    active  INTEGER     NOT NULL DEFAULT 0,
    org_id  INTEGER     NOT NULL DEFAULT 0
);

CREATE TABLE widgets(
    widget_id SERIAL      NOT NULL PRIMARY KEY,
    name      VARCHAR(32) NOT NULL
);
