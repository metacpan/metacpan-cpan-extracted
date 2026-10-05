-- One table holds waiting requests and opaque tokens. `hash` is the SHA-256 of
-- the device code or of the token; neither secret is ever stored.
-- Works as written on SQLite and PostgreSQL.
CREATE TABLE airlock (
  hash            VARCHAR(64)  NOT NULL PRIMARY KEY,
  kind            VARCHAR(16)  NOT NULL,
  user_code       VARCHAR(16)  UNIQUE,
  client_id       VARCHAR(255) NOT NULL,
  scope           TEXT         NOT NULL,
  state           VARCHAR(16)  NOT NULL,
  created         BIGINT       NOT NULL,
  expires         BIGINT       NOT NULL,
  poll_interval   INTEGER,
  last_poll       BIGINT,
  subject         VARCHAR(255),
  amr             VARCHAR(255),
  acr             VARCHAR(255),
  auth_time       BIGINT,
  approved        BIGINT,
  origin_ip       VARCHAR(64),
  origin_ua       VARCHAR(255),
  factor_failures INTEGER      NOT NULL DEFAULT 0
);

CREATE INDEX airlock_expires ON airlock (expires);
