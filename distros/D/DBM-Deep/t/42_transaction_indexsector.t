use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Deep;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

# This testfile is in sections because the goal is to verify the behavior
# when a reindex occurs during an active transaction, both as a result of the
# transaction's actions as well as the result of the HEAD's actions. In order
# to keep this test quick, it's easier to restart and hit the known
# reindexing at 17 keys vs. attempting to hit the second-level reindex which
# can occur as early as 18 keys and as late as 4097 (256*16+1) keys.

{
    my $dbm_factory = new_dbm(
        locking => 1,
        autoflush => 1,
        num_txns  => 16,
    );
    while ( my $dbm_maker = $dbm_factory->() ) {
        my $db1 = $dbm_maker->();
        next unless $db1->supports( 'transactions' );
        my $db2 = $dbm_maker->();

        $db1->{x} = 'y';
        is( $db1->{x}, 'y', "Before transaction, DB1's X is Y" );
        is( $db2->{x}, 'y', "Before transaction, DB2's X is Y" );

        $db1->begin_work;

            cmp_bag( [ keys %$db1 ], [qw( x )], "DB1 keys correct" );
            cmp_bag( [ keys %$db2 ], [qw( x )], "DB2 keys correct" );

            # Add enough keys to force a reindex
            $db1->{"K$_"} = "V$_" for 1 .. 16;

            cmp_bag( [ keys %$db1 ], ['x', (map { "K$_" } 1 .. 16)], "DB1 keys correct" );
            cmp_bag( [ keys %$db2 ], [qw( x )], "DB2 keys correct" );

        $db1->rollback;

        cmp_bag( [ keys %$db1 ], [qw( x )], "DB1 keys correct" );
        cmp_bag( [ keys %$db2 ], [qw( x )], "DB2 keys correct" );

        ok( !exists $db1->{"K$_"}, "DB1: Key K$_ doesn't exist" ) for 1 .. 16;
        ok( !exists $db2->{"K$_"}, "DB2: Key K$_ doesn't exist" ) for 1 .. 16;
    }
}

{
    my $dbm_factory = new_dbm(
        locking => 1,
        autoflush => 1,
        num_txns  => 16,
    );
    while ( my $dbm_maker = $dbm_factory->() ) {
        my $db1 = $dbm_maker->();
        next unless $db1->supports( 'transactions' );
        my $db2 = $dbm_maker->();

        $db1->{x} = 'y';
        is( $db1->{x}, 'y', "Before transaction, DB1's X is Y" );
        is( $db2->{x}, 'y', "Before transaction, DB2's X is Y" );

        $db1->begin_work;

            cmp_bag( [ keys %$db1 ], [qw( x )], "DB1 keys correct" );
            cmp_bag( [ keys %$db2 ], [qw( x )], "DB2 keys correct" );

            # Add enough keys to force a reindex
            $db1->{"K$_"} = "V$_" for 1 .. 16;

            cmp_bag( [ keys %$db1 ], ['x', (map { "K$_" } 1 .. 16)], "DB1 keys correct" );
            cmp_bag( [ keys %$db2 ], [qw( x )], "DB2 keys correct" );

        $db1->commit;

        cmp_bag( [ keys %$db1 ], ['x', (map { "K$_" } 1 .. 16)], "DB1 keys correct" );
        cmp_bag( [ keys %$db2 ], ['x', (map { "K$_" } 1 .. 16)], "DB2 keys correct" );

        ok( exists $db1->{"K$_"}, "DB1: Key K$_ doesn't exist" ) for 1 .. 16;
        ok( exists $db2->{"K$_"}, "DB2: Key K$_ doesn't exist" ) for 1 .. 16;
    }
}

done_testing;
