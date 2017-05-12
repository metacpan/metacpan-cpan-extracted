-- Deploy robobot:p-channellink-20161128173743 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.channel_links (
    parent_channel_id   integer not null references robobot.channels (id) on update cascade on delete cascade,
    child_channel_id    integer not null references robobot.channels (id) on update cascade on delete cascade,
    created_by          integer not null references robobot.nicks (id) on update cascade on delete cascade,
    created_at          timestamp with time zone not null default now(),

    PRIMARY KEY (parent_channel_id, child_channel_id),

    CONSTRAINT "no same-channel linking" CHECK (parent_channel_id != child_channel_id)
);
CREATE INDEX ON robobot.channel_links (child_channel_id);
CREATE INDEX ON robobot.channel_links (created_by);

COMMIT;
