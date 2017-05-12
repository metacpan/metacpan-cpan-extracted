-- Deploy robobot:p-net-urls-20161128224203 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.urltitle_urls (
    url_id          serial not null,
    channel_id      integer not null references robobot.channels (id) on update cascade on delete cascade,
    nick_id         integer not null references robobot.nicks (id) on update cascade on delete cascade,
    title           text,
    original_url    text not null,
    final_url       text not null,
    linked_at       timestamp with time zone not null default now(),

    PRIMARY KEY (url_id)
);
CREATE INDEX ON robobot.urltitle_urls (channel_id);
CREATE INDEX ON robobot.urltitle_urls (nick_id);
CREATE INDEX ON robobot.urltitle_urls (original_url);
CREATE INDEX ON robobot.urltitle_urls (final_url);

COMMIT;
