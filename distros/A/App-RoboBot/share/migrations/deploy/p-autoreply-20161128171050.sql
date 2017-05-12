-- Deploy robobot:p-autoreply-20161128171050 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.autoreply_autoreplies (
    id          serial not null,
    channel_id  integer not null references robobot.channels (id) on update cascade on delete cascade,
    name        text not null,
    condition   text not null,
    response    text not null,
    created_by  integer not null references robobot.nicks (id) on update cascade on delete cascade,
    created_at  timestamp with time zone not null default now(),

    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX ON robobot.autoreply_autoreplies (channel_id, lower(name));
CREATE INDEX ON robobot.autoreply_autoreplies (channel_id);
CREATE INDEX ON robobot.autoreply_autoreplies (created_by);

COMMIT;
