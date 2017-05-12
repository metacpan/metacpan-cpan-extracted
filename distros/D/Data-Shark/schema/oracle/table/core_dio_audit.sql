/*
**
**  core_dio_audit
**
*/
drop table sharkapi2.core_dio_audit;
create table sharkapi2.core_dio_audit
  (
     ca_id              int             not null,
     ca_cd_id           int             not null,
     ca_ip              varchar2(255)   null,
     ca_user            int             null,
     ca_ts              date            null
  )
;
alter table sharkapi2.core_dio_audit add constraint core_dio_audit_pk primary key (ca_id);

create index core_dio_audit_i1 on sharkapi2.core_dio_audit(ca_cd_id,ca_ts);
create index core_dio_audit_i2 on sharkapi2.core_dio_audit(ca_user);
create index core_dio_audit_i3 on sharkapi2.core_dio_audit(ca_ts);

create or replace public synonym core_dio_audit for sharkapi2.core_dio_audit;
