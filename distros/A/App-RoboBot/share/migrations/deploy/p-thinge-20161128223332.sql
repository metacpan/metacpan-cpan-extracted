-- Deploy robobot:p-thinge-20161128223332 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.thinge_types (
    id      serial not null,
    name    text not null,

    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX ON robobot.thinge_types (lower(name));

CREATE TABLE robobot.thinge_tags (
    id          serial not null,
    tag_name    text not null,

    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX ON robobot.thinge_tags (lower(tag_name));

CREATE TABLE robobot.thinge_thinges (
    id          serial not null,
    network_id  integer not null references robobot.networks (id) on update cascade on delete restrict,
    type_id     integer not null references robobot.thinge_types (id) on update cascade on delete restrict,
    thinge_num  integer not null,
    thinge_url  text not null,
    deleted     boolean not null default false,
    added_by    integer not null references robobot.nicks (id) on update cascade on delete restrict,
    added_at    timestamp with time zone not null default now(),

    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX ON robobot.thinge_thinges (network_id, type_id, thinge_num);
CREATE UNIQUE INDEX ON robobot.thinge_thinges (network_id, type_id, thinge_url);
CREATE INDEX ON robobot.thinge_thinges (type_id);
CREATE INDEX ON robobot.thinge_thinges (added_by);

CREATE TABLE robobot.thinge_thinge_tags (
    thinge_id   integer not null references robobot.thinge_thinges (id) on update cascade on delete cascade,
    tag_id      integer not null references robobot.thinge_tags (id) on update cascade on delete cascade,

    PRIMARY KEY (thinge_id, tag_id)
);
CREATE INDEX ON robobot.thinge_thinge_tags (tag_id);

COMMIT;
