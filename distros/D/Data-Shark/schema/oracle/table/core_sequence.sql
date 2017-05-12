/*
**
**  core_sequence
**
*/
drop table sharkapi2.core_sequence;
create table sharkapi2.core_sequence
  (
       s_column      varchar2(32)    not null,
       s_name        varchar2(32)    not null,
       s_table       varchar2(32)    not null,
       s_type        varchar2(32)    not null,
       s_group       varchar2(32)    not null
  )
;

create or replace public synonym core_sequence for sharkapi2.core_sequence;
