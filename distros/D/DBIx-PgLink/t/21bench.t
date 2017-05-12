use strict;
use Test::More tests => 3;
use Test::Deep;
#use Regexp::Common;

BEGIN {
  use lib 't';
  use_ok('PgLinkTestUtil');
}

my $dbh = PgLinkTestUtil::connect;
PgLinkTestUtil::init_test();

{
  my $data = $dbh->selectall_arrayref(<<'END_OF_SQL', {Slice=>{}});
SELECT * FROM dbix_pglink._benchmark_query('select * from source.crud');
END_OF_SQL


  cmp_deeply(
    $data, 
    [
      {
        bench_time => re('^\d\d:\d\d:\d\d.\d+$'), 
        bench_rows => re('^\d+$'),
      }
    ],
    '_benchmark_query(local table)'
  );
}

{
  $dbh->do(q/DROP TABLE IF EXISTS public.tbench CASCADE/);

  $dbh->do(<<'END_OF_SQL');
CREATE TABLE public.tbench AS
  SELECT i, random() as f, 'qwertyuiop'::text as t
  FROM generate_series(1,10000) as s(i);
END_OF_SQL
  $dbh->do(<<'END_OF_SQL');
create or replace function public.test_benchmark_query()
returns setof public.tbench language plperlu as $body$
  my $rv = spi_exec_query('SELECT * FROM public.tbench');
  for my $row (@{$rv->{rows}}) {
    return_next $row;
  }
  return;
$body$;
END_OF_SQL

  my $data = $dbh->selectall_arrayref(<<'END_OF_SQL', {Slice=>{}});
SELECT * FROM dbix_pglink.benchmark_function('public.test_benchmark_query()');
END_OF_SQL

  cmp_deeply(
    $data, 
    [
      {
        local_benchmark => re('^\(\d\d:\d\d:\d\d.\d+,\d+\)$'), # composite
        remote_benchmark => re('^\(\d\d:\d\d:\d\d.\d+,\d+\)$'), # composite
        execution_cost => re('^\d+\.\d+$'), #$RE{num}{real},
      },
    ],
    'benchmark_function(local function)'
  );

}
