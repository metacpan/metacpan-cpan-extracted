/*
**
**  core_dio
**
*/
drop table sharkapi2.core_dio;
create table sharkapi2.core_dio
  (
     cd_id              int             not null,
     cd_namespace       varchar2(64)    not null,
     cd_name            varchar2(64)    not null,
     cd_version         varchar2(64)    not null,
     cd_sysclass        varchar2(256)   null,
     cd_type            varchar2(64)    not null,
     cd_return          varchar2(64)    null,
     cd_cache           char(1)         null,
     cd_profile         char(1)         null,
     cd_audit           char(1)         null,
     cd_cache_expire    varchar2(32)    null,
     cd_repl            varchar2(32)    null,
     cd_action          varchar2(32)    null,
     cd_stmt            varchar2(2000)  null,
     cd_stmt_noarg      varchar2(2000)  null
  )
;
alter table sharkapi2.core_dio add constraint core_dio_pk primary key (cd_id);
create unique index core_dio_i1 on sharkapi2.core_dio(cd_namespace, cd_name, cd_version);

create or replace public synonym core_dio for sharkapi2.core_dio;
