-- Deploy robobot:p-logger-20161128205533 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.logger_log (
    id              serial not null,
    channel_id      integer not null references robobot.channels (id) on update cascade on delete cascade,
    nick_id         integer not null references robobot.nicks (id) on update cascade on delete cascade,
    message         text not null,
    has_expression  boolean not null default false,
    posted_at       timestamp with time zone not null default now(),

    PRIMARY KEY (id)
);
CREATE INDEX ON robobot.logger_log (channel_id, posted_at);
CREATE INDEX ON robobot.logger_log (nick_id, posted_at);

COMMIT;
