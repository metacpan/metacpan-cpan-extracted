-- Deploy robobot:p-achievements-20161128144040 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.achievements (
    id          serial not null,
    name        text not null,
    description text not null,
    query       text not null,
    created_by  integer not null references robobot.nicks (id) on update cascade on delete cascade,
    created_at  timestamp with time zone not null default now(),

    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX ON robobot.achievements (lower(name));
CREATE INDEX ON robobot.achievements (created_by);

CREATE TABLE robobot.achievement_nicks (
    achievement_id  integer not null references robobot.achievements (id) on update cascade on delete cascade,
    nick_id         integer not null references robobot.nicks (id) on update cascade on delete cascade,
    created_at      timestamp with time zone not null default now(),

    PRIMARY KEY (achievement_id, nick_id)
);
CREATE INDEX ON robobot.achievement_nicks (nick_id);

COMMIT;
