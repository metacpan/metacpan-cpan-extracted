#!perl -T

use Test::More tests => 61;

use_ok('DBIx::DataStore');
use_ok('DBD::SQLite');

BEGIN {
    my $dbfile = '/tmp/dbix-datastore-test.db';
    unlink($dbfile) if -f $dbfile;
}
END {
    unlink($dbfile) if -f $dbfile;
}

my $config = {
    cache_connections => 0,
    cache_statements  => 0,
    primary => {
        driver => 'SQLite',
        dsn    => "dbi:SQLite:$dbfile",
    }
};

my $db = DBIx::DataStore->new({ config => $config });
ok(ref($db), 'defined db object returned');

my $res = $db->do(q{ select 1 });
ok($res,            'select-1 resultset defined');
ok($res->next,      'select-1 resultrow defined');
is($res->[0], 1,    'select-1 returned expected value');

$res = $db->do(q{ select ? }, 'abc');
ok($res,                'placeholder-1 resultset defined');
ok($res->next,          'placeholder-1 resultrow defined');
is($res->[0], 'abc',    'placeholder-1 returned expected value');

$res = $db->do(q{ select 1 where 'a' in ??? }, [qw( a b c )]);
ok($res,                'placeholder-2 resultset defined');
ok($res->next,          'placeholder-2 resultrow defined');
is($res->[0], 1,        'placeholder-2 returned expected value');

$res = $db->do(q{ create table test_one ( id integer not null primary key, data text not null ) });
ok($res,    'create-1 resultset defined');

$res = $db->do(q{ insert into test_one ??? }, { id => 1, data => "foo" });
ok($res,                                            'insert-1 resultset defined');
is($db->last_insert_id("","","test_one","id"), 1,   'insert-1 last_insert_id returned expected value');

$res = $db->do(q{ insert into test_one ??? },
    [{ id => 2, data => "foo" },{ id => 3, data => "foo" },{ id => 4, data => "foo" }]
);
ok($res,                                            'insert-2 resultset defined');
is($db->last_insert_id("","","test_one","id"), 4,   'insert-2 last_insert_id returned expected value');

$res = $db->do(q{ select * from test_one order by id asc });
ok($res,                            'select-2 resultset defined');
is($res->next && $res->{'id'}, 1,   'select-2 first row id is expected value');
is($res->next && $res->{'id'}, 2,   'select-2 second row id is expected value');
is($res->next && $res->{'id'}, 3,   'select-2 third row id is expected value');
is($res->next && $res->{'id'}, 4,   'select-2 fourth (last) row id is expected value');
ok( ! $res->next,                   'select-2 resultset contained expected number of resultrows');
is($res->count, 4,                  'select-2 resultset->count returned expected value');

$res = $db->do(q{ update test_one set ??? where id = ? }, { data => "bar" }, 2);
ok($res,                'update-1 resultset defined');
is($res->count, 1,      'udpate-1 resultset->count returned expected value');

$res = $db->do(q{ select data from test_one where id = ? }, 2);
ok($res,                                        'select-3 resultset defined');
is_deeply([sort $res->columns], [qw( data )],   'select-3 columns() returned expected value');
ok($res->next,                                  'select-3 resultset contained valid resultrow');
is($res->[0], "bar",                            'select-3 resultrow contained expected value after earlier update');

$res = $db->do({ page => 2, per_page => 1 }, q{ select id, data from test_one order by id asc });
ok($res,                        'paged-1 resultset defined');
ok($res->next,                  'paged-1 resultset contained resultrow');
is($res->{'id'}, 2,             'paged-1 resultrow was expected value');
ok( ! $res->next,               'paged-1 resultset contained proper number of rows');
my $pager = $res->pager;
ok(defined $pager,              'paged-1 resultset contained pager object');
is($pager->first_page, 1,       'paged-1 pager first_page expected value');
is($pager->last_page, 4,        'paged-1 pager last_page expected value');
is($pager->first, 2,            'paged-1 pager current page first entry expected value');
is($pager->last, 2,             'paged-1 pager current page last entry expected value');
is($pager->total_entries, 4,    'paged-1 pager total_entries expected value');
is($pager->entries_per_page, 1, 'paged-1 pager entries_per_page expected value');
is($pager->current_page, 2,     'paged-1 pager current_page expected value');

$res = $db->do(q{ create table tx_testing ( id integer not null primary key, data text not null ) });
ok($res,                    'create-2 resultset defined');
ok($db->begin,              'txn-1 begin returned true');
ok($db->in_transaction,     'txn-1 in_transaction reports true');
$res = $db->do(q{ insert into tx_testing (id, data) values (1, 'row to rollback') });
ok($res,                    'txn-1 row insert returned defined result');
$res = $db->do(q{ select * from tx_testing where id = 1 });
ok($res && $res->next,      'txn-1 found row inserted in current transaction');
ok($db->rollback,           'txn-1 rollback returned true');
$res = $db->do(q{ select * from tx_testing where id = 1 });
ok($res,                    'txn-1 select returned valid resultset object');
ok( ! $res->next,           'txn-1 row that was rollback\'ed not present in resultset');

$res = $db->do(q{ insert into tx_testing (id, data) values (2, 'pre-savepoint row to save') });
ok($db->begin,                              'txn-2 transaction started successfully');
ok($res,                                    'txn-2 first insert succeeded');
ok($db->savepoint("save1"),                 'txn-2 savepoint() returned true');
$res = $db->do(q{ insert into tx_testing (id, data) values (3, 'post-savepoint row to rollback') });
ok($res,                                    'txn-2 second insert succeeded');
$res = $db->do(q{ select * from tx_testing where id in (2,3) });
ok($res && $res->next && $res->next,        'txn-2 both rows post-begin are present');
ok($db->rollback("save1"),                  'txn-2 rollback to savpoint returned true');
$res = $db->do(q{ select * from tx_testing where id in (2,3) order by id asc });
ok($res && $res->next,                      'txn-2 post-savepoint rollback select succeeded and returned first row');
ok( ! $res->next,                           'txn-2 post-savepoint rollback select did not return post-savepoint insert');
ok($db->commit,                             'txn-2 post-savepoint rollback commit succeeded');
$res = $db->do(q{ select * from tx_testing where id in (2,3) order by id asc });
ok($res && $res->next,                      'txn-2 post-savepoint rollback commit select succeeded and returned first row');
ok( ! $res->next,                           'txn-2 post-savepoint rollback commit select did not return post-savepoint insert');

