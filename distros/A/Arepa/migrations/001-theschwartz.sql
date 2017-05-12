CREATE TABLE funcmap (
        funcid         INTEGER PRIMARY KEY AUTOINCREMENT,
        funcname       VARCHAR(255) NOT NULL,
        UNIQUE(funcname)
);

CREATE TABLE job (
        jobid           INTEGER PRIMARY KEY AUTOINCREMENT,
        funcid          INTEGER UNSIGNED NOT NULL,
        arg             MEDIUMBLOB,
        uniqkey         VARCHAR(255) NULL,
        insert_time     INTEGER UNSIGNED,
        run_after       INTEGER UNSIGNED,
        grabbed_until   INTEGER UNSIGNED,
        priority        SMALLINT UNSIGNED,
        coalesce        VARCHAR(255),
        UNIQUE(funcid,uniqkey)
);

CREATE TABLE note (
        jobid           BIGINT UNSIGNED NOT NULL,
        notekey         VARCHAR(255),
        value           MEDIUMBLOB,
        PRIMARY KEY (jobid, notekey)
);

CREATE TABLE error (
        error_time      INTEGER UNSIGNED NOT NULL,
        jobid           INTEGER NOT NULL,
        funcid          INTEGER UNSIGNED NOT NULL,
        message         VARCHAR(255) NOT NULL
);

CREATE TABLE exitstatus (
        jobid           INTEGER PRIMARY KEY NOT NULL,
        funcid          INTEGER UNSIGNED NOT NULL,
        status          SMALLINT UNSIGNED,
        completion_time INTEGER UNSIGNED,
        delete_after    INTEGER UNSIGNED
);

ALTER TABLE compilation_queue ADD jobid INTEGER;
