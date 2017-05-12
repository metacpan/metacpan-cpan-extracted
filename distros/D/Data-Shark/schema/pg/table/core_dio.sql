/*
**
**  core_dio
**
*/
drop table core_dio;
create table core_dio
  (
     cd_id              int             not null,
     cd_namespace       varchar(64)     not null,
     cd_name            varchar(64)     not null,
     cd_version         varchar(64)     not null,
     cd_sysclass        varchar(256)    null,
     cd_type            varchar(64)     not null,
     cd_return          varchar(64)     null,
     cd_cache           char(1)         null,
     cd_profile         char(1)         null,
     cd_audit           char(1)         null,
     cd_cache_expire    varchar(32)     null,
     cd_repl            varchar(32)     null,
     cd_action          varchar(32)     null,
     cd_stmt            text            null,
     cd_stmt_noarg      text            null
  )
;
alter table core_dio add constraint core_dio_pk primary key (cd_id);
create unique index core_dio_i1 on core_dio(cd_namespace, cd_name, cd_version);
