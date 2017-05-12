-- Deploy robobot:p-fakequotes-20161128183237 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.fakequotes_people (
    id          serial not null,
    network_id  integer not null references robobot.networks (id) on update cascade on delete cascade,
    name        text not null,

    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX ON robobot.fakequotes_people (network_id, lower(name));

CREATE TABLE robobot.fakequotes_phrases (
    id          serial not null,
    person_id   integer not null references robobot.fakequotes_people (id) on update cascade on delete cascade,
    phrase      text not null,

    PRIMARY KEY (id)
);
CREATE INDEX ON robobot.fakequotes_phrases (person_id);

CREATE TABLE robobot.fakequotes_terms (
    id          serial not null,
    person_id   integer not null references robobot.fakequotes_people (id) on update cascade on delete cascade,
    term_type   text not null,
    term        text not null,

    PRIMARY KEY (id)
);
CREATE INDEX ON robobot.fakequotes_terms (person_id);
CREATE INDEX ON robobot.fakequotes_terms (lower(term_type));

COMMIT;
