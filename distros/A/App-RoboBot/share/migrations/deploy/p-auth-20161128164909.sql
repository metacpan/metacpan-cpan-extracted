-- Deploy robobot:p-auth-20161128164909 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.auth_permissions (
    permission_id   serial not null,
    network_id      integer not null references robobot.networks (id) on update cascade on delete cascade,
    nick_id         integer references robobot.nicks (id) on update cascade on delete cascade,
    command         text not null,
    state           text not null,
    granted_by      integer not null references robobot.nicks (id) on update cascade on delete restrict,
    created_at      timestamp with time zone not null default now(),
    updated_at      timestamp with time zone,

    PRIMARY KEY (permission_id)
);
CREATE UNIQUE INDEX ON robobot.auth_permissions (network_id, nick_id, lower(command));
CREATE INDEX ON robobot.auth_permissions (nick_id);
CREATE INDEX ON robobot.auth_permissions (lower(command));
CREATE INDEX ON robobot.auth_permissions (granted_by);

COMMIT;
