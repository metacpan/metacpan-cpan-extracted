-- Deploy robobot:p-location-20161128204426 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.locations (
    location_id serial not null,
    network_id  integer not null references robobot.networks (id) on update cascade on delete cascade,
    nick_id     integer not null references robobot.nicks (id) on update cascade on delete cascade,
    loc_name    text not null,
    loc_message text,
    created_at  timestamp with time zone not null default now(),

    PRIMARY KEY (location_id)
);
CREATE INDEX ON robobot.locations (network_id);
CREATE INDEX ON robobot.locations (nick_id);
CREATE INDEX ON robobot.locations (created_at);

COMMIT;
