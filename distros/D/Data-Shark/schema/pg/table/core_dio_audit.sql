/*
**
**  core_dio_audit
**
*/
drop table core_dio_audit;
create table core_dio_audit
  (
     ca_id              int             not null,
     ca_cd_id           int             not null,
     ca_ip              varchar(255)    null,
     ca_user            int             null,
     ca_ts              timestamp with time zone null
  )
;
alter table core_dio_audit add constraint core_dio_audit_pk primary key (ca_id);

create index core_dio_audit_i1 on core_dio_audit(ca_cd_id,ca_ts);
create index core_dio_audit_i2 on core_dio_audit(ca_user);
create index core_dio_audit_i3 on core_dio_audit(ca_ts);
