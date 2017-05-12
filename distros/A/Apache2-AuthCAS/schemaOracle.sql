REM Schema for use with Oracle

CREATE TABLE cas_sessions (
      id                varchar2(32)    not null
    , last_accessed     number          not null
    , user_id           varchar2(32)    not null
    , pgtiou            varchar2(256)
    , pgt               varchar2(256)
    , service_ticket    varchar2(256)
    , CONSTRAINT cas_sessions_pk
        PRIMARY KEY (id) USING INDEX TABLESPACE &&ts_idx
) TABLESPACE &&ts_data;

CREATE UNIQUE INDEX cas_sessions_idx1 ON cas_sessions (pgtiou) TABLESPACE &&ts_idx;

