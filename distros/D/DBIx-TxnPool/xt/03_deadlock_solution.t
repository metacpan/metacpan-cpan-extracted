# This test is same as 02_deadlock_solution.t only without txn_post_item cause but with txn_commit_callback
use strict;
use warnings;

use lib 'xt';

BEGIN { $Test::MultiFork::inactivity = 120 }

use Test::MultiFork;
use Test::More;

use constant    AMOUNT_TESTS => 300;

use connect;
use DBIx::TxnPool;

my $table = 'dbix_txn_pool_test';
my ( $dbh, $pool, $post_test, @data );

$post_test = 0;

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

ab:
    my $commit_callbacks = 0;

    $pool = txn_item {
        $dbh->do( "UPDATE $table SET b=? WHERE a=?", undef, $_->{b}, $_->{a} );
    }
    txn_commit {
        $commit_callbacks++;
    } dbh => $dbh;

a:
    @data = ( { b => 1, a => 1 }, { b => 1, a => 2 } );

b:
    @data = ( { b => 2, a => 2 }, { b => 2, a => 1 } );

ab:
    for ( my $i = 0; $i < AMOUNT_TESTS; $i++ ) {
        foreach my $item ( @data ) {
            $pool->add( $item );
        }
        $pool->finish;
    }

ab:
    diag "The amount deadlocks is " . $pool->amount_deadlocks;
    ok( $commit_callbacks == AMOUNT_TESTS );
    done_testing;
