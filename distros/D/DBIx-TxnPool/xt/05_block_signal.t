# This test is same as 02_deadlock_solution.t only without txn_post_item cause but with txn_commit_callback
use strict;
use warnings;

use lib 'xt';

BEGIN { $Test::MultiFork::inactivity = 120 }

use Test::MultiFork;
use Test::More;
use Test::Exception;
use Signal::Mask;

use constant    AMOUNT_TESTS => 20;

use connect;
use DBIx::TxnPool;

my $table = 'dbix_txn_pool_test';
my ( $dbh, $pool, $post_test, @data, $pid_a, $pid_b, $amount_TERM_signals );

$post_test = 0;

FORK_ab:

a:
    lockcommon();
    setcommon($$);
    unlockcommon();

b:
    ( $pid_a ) = getcommon();

b:
    lockcommon();
    setcommon($$);
    unlockcommon();

a:
    ( $pid_b ) = getcommon();

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
    $amount_TERM_signals = 0;

    $pool = txn_item {
        $dbh->do( "UPDATE $table SET b=? WHERE a=?", undef, $_->{b}, $_->{a} );
        kill 15, defined $pid_a ? $pid_a : $pid_b;
    }
    txn_commit {
        $commit_callbacks++;
    } dbh => $dbh;

    $SIG{TERM} = sub { $amount_TERM_signals++ };

a:
    @data = ( { b => 1, a => 1 }, { b => 1, a => 2 } );

b:
    @data = ( { b => 2, a => 2 }, { b => 2, a => 1 } );

ab:
    ok ! $Signal::Mask{TERM};
    lives_ok {
        for ( my $i = 0; $i < AMOUNT_TESTS; $i++ ) {
            foreach my $item ( @data ) {
                $pool->add( $item );
            }
            $pool->finish;
        }
    };
    ok ! $Signal::Mask{TERM};

ab:
    ok( $commit_callbacks == AMOUNT_TESTS );
    #diag "pid $$, caught number TERM signals: $amount_TERM_signals";
    ok $amount_TERM_signals > 0;

ab:
    {
        local $Signal::Mask{TERM} = 1;

        $amount_TERM_signals = 0;

        ok $Signal::Mask{TERM};
        lives_ok {
            for ( my $i = 0; $i < AMOUNT_TESTS; $i++ ) {
                foreach my $item ( @data ) {
                    $pool->add( $item );
                    ok $Signal::Mask{TERM};
                }
                $pool->finish;
            }
        };
        ok $Signal::Mask{TERM};
        ok $amount_TERM_signals == 0;
    }

ab:
    #diag "pid $$, caught number TERM signals: $amount_TERM_signals";
    ok $amount_TERM_signals > 0;

    done_testing;
