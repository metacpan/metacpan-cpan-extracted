-- Deploy robobot:p-net-http-20161128214753 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.net_http_log (
    id          serial not null,
    scheme      text not null,
    host        text not null,
    path        text,
    created_at  timestamp with time zone not null default now(),

    PRIMARY KEY (id)
);
CREATE INDEX ON robobot.net_http_log (lower(host), created_at);

COMMIT;
