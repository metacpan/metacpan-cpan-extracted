-- Deploy robobot:p-markov-20161128212720 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.markov_phrases (
    id          serial not null,
    nick_id     integer not null references robobot.nicks (id) on update cascade on delete cascade,
    structure   text not null,
    phrase      text not null,
    used_count  integer not null default 1,
    created_at  timestamp with time zone not null default now(),
    updated_at  timestamp with time zone,

    PRIMARY KEY (id)
);
CREATE INDEX ON robobot.markov_phrases (nick_id);
CREATE INDEX ON robobot.markov_phrases (structure);

CREATE TABLE robobot.markov_sentence_forms (
    id              serial not null,
    nick_id         integer not null references robobot.nicks (id) on update cascade on delete cascade,
    structure       text not null,
    structure_jsonb jsonb,
    used_count      integer not null default 1,
    created_at      timestamp with time zone not null default now(),
    updated_at      timestamp with time zone,

    PRIMARY KEY (id)
);
CREATE INDEX ON robobot.markov_sentence_forms (nick_id);

CREATE TABLE robobot.markov_neighbors (
    phrase_id   integer not null references robobot.markov_phrases (id) on update cascade on delete cascade,
    neighbor_id integer not null references robobot.markov_phrases (id) on update cascade on delete cascade,
    occurrences integer not null default 1,
    created_at  timestamp with time zone not null default now(),
    updated_at  timestamp with time zone,

    PRIMARY KEY (phrase_id, neighbor_id)
);
CREATE INDEX ON robobot.markov_neighbors (neighbor_id);

COMMIT;
