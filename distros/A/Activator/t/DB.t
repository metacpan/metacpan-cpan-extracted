#!perl
use warnings;
use strict;
use Test::More;
use Test::Exception;
use Data::Dumper;
use DBI;

BEGIN{ 
    $ENV{ACT_REG_YAML_FILE} ||= "$ENV{PWD}/t/data/DB-test.yml";
}

if ( ! ( $ENV{ACT_DB_TEST_ENGINE} && (
	 ( $ENV{ACT_DB_TEST_ENGINE} eq 'mysql' && $ENV{ACT_DB_TEST_USER} && $ENV{ACT_DB_TEST_PASSWORD} ) ||
	 ( $ENV{ACT_DB_TEST_ENGINE} eq 'Pg'    && $ENV{ACT_DB_TEST_USER} ) ) ) ) {

    plan skip_all => q{
 TO ENABLE Activator::DB tests you must set some environment variables as such:
   a) set ACT_DB_TEST_ENGINE to "mysql", then set ACT_DB_TEST_USER
      and ACT_DB_TEST_PASSWORD to user/password that can 'create database'
OR
   b) set ACT_DB_TEST_ENGINE to "Pg", then set ACT_DB_TEST_USER
      to a user that has passwordless access to psql and can 'create database'}
}
else {
    plan tests => 68;
}

use Activator::DB;
use Activator::Registry;
use Activator::Exception;
my ($dbh, $db, $id, $res, @row, $rowref, $err);

# create test dbs, users, tables
if ( $ENV{ACT_DB_TEST_ENGINE} eq 'mysql' ) {
    system( "cat $ENV{PWD}/t/data/DB-create-mysql-test.sql | mysql -u $ENV{ACT_DB_TEST_USER} -p$ENV{ACT_DB_TEST_PASSWORD}");
}
else {
    system( "psql template1 $ENV{ACT_DB_TEST_USER} < $ENV{PWD}/t/data/DB-create-Pg-test.sql");

}

# connect/select the old skool way
my $mysql_dsn = 'DBI:mysql:act_db_test1:localhost';
my $pg_dsn    = 'DBI:Pg:database=act_db_test1';
my $dsn = ( $ENV{ACT_DB_TEST_ENGINE} eq 'Pg' ? $pg_dsn : $mysql_dsn );

$dbh =  DBI->connect( $dsn, $ENV{ACT_DB_TEST_USER}, $ENV{ACT_DB_TEST_PASSWORD} );
ok( !$@, 'test old skool: DBI->connect without $@');
ok( !$DBI::err, 'no $DBI::err');
ok( !$DBI::errstr, 'no $DBI::errstr');
ok( $dbh, 'got dbh with DBI');
lives_ok { $dbh->ping() } 'ping $dbh with DBI';

# make sure we can do the basics with DBI
@row = $dbh->selectrow_array( 'select * from t1' );
ok( $row[0] eq '1' && $row[1] eq 'd1_t1_r1_c1' && $row[2] eq 'd1_t1_r1_c2', 'can select row with DBI');
lives_ok { $dbh->disconnect() } 'disconnect $dbh with DBI';

################################################################################
#
# connnect to the default db
#

# set up all the connections proppa
Activator::Registry->register('Activator::DB->connections->test1_mysql->user', $ENV{ACT_DB_TEST_USER});
Activator::Registry->register('Activator::DB->connections->test1_mysql->pass', $ENV{ACT_DB_TEST_PASSWORD});
Activator::Registry->register('Activator::DB->connections->test2_mysql->user', $ENV{ACT_DB_TEST_USER});
Activator::Registry->register('Activator::DB->connections->test2_mysql->pass', $ENV{ACT_DB_TEST_PASSWORD});
Activator::Registry->register('Activator::DB->connections->test1_pg->user', $ENV{ACT_DB_TEST_USER});
Activator::Registry->register('Activator::DB->connections->test1_pg->pass', $ENV{ACT_DB_TEST_PASSWORD});
Activator::Registry->register('Activator::DB->connections->test2_pg->user', $ENV{ACT_DB_TEST_USER});
Activator::Registry->register('Activator::DB->connections->test2_pg->pass', $ENV{ACT_DB_TEST_PASSWORD});
my $testdb1 = 'test1_mysql';
my $testdb2 = 'test2_mysql';
if ( $ENV{ACT_DB_TEST_ENGINE} eq 'Pg' ) {
    Activator::Registry->register('Activator::DB->default->connection', 'test1_pg');
    $testdb1 = 'test1_pg';
    $testdb2 = 'test2_pg';
}

lives_ok {
    $db = Activator::DB->connect('default')
} 'new skool: no connect error on default db';
ok( defined( $db ) && $db->isa('Activator::DB'), 'valid default Activator::DB object');
ok( $db->{cur_alias} eq $testdb1, "alias set to testdb1");

# select default row
lives_ok {
    @row = $db->getrow( 'select * from t1' );
} "getrow doesn't die";
ok( $row[0] eq '1' && $row[1] eq 'd1_t1_r1_c1' && $row[2] eq 'd1_t1_r1_c2', 'can select row');

# connnect to alt db
lives_ok {
    $db = Activator::DB->connect($testdb2);
} 'no connect error on test2_* db';
ok( defined( $db ) && $db->isa('Activator::DB'), 'valid test2 Activator::DB object');
ok( $db->{cur_alias} eq $testdb2, 'alias set to test2');

# select default row
lives_ok {
    @row = $db->getrow( 'select * from t1' );
} "getrow doesn't die";
ok( $row[0] eq '1' && $row[1] eq 'd2_t1_r1_c1' && $row[2] eq 'd2_t1_r1_c2', 'can select row from other db');

# select something that returns nothing, make sure we get empty row(ref) back
lives_ok {
    @row = $db->getrow( "select * from t1 where id = '-42'" );
} "getrow doesn't die";

ok( @row == 0, 'got empty array when select returns no rows' );

lives_ok {
    $rowref = $db->getrow_arrayref( "select * from t1 where id = '-42'" );
} "getrow_arrayref doesn't die";
ok( @$rowref == 0, 'got empty arrayref when select returns no rows' );

lives_ok {
    $rowref = $db->getrow_hashref( "select * from t1 where id = '-42'" );
} "getrow_hashref doesn't die";
ok( keys %$rowref == 0, 'got empty hashref when select returns no rows' );

# go back to default db
lives_ok {
    $db->connect();
} 'no connect error';
ok( defined( $db ) && $db->isa('Activator::DB'), 'reverted to valid default Activator::DB object');
ok( $db->{cur_alias} eq $testdb1, "alias reset to $testdb1");

# select default row
lives_ok {
    @row = $db->getrow( 'select * from t1' );
} "getrow doesn't die";
ok( $row[0] eq '1' && $row[1] eq 'd1_t1_r1_c1' && $row[2] eq 'd1_t1_r1_c2', 'can select row from orig db');

# select using "change_alias"
lives_ok {
    @row = $db->getrow( 'select * from t1', [], connect =>$testdb2 );
} "getrow doesn't die";
ok( $row[0] eq '1' && $row[1] eq 'd2_t1_r1_c1' && $row[2] eq 'd2_t1_r1_c2', 'can select row from other db using connect');

# select staticly using connect
lives_ok {
    @row = Activator::DB->getrow( 'select * from t1', [], connect =>$testdb1 );
} "getrow doesn't die";
ok( $row[0] eq '1' && $row[1] eq 'd1_t1_r1_c1' && $row[2] eq 'd1_t1_r1_c2', 'can select row from orig staticly');

# create a row
lives_ok {
    $id = Activator::DB->do_id( 'insert into t1 ( c1, c2) '.
				"values ( 'd1_t1_r2_c1', 'd1_t1_r2_c2')",
				[], 
				connect => 'def', # should go back to $testdb1
				seq => 't1_id_seq', # for Pg, ignored for mysql
			      );
} "do_id doesn't die";
ok( $id && $id == 2, 'can insert' );
ok( $db->{cur_alias} eq $testdb1, "alias set to $testdb1 using 'def'");

# select the new row
lives_ok {
    @row = Activator::DB->getrow( "select * from t1 where id='$id'", [], connect => 'def', debug => 1 );
} "getrow doesn't die";
ok( $row[0] eq '2' && $row[1] eq 'd1_t1_r2_c1' && $row[2] eq 'd1_t1_r2_c2', 'can select new row');

# test "do"
lives_ok {
    $res = $db->do( "delete from t1 where id='$id'" );
} "do doesn't die";
ok( $res == 1, 'do affects corect num of rows');
lives_ok {
    @row = $db->getrow( "select * from t1 where id='$id'" );
} "getrow doesn't die";
ok( @row == 0, 'do successfully deleted row');

# fail on static calls without connect string
throws_ok {
    @row = Activator::DB->getrow( "select * from t1 where id='$id'" );
} 'Activator::Exception::DB', 'static call dies without connect arg';

throws_ok {
    @row = Activator::DB->getrow( "sel  from foo", [], connect => 'def');
} 'Activator::Exception::DB', 'invalid sql throws Activator::Exception::DB';

throws_ok {
    @row = Activator::DB->getrow( "select * from t1", [], connect => 'defasdlkj');
} 'Activator::Exception::DB', 'invalid connect alias dies';

# get row as arrayref
lives_ok {
    $rowref = $db->getrow_arrayref( "select * from t1" );
} "getrow_arrayref doesn't die after invalid connect attempt";
ok( ref($rowref) eq 'ARRAY', 'getrow_arrayref returns arrayref');
ok( @$rowref[0] eq '1' && @$rowref[1] eq 'd1_t1_r1_c1' && @$rowref[2] eq 'd1_t1_r1_c2', 'getrow_arrayref returns expected data');

# get row as hashref
lives_ok {
    $rowref = $db->getrow_hashref( "select * from t1" );
} "getrow_hashref doesn't die";
ok( ref($rowref) eq 'HASH', 'getrow_hashref returns hashref');
ok( $rowref->{id} eq '1' && $rowref->{c1} eq 'd1_t1_r1_c1' && $rowref->{c2} eq 'd1_t1_r1_c2', 'getrow_hashref returns expected data');

my $db2 = Activator::DB->connect($testdb1);
my $db3 = Activator::DB->connect($testdb2);
ok( $db2 eq $db3, 'multiple db objects refer to the same pointer' );

# force reconnect
$db->connect( $testdb1);
delete $db->{connections}->{ $testdb1 }->{dbh};
lives_ok {
    @row = $db->getrow( 'select * from t1' );
} "getrow doesn't die";
ok( $row[0] eq '1' && $row[1] eq 'd1_t1_r1_c1' && $row[2] eq 'd1_t1_r1_c2', 'can select row when dbh is missing');


# TODO: test getall_*

# test aborting transaction
lives_ok {
    $db->connect($testdb1);
    $db->begin();
} "can begin transaction";

lives_ok {
    $db->do( 'update t1 set c1 = ?', [ 'broken' ]);
} "can update within transaction";

lives_ok {
    @row = $db->getrow( "select * from t1 where id ='1'" );
} "can select within transaction";

ok( $row[1] eq 'broken', 'value is set' );

lives_ok {
    $db->abort();
} "can abort transaction";

lives_ok {
    @row = $db->getrow( "select * from t1 where id ='1'" );
} "can select after transaction";

ok( $row[1] eq 'd1_t1_r1_c1', 'value reverts to pre-transaction state' );


# test atomic action now
lives_ok {
    $db->do( "update t1 set c1 = 'intermediate' where id='1'");
} "can update row outside transaction";

lives_ok {
    @row = $db->getrow( "select * from t1 where id ='1'" );
} "can select row outside transaction";

ok( $row[1] eq 'intermediate', 'value set outside transaction' );

# test committing transaction
lives_ok {
    $db->connect($testdb1);
    $db->begin();
} "can begin transaction";

lives_ok {
    $db->do( 'update t1 set c1 = ?', [ 'd1_t1_r1_c1_upd' ]);
} "can update within transaction";

lives_ok {
    $db->commit();
} "can commit transaction";

lives_ok {
    @row = $db->getrow( "select * from t1 where id ='1'" );
} "can select again outside commited transaction";

ok( $row[1] eq 'd1_t1_r1_c1_upd', 'transaction commited, value verified' );

# delete test dbs, users, tables
if ( $ENV{ACT_DB_TEST_ENGINE} eq 'mysql' ) {
    system( "cat $ENV{PWD}/t/data/DB-drop-mysql-test.sql | mysql -u root");
}
else {
    $db = Activator::DB->disconnect_all();
    system( "psql template1 $ENV{ACT_DB_TEST_USER} < $ENV{PWD}/t/data/DB-drop-Pg-test.sql ");
}
