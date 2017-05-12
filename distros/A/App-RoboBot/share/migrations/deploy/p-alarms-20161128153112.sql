-- Deploy robobot:p-alarms-20161128153112 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.alarms_alarms (
    id              serial not null,
    channel_id      integer not null references robobot.channels (id) on update cascade on delete cascade,
    name            text not null,
    next_emit       timestamp with time zone not null,
    recurrence      interval,
    exclusions      jsonb not null default '{}'::jsonb,
    is_expression   boolean not null default false,
    is_suspended    boolean not null default false,
    message         text,
    created_by      integer not null references robobot.nicks (id) on update cascade on delete cascade,
    created_at      timestamp with time zone not null default now(),

    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX ON robobot.alarms_alarms (channel_id, lower(name));
CREATE INDEX ON robobot.alarms_alarms (created_by);

COMMIT;
