-- Deploy robobot:p-voting-20161128224521 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.voting_polls (
    poll_id     serial not null,
    channel_id  integer not null references robobot.channels (id) on update cascade on delete cascade,
    name        text not null,
    can_writein boolean not null default false,
    created_by  integer not null references robobot.nicks (id) on update cascade on delete cascade,
    created_at  timestamp with time zone not null default now(),
    closed_at   timestamp with time zone,

    PRIMARY KEY (poll_id)
);
CREATE INDEX ON robobot.voting_polls (channel_id);
CREATE INDEX ON robobot.voting_polls (created_by);

CREATE TABLE robobot.voting_poll_choices (
    choice_id   serial not null,
    poll_id     integer not null references robobot.voting_polls (poll_id) on update cascade on delete cascade,
    name        text not null,
    is_writein  boolean not null default false,
    writein_by  integer references robobot.nicks (id) on update cascade on delete cascade,
    writein_at  timestamp with time zone,

    PRIMARY KEY (choice_id)
);
CREATE UNIQUE INDEX ON robobot.voting_poll_choices (poll_id, name);
CREATE INDEX ON robobot.voting_poll_choices (writein_by);

CREATE TABLE robobot.voting_votes (
    vote_id     serial not null,
    choice_id   integer not null references robobot.voting_poll_choices (choice_id) on update cascade on delete restrict,
    nick_id     integer not null references robobot.nicks (id) on update cascade on delete restrict,
    voted_at    timestamp with time zone not null default now(),

    PRIMARY KEY (vote_id)
);
CREATE INDEX ON robobot.voting_votes (choice_id);
CREATE INDEX ON robobot.voting_votes (nick_id);

COMMIT;
