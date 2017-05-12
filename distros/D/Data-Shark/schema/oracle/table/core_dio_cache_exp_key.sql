/*
**
**  core_dio_cache_exp_key
**
*/
drop table sharkapi2.core_dio_cache_exp_key;
create table sharkapi2.core_dio_cache_exp_key
  (
     ck_cd_id           int             not null,
     ck_exp_id          int             not null,
     ck_key             varchar2(64)    not null
  )
;
alter table sharkapi2.core_dio_cache_exp_key add constraint core_dio_cache_exp_key_pk primary key (ck_cd_id, ck_exp_id, ck_key);

create or replace public synonym core_dio_cache_exp_key for sharkapi2.core_dio_cache_exp_key;
