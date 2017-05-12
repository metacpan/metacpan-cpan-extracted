/*
**
**  core_dio_cache_exp_key
**
*/
drop table core_dio_cache_exp_key;
create table core_dio_cache_exp_key
  (
     ck_cd_id           int             not null,
     ck_exp_id          int             not null,
     ck_key             varchar(64)     not null
  )
;
alter table core_dio_cache_exp_key add constraint core_dio_cache_exp_key_pk primary key (ck_cd_id, ck_exp_id, ck_key);
