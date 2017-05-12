use strict;
use Test::More tests => 30;
use Test::Exception;

BEGIN {
  use lib 't';
  use_ok('PgLinkTestUtil');
}

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();


# --------SELECT table accessor functions

$dbh->do('DELETE FROM source.crud WHERE id not between 1 and 5');

is_deeply(
  $dbh->selectall_arrayref(q/SELECT * from test_pg.crud$() ORDER BY 1/, {Slice=>{}}),
  [
    {id=>1,i=>1,t=>'row#1'},
    {id=>2,i=>2,t=>'row#2'},
    {id=>3,i=>3,t=>'row#3'},
    {id=>4,i=>4,t=>'row#4'},
    {id=>5,i=>5,t=>'row#5'},
  ],
  'select: no where'
);

is_deeply(
  $dbh->selectall_arrayref(q/SELECT * from test_pg.crud$('WHERE id <= 3',null,null) ORDER BY 1/, {Slice=>{}}),
  [
    {id=>1,i=>1,t=>'row#1'},
    {id=>2,i=>2,t=>'row#2'},
    {id=>3,i=>3,t=>'row#3'},
  ],
  'select: where'
);

is_deeply(
  $dbh->selectall_arrayref(q/SELECT * from test_pg.crud$('WHERE id <= ?',ARRAY[2],null) ORDER BY 1/, {Slice=>{}}),
  [
    {id=>1,i=>1,t=>'row#1'},
    {id=>2,i=>2,t=>'row#2'},
  ],
  'select: where+param_values'
);

is_deeply(
  $dbh->selectall_arrayref(q/SELECT * from test_pg.crud$('WHERE id <= ?',ARRAY[1], ARRAY['int']) ORDER BY 1/, {Slice=>{}}),
  [
    {id=>1,i=>1,t=>'row#1'},
  ],
  'select: where+param_values+param_types'
);


#--------------------- query filter

lives_ok {
  $dbh->do(q/SELECT test_pg.crud_set_filter('WHERE id between ? and ?', ARRAY[2,4], NULL)/);
} 'set filter';


is_deeply(
  $dbh->selectall_arrayref(q/SELECT * from test_pg.crud ORDER BY 1/, {Slice=>{}}),
  [
    {id=>2,i=>2,t=>'row#2'},
    {id=>3,i=>3,t=>'row#3'},
    {id=>4,i=>4,t=>'row#4'},
  ],
  'select: filter applied'
);

lives_ok {
  $dbh->do(q/SELECT test_pg.crud_reset_filter()/);
} 'reset filter';

is_deeply(
  $dbh->selectall_arrayref(q/SELECT * from test_pg.crud ORDER BY 1/, {Slice=>{}}),
  [
    {id=>1,i=>1,t=>'row#1'},
    {id=>2,i=>2,t=>'row#2'},
    {id=>3,i=>3,t=>'row#3'},
    {id=>4,i=>4,t=>'row#4'},
    {id=>5,i=>5,t=>'row#5'},
  ],
  'select: filter removed'
);

# ----------------------------------------- CRUD table accessors

sub get_row {
  $dbh->selectrow_hashref('SELECT * FROM test_pg.crud WHERE id=?', {}, @_);
}

lives_ok {
  $dbh->do(q/delete from test_pg.crud where id=100/);
} 'remote delete';

is_deeply(get_row(100), undef, 'remote select 1');

dies_ok {
  $dbh->do(q/insert into test_pg.crud(t) select 'remote insert'/);
} 'remote insert (constraint violation)';

is_deeply(get_row(100), undef, 'remote select 2');

lives_ok {
  $dbh->do(q/insert into test_pg.crud(id, i,t) select 100, 100, 'remote insert'/);
} 'remote insert';

is_deeply(get_row(100), {id=>100, i=>100, t=>'remote insert'}, 'remote select 3');

lives_ok {
  $dbh->do(q/update test_pg.crud set i=777 where id=100/);
} 'remote update';

is_deeply(get_row(100), {id=>100, i=>777, t=>'remote insert'}, 'remote select 4');


# multiple rows insert/delete

my $rc = 1000;

$dbh->do(q/delete from source.crud where id>=100/);

lives_ok {
  $dbh->do(qq/insert into test_pg.crud(id, i,t) select i+100, i, 'remote insert' from generate_series(1,$rc) as s(i)/);
} "remote insert $rc rows";

lives_ok {
  $dbh->do(q/delete from test_pg.crud where id>100;/);
} "remote insert $rc rows";


# one row, nested transaction

$dbh->do(q/delete from source.crud where id>=100/);


lives_ok {
  $dbh->do(q/select dbix_pglink.begin('TEST')/);
  eval {
    $dbh->do(q/insert into test_pg.crud(id, i,t) select 100, 100, 'remote insert'/);
    $dbh->do(q/update test_pg.crud set i=888 where id=100/);
    $dbh->do(q/delete from test_pg.crud where id=100/);
    $dbh->do(q/select dbix_pglink.commit('TEST')/);
  };
  if ($@) {
    lives_ok {
      $dbh->do(q/select dbix_pglink.rollback('TEST')/);
    } 'outer rollback';
    die $@;
  }
} 'nested transaction (ok)';

throws_ok {
  $dbh->do(q/select dbix_pglink.begin('TEST')/);
  eval {
    $dbh->do(q/insert into test_pg.crud(i,t) select 42, 'remote insert'/);
    die 'This INSERT must fails';
    $dbh->do(q/select dbix_pglink.commit('TEST')/);
  };
  if ($@) {
    my $err = $@;
    lives_ok {
      $dbh->do(q/select dbix_pglink.rollback('TEST')/);
    } 'outer rollback';
    die $err;
  }
} qr/Modification of remote TABLE "source"."crud" failed/, 'nested transaction (error)';

# ------------- routine accessor

is_deeply(
  $dbh->selectall_arrayref(q/SELECT test_pg.get_void()/, {Slice=>{}}),
  [
    { get_void=>'' },
  ],
  'remote function get_void()'
);

is_deeply(
  $dbh->selectall_arrayref(q/SELECT test_pg.get_scalar()/, {Slice=>{}}),
  [
    { get_scalar=>42 },
  ],
  'remote function get_scalar()'
);

is_deeply(
  $dbh->selectall_arrayref(q/SELECT test_pg.get_scalar(1,'foo')/, {Slice=>{}}),
  [
    { get_scalar=>2 },
  ],
  'remote function get_scalar(int,text)'
);

is_deeply(
  $dbh->selectall_arrayref(q/SELECT * from test_pg.get_row1(3,'hello')/, {Slice=>{}}),
  [
    { id=>1, i=>3, t=>'hello' },
  ],
  'remote function get_row1(domain->int,text)'
);

is_deeply(
  $dbh->selectall_arrayref(q/SELECT * from test_pg.get_row2(1,'foo')/, {Slice=>{}}),
  [
    { b=>'hello, foo', c=>'2000-12-31' },
  ],
  'remote function get_row2(int,text)->record'
);

is_deeply(
  $dbh->selectall_arrayref(q/SELECT * from test_pg.get_setof(5,'foo')/, {Slice=>{}}),
  [
    { id=>1, i=>5, t=>'foo' },
    { id=>2, i=>5, t=>'foo' },
    { id=>3, i=>5, t=>'foo' },
    { id=>4, i=>5, t=>'foo' },
    { id=>5, i=>5, t=>'foo' },
  ],
  'remote function get_setof(int,text)->set'
);


# bytea input
is_deeply(
  $dbh->selectall_arrayref(q/SELECT test_pg.get_bytea_length($$foo\000\377\123$$::bytea)/, {Slice=>{}}),
  [ {get_bytea_length=>6} ],
  'bytea input to function accessor'
);

is_deeply(
  $dbh->selectall_arrayref(q/
select * from dbix_pglink.query(
  'TEST',
  $$select source.get_bytea_length(?)$$,
  ARRAY[$$foo\000\377\123$$]
) as s(get_bytea_length int)
/, {Slice=>{}}),
  [ {get_bytea_length=>6} ],
  'bytea input to query()'
);
