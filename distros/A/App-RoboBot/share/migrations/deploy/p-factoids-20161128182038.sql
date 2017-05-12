-- Deploy robobot:p-factoids-20161128182038 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.factoids (
    id          serial not null,
    network_id  integer not null references robobot.networks (id) on update cascade on delete cascade,
    name        text not null,
    factoid     text not null,
    terms       tsvector not null,
    created_by  integer not null references robobot.nicks (id) on update cascade on delete cascade,
    created_at  timestamp with time zone not null default now(),
    updated_by  integer references robobot.nicks (id) on update cascade on delete set null,
    updated_at  timestamp with time zone,

    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX ON robobot.factoids (network_id, lower(name));
CREATE INDEX ON robobot.factoids (lower(name));
CREATE INDEX ON robobot.factoids (created_by);
CREATE INDEX ON robobot.factoids (updated_by);

COMMIT;
