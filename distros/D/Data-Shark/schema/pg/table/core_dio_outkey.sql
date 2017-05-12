/*
**
**  core_dio_outkey
**
*/
drop table core_dio_outkey;
create table core_dio_outkey
  (
     co_cd_id           int             not null,
     co_name            varchar(64)     not null,
     co_pos             int             not null,
     co_req             char(1)         null,
     co_key             char(1)         null,
     co_inout           char(1)         null,
     co_default         text            null
  )
;
alter table core_dio_outkey add constraint core_dio_outkey_pk primary key (co_cd_id, co_name);
