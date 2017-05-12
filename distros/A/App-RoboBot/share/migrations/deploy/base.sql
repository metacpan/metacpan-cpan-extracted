-- Deploy robobot:base to pg

BEGIN;

CREATE SCHEMA robobot AUTHORIZATION robobot;

CREATE TABLE robobot.nicks (
    id          serial not null,
    name        text not null,
    extradata   jsonb not null default '{}'::jsonb,
    created_at  timestamp with time zone not null default now(),
    updated_at  timestamp with time zone,

    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX ON robobot.nicks (lower(name));

CREATE TABLE robobot.networks (
    id          serial not null,
    name        text not null,
    created_at  timestamp with time zone not null default now(),
    updated_at  timestamp with time zone,

    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX ON robobot.networks (lower(name));

CREATE TABLE robobot.channels (
    id          serial not null,
    network_id  integer not null references robobot.networks (id) on update cascade on delete cascade,
    name        text not null,
    log_enabled boolean not null default true,
    extradata   jsonb not null default '{}'::jsonb,
    created_at  timestamp with time zone not null default now(),
    updated_at  timestamp with time zone,

    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX ON robobot.channels (network_id, lower(name));

COMMIT;
