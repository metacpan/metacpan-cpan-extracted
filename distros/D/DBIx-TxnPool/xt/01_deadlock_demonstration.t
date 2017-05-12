use strict;
use warnings;

use lib 'xt';

use Test::MultiFork;
use Test::More;
use Test::Exception;

use connect;

my $table = 'dbix_txn_pool_test';
my $dbh;

FORK_ab:

a:
    ok( ! defined $dbh );
    $dbh = dbi_connect;

    $dbh->do( "DROP TABLE IF EXISTS $table" );
    $dbh->do( "CREATE TABLE $table ( a INT NOT NULL, b INT, INDEX (a) ) ENGINE = InnoDB" );

    $dbh->do( "INSERT INTO $table SET a=$_" ) for ( 1 .. 10 );
    ok( $dbh->selectrow_array( "SELECT COUNT(*) FROM $table" ) == 10 );

b:
    ok( ! defined $dbh );
    $dbh = dbi_connect;
    ok( $dbh->selectrow_array( "SELECT COUNT(*) FROM $table" ) == 10 );

a:
    $dbh->begin_work() or die $dbh->errstr;
    $dbh->do( "UPDATE $table SET b=1 WHERE a=1" );

b:
    $dbh->begin_work() or die $dbh->errstr;
    $dbh->do( "UPDATE $table SET b=2 WHERE a=2" );

ab:
    if ( ( procname() )[1] eq 'a' ) {
        $dbh->do( "UPDATE $table SET b=1 WHERE a=2" );
    }
    else {
        # Small transactions are preferable for breaking by MySQL: http://dev.mysql.com/doc/refman/5.5/en/innodb-deadlock-detection.html
        # This transaction is small here because the transaction from 'a' already locked 2 rows but this only one row
        dies_ok {
            select( undef, undef, undef, 0.5 );
            $dbh->do( "UPDATE $table SET b=2 WHERE a=1" );
        };
        ok( $DBI::err == 1213 );
    }
a:
    $dbh->commit or die $dbh->errstr;

b:
    $dbh->commit or die $dbh->errstr;

a:
    ok( $dbh->selectrow_array( "SELECT COUNT(*) FROM $table WHERE b=1" ) == 2 );
    ok( $dbh->selectrow_array( "SELECT COUNT(*) FROM $table WHERE b=2" ) == 0 );
    $dbh->disconnect;

b:
    ok( $dbh->selectrow_array( "SELECT COUNT(*) FROM $table WHERE b=1" ) == 2 );
    ok( $dbh->selectrow_array( "SELECT COUNT(*) FROM $table WHERE b=2" ) == 0 );
    $dbh->disconnect;

ab:
done_testing;
