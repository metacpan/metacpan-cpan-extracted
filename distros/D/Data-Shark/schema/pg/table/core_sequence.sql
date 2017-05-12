/*
**
**  core_sequence
**
*/
drop table core_sequence;
create table core_sequence
  (
       s_column      varchar(32)    not null,
       s_name        varchar(32)    not null,
		 s_table       varchar(32)    not null,
		 s_type        varchar(32)    not null,
		 s_group       varchar(32)    not null
  )
;
