-- Deploy robobot:p-karma-20161128200656 to pg
-- requires: base

BEGIN;

CREATE TABLE karma_karma (
    id              serial not null,
    nick_id         integer not null references robobot.nicks (id) on update cascade on delete cascade,
    karma           integer not null,
    from_nick_id    integer not null references robobot.nicks (id) on update cascade on delete cascade,
    created_at      timestamp with time zone not null default now(),

    PRIMARY KEY (id)
);
CREATE INDEX ON robobot.karma_karma (nick_id);
CREATE INDEX ON robobot.karma_karma (from_nick_id);

COMMIT;
