create database act_db_test1;
create database act_db_test2;
/*
grant all on act_db_test1.* 
   to 'act_db_test_user'@'localhost' identified by 'act_db_test_pass';
grant all on act_db_test2.* 
   to 'act_db_test_user'@'localhost' identified by 'act_db_test_pass'; 
*/
use act_db_test1;

create table t1 (
  id serial,
  c1 text,
  c2 text
);

insert into t1 values ( 1, 'd1_t1_r1_c1', 'd1_t1_r1_c2');

use act_db_test2;

create table t1 (
  id serial,
  c1 text,
  c2 text
);

insert into t1 values ( 1, 'd2_t1_r1_c1', 'd2_t1_r1_c2');

