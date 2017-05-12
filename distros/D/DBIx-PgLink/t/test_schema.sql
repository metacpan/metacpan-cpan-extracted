-----test schema

create schema source;

create domain source.domain1 as int check (value between 1 and 5);

create or replace function create_domain2() returns void language plpgsql as $body$
begin
  begin
    execute($$create domain source.domain2 as source.domain1 default 1 not null$$);
  exception
    when datatype_mismatch then --v8.1
      execute($$create domain source.domain2 as int default 1 not null$$);
  end;
end;
$body$;

select create_domain2();

drop function create_domain2();

create type source.composite1 as (
  a int,
  b text
);

create table source.all_types(
  f_smallint smallint default 1,
  f_integer  integer default 2,
  f_bigint   bigint default power(2,33),
  f_decimal  decimal(10,3) default 1234.567,
  f_numeric  numeric(30,2) default 1234567890123456789012345678.12,
  f_real     real default 2.0/3,
  f_double_precision double precision default 1.0/42,
  f_serial    serial,
  f_bigserial bigserial,
  f_varchar varchar(10) default 'hello',
  f_char char(10) default 'world',
  f_text text default 'PostgreSQL is an object-relational database management system (ORDBMS) based on POSTGRES, Version 4.2, developed at the University of California at Berkeley Computer Science Department. POSTGRES pioneered many concepts that only became available in some commercial database systems much later.',
  f_bytea bytea default E'TEST\001\002 OK',
  f_timestamp timestamp default '1945-05-09 01:23:45.678',
  f_timestamp_tz timestamp with time zone default '1956-05-22 01:23:45.678 UTC+05',
  f_interval interval default '1 hr 45 min',
  f_date date default '2007-10-01',
  f_time time default '11:11',
  f_boolean boolean default true,
  f_inet inet default '192.168.0.1/32',
  f_bit bit(8) default '00101010',
  f_int_array int[] default '{1,2,3}',
  f_text_array text[] default '{one,two,"three four"}',
  f_domain1 source.domain1 default 5,
  f_domain2 source.domain2,
  f_composite1 source.composite1 default '(99,"a b c")'
);
insert into source.all_types values (default);

create table source.crud (
  id int primary key,
  i  int,
  t  text
);
insert into source.crud(id, i, t) select i, i, 'row#'::text || i::text from generate_series(1,5) as s(i);

create view source.v_crud as select i, t from source.crud where i < 3;

create table source.tbool (
  id int primary key,
  t  text,
  b  boolean
);
insert into source.tbool values (1, 'a', null);
insert into source.tbool values (2, 'b', 'f');
insert into source.tbool values (3, 'c', 't');

create table source.enc (
  id int primary key,
  t  text
);
set client_encoding=win1251;
insert into source.enc values ( 1, 'Покупая'); 
insert into source.enc values ( 2, 'птицу');
insert into source.enc values ( 3, 'смотри');
insert into source.enc values ( 4, 'нет');
insert into source.enc values ( 5, 'ли');
insert into source.enc values ( 6, 'у');
insert into source.enc values ( 7, 'неё');
insert into source.enc values ( 8, 'зубов');
insert into source.enc values ( 9, 'Если');
insert into source.enc values (10, 'есть');
insert into source.enc values (11, 'зубы');
insert into source.enc values (12, 'то');
insert into source.enc values (13, 'это');
insert into source.enc values (14, 'не');
insert into source.enc values (15, 'птица');

create or replace function source.get_void() returns void language sql as '';

create or replace function source.get_scalar() returns int language sql as 'SELECT 42';

create or replace function source.get_scalar(a int, b text) returns int language sql as 'SELECT $1*2';

create or replace function source.get_row1(a source.domain2, b text) returns source.crud language sql 
as $$SELECT ROW(1,$1,$2)::source.crud$$;

create or replace function source.get_row2(in a int, inout b text, out c date) language plpgsql
as $body$
begin
  b := 'hello, ' || b;
  c := '2000-12-31';
end;
$body$;

create or replace function source.get_setof(a int, b text) returns setof source.crud language sql
as $$SELECT i,$1,$2 FROM generate_series(1,$1) as s(i)$$;

create or replace function source.get_bytea_length(a bytea) returns int 
language sql as $$select octet_length($1)$$;

grant connect on database test_pglink to test_pglink1;
grant connect on database test_pglink to test_pglink2;
grant usage on schema dbix_pglink to test_pglink1;
grant usage on schema dbix_pglink to test_pglink2;
grant usage on schema source to test_pglink1;
grant usage on schema source to test_pglink2;
grant all on source.crud to test_pglink1;
grant all on source.v_crud to test_pglink1;
grant all on source.crud to test_pglink2;
grant all on source.v_crud to test_pglink2;

grant all on function source.get_scalar() to test_pglink1;
grant all on function source.get_scalar() to test_pglink2;

grant all on function source.get_scalar(a int, b text) to test_pglink1;
grant all on function source.get_scalar(a int, b text) to test_pglink2;

grant all on function source.get_row1(a source.domain2, b text) to test_pglink1;
grant all on function source.get_row1(a source.domain2, b text) to test_pglink2;

grant all on function source.get_row2(in a int, inout b text, out c date) to test_pglink1;
grant all on function source.get_row2(in a int, inout b text, out c date) to test_pglink2;

grant all on function source.get_setof(a int, b text) to test_pglink1;
grant all on function source.get_setof(a int, b text) to test_pglink2;

grant all on function source.get_bytea_length(a bytea) to test_pglink1;
grant all on function source.get_bytea_length(a bytea) to test_pglink2;
