--setup fresh database for testing
--database must be created from template0

\set ON_ERROR_STOP
set client_min_messages=WARNING;
select public.plperl_use_blib();

\i _install.sql

set search_path = 'dbix_pglink';

\i t/test_schema.sql

----test functions

create or replace function ok(_condition boolean, _name text) 
returns void language plpgsql as $body$
begin
  if not _condition then
    raise EXCEPTION 'not ok: %', _name;
  end if;
  return;
end;
$body$;
grant execute on function ok(_condition boolean, _name text) to public;

create or replace function is(_got anyelement, _expected anyelement, _name text)
returns void language plpgsql as $body$
begin
  if _got IS DISTINCT FROM _expected then
    raise EXCEPTION 'not ok %: got=''%'' expected=''%''', _name, _got, _expected;
  end if;
  return;
end;
$body$;
grant execute on function is(_got anyelement, _expected anyelement, _name text) to public;

create or replace function dies_ok(_query text, _name text) 
returns void language plpgsql as $body$
begin
  begin
    execute(_query);
  exception
    when others then return;
  end;
  raise EXCEPTION 'not dies_ok: %', _name;
end;
$body$;
grant execute on function dies_ok(_query text, _name text) to public;

----debug functions

create or replace function dbix_pglink.plperl_dump_rv_struct(_query text) returns text language plperlu as $body$
  use Data::Dumper;
  my $rv = spi_exec_query(shift);
  return Dumper($rv);
$body$;

select dbix_pglink.plperl_dump_rv_struct('SELECT 1');
select dbix_pglink.plperl_dump_rv_struct('SELECT * FROM dbix_pglink.connections');

create or replace function dbix_pglink.plperl_show_inc() returns void language plperlu as $body$
  elog NOTICE, '@INC=' . join(" ", @INC);
  return;
$body$;

