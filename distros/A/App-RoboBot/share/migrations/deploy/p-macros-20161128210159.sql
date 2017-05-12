-- Deploy robobot:p-macros-20161128210159 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.macros (
    macro_id    serial not null,
    network_id  integer not null references robobot.networks (id) on update cascade on delete restrict,
    name        text not null,
    arguments   jsonb not null default '{}'::jsonb,
    definition  text not null,
    is_locked   boolean not null default false,
    defined_by  integer not null references robobot.nicks (id) on update cascade on delete restrict,
    defined_at  timestamp with time zone not null default now(),

    PRIMARY KEY (macro_id)
);
CREATE UNIQUE INDEX ON robobot.macros (network_id, lower(name));
CREATE INDEX ON robobot.macros (defined_by);

COMMIT;
