--setup psql session for testing
\set ON_ERROR_STOP
set client_min_messages=WARNING;
set search_path = 'dbix_pglink';
select public.plperl_use_blib();

select trace_level(5);