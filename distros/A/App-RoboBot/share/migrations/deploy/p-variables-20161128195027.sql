-- Deploy robobot:p-variables-20161128195027 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.global_vars (
    id          serial not null,
    network_id  integer not null references robobot.networks (id) on update cascade on delete cascade,
    var_name    text not null,
    var_values  text[] not null,
    created_by  integer not null references robobot.nicks (id) on update cascade on delete cascade,
    created_at  timestamp with time zone not null default now(),
    updated_at  timestamp with time zone,

    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX ON robobot.global_vars (network_id, var_name);
CREATE INDEX ON robobot.global_vars (created_by);

COMMIT;
