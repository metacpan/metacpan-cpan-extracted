/*
**
**  core_dio_cache_exp
**
*/
drop table sharkapi2.core_dio_cache_exp;
create table sharkapi2.core_dio_cache_exp
  (
     ce_cd_id           int             not null,
     ce_exp_id          int             not null
  )
;
alter table sharkapi2.core_dio_cache_exp add constraint core_dio_cache_exp_pk primary key (ce_cd_id, ce_exp_id);

create or replace public synonym core_dio_cache_exp for sharkapi2.core_dio_cache_exp;
