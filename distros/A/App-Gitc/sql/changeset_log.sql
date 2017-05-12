-- This table is not at all normalized.  The goal is to keep the schema
-- ridiculously simple so that we can avoid as much schema management as
-- possible
create table changeset_log (
    id          serial primary key,
    stamp       timestamp default now(),
    user        varchar(8) not null,
    project     varchar(30) not null,
    changeset   varchar(40) not null,
    action      varchar(10) not null,
    target      varchar(5)      null,
    reviewer    varchar(12)     null
);
create index changeset_log_project_changeset
    on changeset_log (project,changeset);
