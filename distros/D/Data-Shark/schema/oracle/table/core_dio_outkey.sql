/*
**
**  core_dio_outkey
**
*/
drop table sharkapi2.core_dio_outkey;
create table sharkapi2.core_dio_outkey
  (
     co_cd_id           int             not null,
     co_name            varchar2(64)    not null,
     co_pos             int             not null,
     co_req             char(1)         null,
     co_key             char(1)         null,
     co_inout           char(1)         null,
     co_default         varchar2(2000)  null
  )
;
alter table sharkapi2.core_dio_outkey add constraint core_dio_outkey_pk primary key (co_cd_id, co_name);

create or replace public synonym core_dio_outkey for sharkapi2.core_dio_outkey;
