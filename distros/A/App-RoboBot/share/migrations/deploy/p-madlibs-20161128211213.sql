-- Deploy robobot:p-madlibs-20161128211213 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.madlibs_madlibs (
    id              serial not null,
    madlib          text not null,
    placeholders    text[] not null,
    created_by      integer not null references robobot.nicks (id) on update cascade on delete restrict,
    created_at      timestamp with time zone not null default now(),

    PRIMARY KEY (id)
);
CREATE INDEX ON robobot.madlibs_madlibs (created_by);

CREATE TABLE robobot.madlibs_results (
    id              serial not null,
    madlib_id       integer not null references robobot.madlibs_madlibs (id) on update cascade on delete restrict,
    network_id      integer not null references robobot.networks (id) on update cascade on delete restrict,
    nick_id         integer not null references robobot.nicks (id) on update cascade on delete cascade,
    words           text[],
    filled_in       text,
    started_at      timestamp with time zone not null default now(),
    completed_at    timestamp with time zone,

    PRIMARY KEY (id)
);
CREATE INDEX ON robobot.madlibs_results (madlib_id);
CREATE INDEX ON robobot.madlibs_results (network_id, completed_at);
CREATE INDEX ON robobot.madlibs_results (nick_id);

COMMIT;
