-- Deploy robobot:p-github-20161128190436 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.github_repos (
    repo_id     serial not null,
    owner_name  text not null,
    repo_name   text not null,
    last_pr     integer,
    last_issue  integer,
    created_at  timestamp with time zone not null default now(),
    polled_at   timestamp with time zone,

    PRIMARY KEY (repo_id)
);
CREATE UNIQUE INDEX ON robobot.github_repos (owner_name, repo_name);
CREATE INDEX ON robobot.github_repos (polled_at);

CREATE TABLE robobot.github_repo_channels (
    repo_id     integer not null references robobot.github_repos (repo_id) on update cascade on delete cascade,
    channel_id  integer not null references robobot.channels (id) on update cascade on delete cascade,

    PRIMARY KEY (repo_id, channel_id)
);
CREATE INDEX ON robobot.github_repo_channels (channel_id);

COMMIT;
