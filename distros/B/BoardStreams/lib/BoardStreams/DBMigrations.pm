package BoardStreams::DBMigrations;

use Mojo::Base -strict, -signatures;

our $VERSION = "v0.0.22";

my $string = <<'SQL';
-- 1 up
CREATE TABLE IF NOT EXISTS "channel" (
    id          BIGSERIAL                   NOT NULL,
    name        VARCHAR(50)                 NOT NULL,
    type        VARCHAR(50)                 NOT NULL,
    event_id    BIGINT                      NOT NULL    DEFAULT 0,
    last_dt     TIMESTAMP WITH TIME ZONE    NOT NULL    DEFAULT CURRENT_TIMESTAMP,
    state       JSON                        NOT NULL,

    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX ON "channel"(name);
CREATE INDEX ON "channel"(type, last_dt);

CREATE TABLE IF NOT EXISTS "event_patch" (
    id          BIGSERIAL                   NOT NULL,
    channel_id  BIGINT                      NOT NULL,
    datetime    TIMESTAMP WITH TIME ZONE    NOT NULL    DEFAULT CURRENT_TIMESTAMP,
    event       JSON                        NOT NULL,

    PRIMARY KEY (id),

    CONSTRAINT fk_1
        FOREIGN KEY (channel_id)
        REFERENCES "channel"(id)
        ON DELETE CASCADE
);
CREATE INDEX ON "event_patch"(datetime);
CREATE INDEX ON "event_patch"(channel_id, datetime);
CREATE INDEX ON "event_patch"(channel_id, id);

CREATE TABLE IF NOT EXISTS "guards" (
    worker_uuid     VARCHAR(50)             NOT NULL,
    channel_id      BIGINT                  NOT NULL,
    counter         INTEGER                 NOT NULL,

    PRIMARY KEY (worker_uuid, channel_id),

    CONSTRAINT fk_2
        FOREIGN KEY (channel_id)
        REFERENCES "channel"(id)
        ON DELETE CASCADE
);

-- 1 down
DROP TABLE "guards";
DROP TABLE "event_patch";
DROP TABLE "channel";

-- 2 up
ALTER TABLE "channel" ADD COLUMN keep_events BOOLEAN NOT NULL DEFAULT true;

-- 2 down
ALTER TABLE "channel" DROP COLUMN keep_events;

SQL

sub apply_migrations ($class, $pg) {
    $pg->migrations
        ->name('boardstreams_library')
        ->from_string($string)
        ->migrate;
}

1;