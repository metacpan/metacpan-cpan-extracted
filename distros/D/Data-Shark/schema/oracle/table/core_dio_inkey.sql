/*
**
**  core_dio_inkey
**
*/
drop table sharkapi2.core_dio_inkey;
create table sharkapi2.core_dio_inkey
  (
     ci_cd_id           int             not null,
     ci_name            varchar2(64)    not null,
     ci_pos             int             not null,
     ci_req             char(1)         null,
     ci_key             char(1)         null,
     ci_inout           char(1)         null,
     ci_opt             varchar2(32)    null,
     ci_default         varchar2(2000)  null
  )
;
alter table sharkapi2.core_dio_inkey add constraint core_dio_inkey_pk primary key (ci_cd_id, ci_name);

create or replace public synonym core_dio_inkey for sharkapi2.core_dio_inkey;
