-- Deploy robobot:p-memos-20161128214110 to pg
-- requires: base

BEGIN;

CREATE TABLE robobot.memo_memos (
    memo_id         serial not null,
    from_nick_id    integer not null references robobot.nicks (id) on update cascade on delete cascade,
    to_nick_id      integer not null references robobot.nicks (id) on update cascade on delete cascade,
    message         text not null,
    created_at      timestamp with time zone not null default now(),
    delivered_at    timestamp with time zone,

    PRIMARY KEY (memo_id)
);
CREATE INDEX ON robobot.memo_memos (from_nick_id);
CREATE INDEX ON robobot.memo_memos (to_nick_id, delivered_at);
CREATE INDEX ON robobot.memo_memos (delivered_at);

COMMIT;
