-- Deploy robobot:p-skills-20161128215019 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.skills_skills (
    skill_id    serial not null,
    name        text not null,
    description text,
    created_by  integer references robobot.nicks (id) on update cascade on delete set null,
    created_at  timestamp with time zone not null default now(),

    PRIMARY KEY (skill_id)
);
CREATE UNIQUE INDEX ON robobot.skills_skills (lower(name));
CREATE INDEX ON robobot.skills_skills (created_by);

CREATE TABLE robobot.skills_levels (
    level_id    serial not null,
    name        text not null,
    description text,
    sort_order  integer not null default 0,

    PRIMARY KEY (level_id)
);
CREATE UNIQUE INDEX ON robobot.skills_levels (lower(name));
CREATE INDEX ON robobot.skills_levels (sort_order);

CREATE TABLE robobot.skills_related (
    skill_id    integer not null references robobot.skills_skills (skill_id) on update cascade on delete cascade,
    related_id  integer not null references robobot.skills_skills (skill_id) on update cascade on delete cascade,

    CONSTRAINT "no self-relations" CHECK (skill_id != related_id),

    PRIMARY KEY (skill_id, related_id)
);
CREATE INDEX ON robobot.skills_related (related_id);

CREATE TABLE robobot.skills_nicks (
    skill_id        integer not null references robobot.skills_skills (skill_id) on update cascade on delete cascade,
    nick_id         integer not null references robobot.nicks (id) on update cascade on delete cascade,
    skill_level_id  integer not null references robobot.skills_levels (level_id) on update cascade on delete cascade,

    PRIMARY KEY (skill_id, nick_id)
);
CREATE INDEX ON robobot.skills_nicks (nick_id);
CREATE INDEX ON robobot.skills_nicks (skill_level_id);

COMMIT;
