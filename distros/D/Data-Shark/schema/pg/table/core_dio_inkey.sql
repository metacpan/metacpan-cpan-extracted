/*
**
**  core_dio_inkey
**
*/
drop table core_dio_inkey;
create table core_dio_inkey
  (
     ci_cd_id           int             not null,
     ci_name            varchar(64)     not null,
     ci_pos             int             not null,
     ci_req             char(1)         null,
     ci_key             char(1)         null,
     ci_inout           char(1)         null,
     ci_default         text            null
  )
;
alter table core_dio_inkey add constraint core_dio_inkey_pk primary key (ci_cd_id, ci_name);
