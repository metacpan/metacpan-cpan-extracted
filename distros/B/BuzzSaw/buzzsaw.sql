DROP TABLE log;
DROP TABLE event;
DROP TABLE tag;

CREATE DOMAIN BASE64 AS VARCHAR(200) CHECK( VALUE ~ '^[A-Za-z0-9+/:_.-]+$' );

CREATE DOMAIN HOSTNAME AS VARCHAR(100);

BEGIN;

CREATE TABLE log (
    id       SERIAL                        PRIMARY KEY,
    name     VARCHAR(200)                  NOT NULL,
    digest   BASE64                        NOT NULL,
    CONSTRAINT name_digest UNIQUE(name,digest)
);

CREATE INDEX log_name ON log (name);

CREATE TABLE current_processing (
    id        SERIAL                       PRIMARY KEY,
    name      VARCHAR(200)                 NOT NULL UNIQUE,
    starttime TIMESTAMP WITH TIME ZONE     NOT NULL DEFAULT current_timestamp
);

CREATE OR REPLACE FUNCTION register_current_processing(n current_processing.name%TYPE, d log.digest%TYPE, readall BOOLEAN) RETURNS void AS $$
DECLARE logcount INTEGER;
BEGIN

    LOCK TABLE current_processing IN ACCESS EXCLUSIVE MODE;

    -- If the mode is not set for reading all files then raise an
    -- error if we have already seen the file before.

    IF NOT readall THEN
      SELECT COUNT(*) INTO logcount
        FROM log
        WHERE digest = d;

      IF logcount > 0 THEN
        RAISE EXCEPTION 'Previously seen';
      END IF;
    END IF;

    -- Check if the file is currently being processed.

    -- Timeout any processing entries after 1 hour

    DELETE FROM current_processing
      WHERE starttime < current_timestamp - interval '1 hour';

    SELECT COUNT(*) INTO logcount
      FROM current_processing
      WHERE name = n;

    IF logcount > 0 THEN
      RAISE EXCEPTION 'Currently being processed';
    ELSE
      INSERT INTO current_processing (name) VALUES (n);
    END IF;

END;
$$  LANGUAGE plpgsql;

CREATE TABLE event (
    id       SERIAL                        PRIMARY KEY,
    raw      VARCHAR(1000)                 NOT NULL,
    digest   BASE64                        NOT NULL UNIQUE,
    logtime  TIMESTAMP WITH TIME ZONE      NOT NULL,
    logdate  DATE                          NOT NULL,
    hostname VARCHAR(100)                  NOT NULL,
    message  VARCHAR(1000)                 NOT NULL,
    program  VARCHAR(100),
    pid      INTEGER,
    userid   VARCHAR(20)
);

CREATE INDEX event_program_idx ON event(program);
CREATE INDEX event_userid_idx  ON event(userid);
CREATE INDEX event_logdate_idx ON event(logdate);
CREATE INDEX event_logtime_idx ON event(logtime);

CREATE FUNCTION set_event_date_func () RETURNS trigger AS '
 BEGIN
 	NEW.logdate = NEW.logtime::date;
 	RETURN NEW;
 END;
 ' LANGUAGE plpgsql;

CREATE TRIGGER set_event_date_trg BEFORE INSERT OR UPDATE
     ON event FOR EACH ROW
     EXECUTE PROCEDURE set_event_date_func ();

CREATE TABLE tag (
    id       SERIAL                        PRIMARY KEY,
    name     VARCHAR(20)                   NOT NULL,
    event    INTEGER                       NOT NULL REFERENCES event(id),
    CONSTRAINT name_event UNIQUE(name,event)
);

CREATE INDEX tag_name_idx ON tag(name);

CREATE TABLE extra_info (
    id       SERIAL                        PRIMARY KEY,
    name     VARCHAR(20)                   NOT NULL,
    val      VARCHAR(100)                  NOT NULL,
    event    INTEGER                       NOT NULL REFERENCES event(id),
    CONSTRAINT name_event_val UNIQUE(name,event,val)
);

CREATE index extra_info_name_idx ON extra_info(name);

CREATE TABLE auth_counts_ssh (
    id            SERIAL                   PRIMARY KEY,
    day           date                     NOT NULL,
    hostname      HOSTNAME                 NOT NULL,
    failure_count INTEGER                  NOT NULL DEFAULT 0,
    success_count INTEGER                  NOT NULL DEFAULT 0,
    total_count   INTEGER                  NOT NULL DEFAULT 0,
    CONSTRAINT day_hostname UNIQUE(day,hostname)
);

CREATE FUNCTION store_auth_counts_ssh() RETURNS void AS $$
DECLARE
    recent RECORD;
BEGIN

    LOCK TABLE auth_counts_ssh IN ACCESS EXCLUSIVE MODE;

    FOR recent IN ( SELECT day,hostname,failure_count,success_count,total_count FROM auth_counts_ssh_recent EXCEPT (SELECT day,hostname,failure_count,success_count,total_count FROM auth_counts_ssh) ) LOOP

        -- first try to update the key
        UPDATE auth_counts_ssh SET failure_count = recent.failure_count, success_count = recent.success_count, total_count = recent.total_count WHERE day = recent.day AND hostname = recent.hostname;

        IF NOT FOUND THEN
            INSERT INTO auth_counts_ssh(day,hostname,failure_count,success_count,total_count) VALUES (recent.day,recent.hostname,recent.failure_count,recent.success_count,recent.total_count);
        END IF;

    END LOOP;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW auth_counts_ssh_recent AS

WITH failures AS (
SELECT
  date_trunc('day', e.logtime) AS day,
  e.hostname,
  count(*)                     AS failure_count
FROM event AS e
JOIN tag   AS t ON e.id = t.event
WHERE
  e.program = 'sshd'                  AND
  t.name = 'auth_failure'
GROUP BY day, e.hostname ),
     successes AS (
SELECT
  date_trunc('day', e.logtime) AS day,
  e.hostname,
  count(*)                     AS success_count
FROM event AS e
JOIN tag   AS t ON e.id = t.event
WHERE
  e.program = 'sshd'                  AND
  t.name = 'auth_success'
GROUP BY day, e.hostname )
SELECT
  f.day,
  f.hostname,
  f.failure_count,
  s.success_count,
  f.failure_count + s.success_count AS total_count
FROM failures  AS f
JOIN successes AS s ON f.day = s.day and f.hostname = s.hostname
ORDER BY f.day, f.hostname;

-- Permissions

GRANT SELECT                      ON TABLE log, event, tag, extra_info
                                  TO logfiles_reader;

GRANT SELECT,INSERT,UPDATE        ON TABLE log, event, tag, extra_info
                                  TO logfiles_writer;

GRANT SELECT,INSERT,UPDATE,DELETE ON TABLE current_processing
                                  TO logfiles_writer;

GRANT SELECT,UPDATE               ON SEQUENCE current_processing_id_seq, event_id_seq, log_id_seq, tag_id_seq, extra_info_id_seq
                                  TO logfiles_writer;

-- various tables holding 'computed' results

GRANT SELECT,INSERT,UPDATE        ON TABLE auth_counts_ssh
                                  TO logfiles_reader;

GRANT SELECT,UPDATE               ON SEQUENCE auth_counts_ssh_id_seq
                                  TO logfiles_reader;

GRANT SELECT,INSERT,UPDATE        ON TABLE auth_counts_ssh
                                  TO logfiles_writer;

GRANT SELECT,UPDATE               ON SEQUENCE auth_counts_ssh_id_seq
                                  TO logfiles_writer;

-- This is a view so insert, update are not required

GRANT SELECT                      ON TABLE auth_counts_ssh_recent
                                  TO logfiles_reader;

GRANT SELECT                      ON TABLE auth_counts_ssh_recent
                                  TO logfiles_writer;

-- data anonymisation is very restricted

GRANT SELECT, UPDATE (raw,message,userid) ON TABLE event
                                          TO logfiles_anonymiser;

GRANT SELECT,DELETE                       ON TABLE extra_info
                                          TO logfiles_anonymiser;

COMMIT;
