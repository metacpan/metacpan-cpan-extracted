create database act_db_test1;
create database act_db_test2;
\c act_db_test1;
create schema public;
create table t1 (
  id serial primary key,
  c1 text,
  c2 text
);

insert into t1 values ( default, 'd1_t1_r1_c1', 'd1_t1_r1_c2');

\c act_db_test2;
create schema public;
create table t1 (
  id serial primary key,
  c1 text,
  c2 text
);

insert into t1 values ( default, 'd2_t1_r1_c1', 'd2_t1_r1_c2');

