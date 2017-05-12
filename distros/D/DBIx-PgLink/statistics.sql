set search_path = 'dbix_pglink';

create type benchmark_result as (bench_time interval, bench_rows bigint);

create or replace function _benchmark_query(_query text)
returns dbix_pglink.benchmark_result language plpgsql as $body$
declare
  _rec record;
  _first_row boolean;
  _s text;
  _result dbix_pglink.benchmark_result;
begin

  _first_row := 't';
  for _rec in execute('EXPLAIN ANALYZE ' || _query) loop
    --raise INFO 'plan: %', _first_row, _rec."QUERY PLAN";
    if _first_row then
      _s := substring(_rec."QUERY PLAN" from $re$actual time=.* rows=(\d+)$re$);
      if _s is not null then
        _result.bench_rows := _s::bigint;
      end if;
    else
      _s := substring(_rec."QUERY PLAN" from $re$^Total runtime: (.*) ms$$re$);
      if _s is not null then
        _result.bench_time := _s::float8 * '0.001s'::interval;
      end if ;
    end if;
    _first_row := false;
  end loop;

  return _result;
end;
$body$;
comment on function _benchmark_query(_query text) is $$Utility function, execute EXPLAIN ANALYZE <query>. 
Returns actual time and row count$$;



create or replace function benchmark_function(
  _remote_table text,
  out local_benchmark  benchmark_result,
  out remote_benchmark benchmark_result,
  out execution_cost float
) language plpgsql as $body$
declare
  _local_table text;
  _query text;
  _relpages int;
begin

  _local_table := 'dbix_pglink.tmp_benchmark';

  execute('DROP TABLE IF EXISTS ' || _local_table);

  --materialize remote table as local temp table
  raise INFO 'copy % into %', _remote_table, _local_table;
  execute(
    'CREATE TABLE ' || _local_table || ' as SELECT * FROM ' || _remote_table
  );
  execute('ANALYZE ' || _local_table); --update statistics
  --now remote table probably cached on remote server
  --so it is fair to compare cached local table with remote table
  --in fact, this measures mostly network throughput + perl code overhead
  
  _query = 'SELECT * FROM ' || _local_table;
  raise INFO 'benchmark %', _query;
  local_benchmark := dbix_pglink._benchmark_query(_query);
    
  _query = 'SELECT * FROM ' || _remote_table;
  raise INFO 'benchmark %', _query;
  remote_benchmark := dbix_pglink._benchmark_query(_query);

  _relpages := (select relpages from pg_class where oid=_local_table::regclass);
    
  execute('DROP TABLE IF EXISTS ' || _local_table);

  --execution cost per returned row, in units of 'cpu_operator_cost'
  --default for non-C function is 100
  --cost ~ time/rows * Const
  execution_cost := --1/tuple
    1
    * ( extract(epoch from remote_benchmark.bench_time) / remote_benchmark.bench_rows ) --time/tuple, remote db + network + perl
    / ( extract(epoch from local_benchmark.bench_time)  / local_benchmark.bench_rows  ) --tuple/time, local db

    --disk read cost per tuple (local, not remote!)
    --(local tuple fetch cost + tuple CPU cost)
    * (
      current_setting('random_page_cost')::float --1/page
      * _relpages --page
      / local_benchmark.bench_rows --1/tuple
      + current_setting('cpu_tuple_cost')::float --1/tuple
    )
    / current_setting('cpu_operator_cost')::float
  ;

end;
$body$;
comment on function benchmark_function(
  _remote_table text,
  out local_benchmark  benchmark_result,
  out remote_benchmark benchmark_result,
  out execution_cost float
) is $$Utility function, compare performance of set-returning function (or view over function) vs materialized table.
Returns benchmark results and estimated execution cost per row.
This function is costly as it fetch all remote table rows twice and create local copy of data.
DO NOT EXECUTE THIS ON REALLY BIG TABLE!
Average output of this function (execution_cost) can be used as input for update_statistics() function.$$;



create or replace function update_statistics(
  _conn_name           text,
  _local_schema        text,
  _local_object        text,
  _remote_object_types text[],
  _execution_cost      float
) returns int security definer
language plperlu as $body$
#line 119
  use DBIx::PgLink;
  my $conn = DBIx::PgLink->connect(shift);
  my $p = named_params(\@_, 
    qw/local_schema local_object remote_object_types execution_cost/
  );
  my $cost = delete $p->{execution_cost};
  $conn->for_accessors(
    %{$p},
    coderef => sub { 
      my $accessor = shift;
      $accessor->update_statistics(
        execution_cost => $cost
      ) if $accessor->can('update_statistics');
    },
  );
$body$;

revoke all on function update_statistics(
  _conn_name           text,
  _local_schema        text,
  _local_object        text,
  _remote_object_types text[],
  _execution_cost      float
) from public;

comment on function update_statistics(
  _conn_name           text,
  _local_schema        text,
  _local_object        text,
  _remote_object_types text[],
  _execution_cost      float
) is $$Set function statistics (row count and execution cost) for table function.
Parameters:
  1 - connection name
  2 - local schema name
  3 - like-pattern of local object name
  4 - array of remote object types
  5 - execution cost, can be result of previously running benchmark_function()
Returns number of objects.$$;

