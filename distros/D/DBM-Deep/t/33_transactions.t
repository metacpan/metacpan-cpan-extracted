use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Deep;
use Test::Exception;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

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

    cmp_bag( [ keys %$db1 ], [qw( x )], "DB1 keys correct" );
    cmp_bag( [ keys %$db2 ], [qw( x )], "DB2 keys correct" );

    throws_ok {
        $db1->rollback;
    } qr/Cannot rollback without an active transaction/, "Attempting to rollback without a transaction throws an error";

    throws_ok {
        $db1->commit;
    } qr/Cannot commit without an active transaction/, "Attempting to commit without a transaction throws an error";

    $db1->begin_work;

    throws_ok {
        $db1->begin_work;
    } qr/Cannot begin_work within an active transaction/, "Attempting to begin_work within a transaction throws an error";

    lives_ok {
        $db1->rollback;
    } "Rolling back an empty transaction is ok.";

    cmp_bag( [ keys %$db1 ], [qw( x )], "DB1 keys correct" );
    cmp_bag( [ keys %$db2 ], [qw( x )], "DB2 keys correct" );

    $db1->begin_work;

    lives_ok {
        $db1->commit;
    } "Committing an empty transaction is ok.";

    cmp_bag( [ keys %$db1 ], [qw( x )], "DB1 keys correct" );
    cmp_bag( [ keys %$db2 ], [qw( x )], "DB2 keys correct" );

    $db1->begin_work;

        cmp_bag( [ keys %$db1 ], [qw( x )], "DB1 keys correct" );
        cmp_bag( [ keys %$db2 ], [qw( x )], "DB2 keys correct" );

        is( $db1->{x}, 'y', "DB1 transaction started, no actions - DB1's X is Y" );
        is( $db2->{x}, 'y', "DB1 transaction started, no actions - DB2's X is Y" );

        $db2->{x} = 'a';
        is( $db1->{x}, 'y', "Within DB1 transaction, DB1's X is still Y" );
        is( $db2->{x}, 'a', "Within DB1 transaction, DB2's X is now A" );

        $db1->{x} = 'z';
        is( $db1->{x}, 'z', "Within DB1 transaction, DB1's X is Z" );
        is( $db2->{x}, 'a', "Within DB1 transaction, DB2's X is still A" );

        $db1->{z} = 'a';
        is( $db1->{z}, 'a', "Within DB1 transaction, DB1's Z is A" );
        ok( !exists $db2->{z}, "Since z was added after the transaction began, DB2 doesn't see it." );

        $db2->{other_x} = 'foo';
        is( $db2->{other_x}, 'foo', "DB2 set other_x within DB1's transaction, so DB2 can see it" );
        ok( !exists $db1->{other_x}, "Since other_x was added after the transaction began, DB1 doesn't see it." );

        # Reset to an expected value
        $db2->{x} = 'y';
        is( $db1->{x}, 'z', "Within DB1 transaction, DB1's X is istill Z" );
        is( $db2->{x}, 'y', "Within DB1 transaction, DB2's X is now Y" );

        cmp_bag( [ keys %$db1 ], [qw( x z )], "DB1 keys correct" );
        cmp_bag( [ keys %$db2 ], [qw( x other_x )], "DB2 keys correct" );

    $db1->rollback;

    is( $db1->{x}, 'y', "After rollback, DB1's X is Y" );
    is( $db2->{x}, 'y', "After rollback, DB2's X is Y" );

    is( $db1->{other_x}, 'foo', "After DB1 transaction is over, DB1 can see other_x" );
    is( $db2->{other_x}, 'foo', "After DB1 transaction is over, DB2 can still see other_x" );

    $db1->begin_work;

        cmp_bag( [ keys %$db1 ], [qw( x other_x )], "DB1 keys correct" );
        cmp_bag( [ keys %$db2 ], [qw( x other_x )], "DB2 keys correct" );

        is( $db1->{x}, 'y', "DB1 transaction started, no actions - DB1's X is Y" );
        is( $db2->{x}, 'y', "DB1 transaction started, no actions - DB2's X is Y" );

        $db1->{x} = 'z';
        is( $db1->{x}, 'z', "Within DB1 transaction, DB1's X is Z" );
        is( $db2->{x}, 'y', "Within DB1 transaction, DB2's X is still Y" );

        $db2->{other_x} = 'bar';
        is( $db2->{other_x}, 'bar', "DB2 set other_x within DB1's transaction, so DB2 can see it" );
        is( $db1->{other_x}, 'foo', "Since other_x was modified after the transaction began, DB1 doesn't see the change." );

        $db1->{z} = 'a';
        is( $db1->{z}, 'a', "Within DB1 transaction, DB1's Z is A" );
        ok( !exists $db2->{z}, "Since z was added after the transaction began, DB2 doesn't see it." );

        cmp_bag( [ keys %$db1 ], [qw( x other_x z )], "DB1 keys correct" );
        cmp_bag( [ keys %$db2 ], [qw( x other_x )], "DB2 keys correct" );

    $db1->commit;

    is( $db1->{x}, 'z', "After commit, DB1's X is Z" );
    is( $db2->{x}, 'z', "After commit, DB2's X is Z" );

    is( $db1->{z}, 'a', "After commit, DB1's Z is A" );
    is( $db2->{z}, 'a', "After commit, DB2's Z is A" );

    is( $db1->{other_x}, 'bar', "After commit, DB1's other_x is bar" );
    is( $db2->{other_x}, 'bar', "After commit, DB2's other_x is bar" );

    $db1->begin_work;

        cmp_bag( [ keys %$db1 ], [qw( x z other_x )], "DB1 keys correct" );
        cmp_bag( [ keys %$db2 ], [qw( x z other_x )], "DB2 keys correct" );

        is( $db1->{x}, 'z', "After commit, DB1's X is Z" );
        is( $db2->{x}, 'z', "After commit, DB2's X is Z" );

        is( $db1->{z}, 'a', "After commit, DB1's Z is A" );
        is( $db2->{z}, 'a', "After commit, DB2's Z is A" );

        is( $db1->{other_x}, 'bar', "After begin_work, DB1's other_x is still bar" );
        is( $db2->{other_x}, 'bar', "After begin_work, DB2's other_x is still bar" );

        delete $db2->{other_x};
        ok( !exists $db2->{other_x}, "DB2 deleted other_x in DB1's transaction, so it can't see it anymore" );
        is( $db1->{other_x}, 'bar', "Since other_x was deleted after the transaction began, DB1 still sees it." );

        cmp_bag( [ keys %$db1 ], [qw( x z other_x )], "DB1 keys correct" );
        cmp_bag( [ keys %$db2 ], [qw( x z )], "DB2 keys correct" );

        delete $db1->{x};
        ok( !exists $db1->{x}, "DB1 deleted X in a transaction, so it can't see it anymore" );
        is( $db2->{x}, 'z', "But, DB2 can still see it" );

        cmp_bag( [ keys %$db1 ], [qw( other_x z )], "DB1 keys correct" );
        cmp_bag( [ keys %$db2 ], [qw( x z )], "DB2 keys correct" );

    $db1->rollback;

    ok( !exists $db2->{other_x}, "It's still deleted for DB2" );
    ok( !exists $db1->{other_x}, "And now DB1 sees the deletion" );

    is( $db1->{x}, 'z', "The transaction was rolled back, so DB1 can see X now" );
    is( $db2->{x}, 'z', "DB2 can still see it" );

    cmp_bag( [ keys %$db1 ], [qw( x z )], "DB1 keys correct" );
    cmp_bag( [ keys %$db2 ], [qw( x z )], "DB2 keys correct" );

    $db1->begin_work;

        delete $db1->{x};
        ok( !exists $db1->{x}, "DB1 deleted X in a transaction, so it can't see it anymore" );

        is( $db2->{x}, 'z', "But, DB2 can still see it" );

        cmp_bag( [ keys %$db1 ], [qw( z )], "DB1 keys correct" );
        cmp_bag( [ keys %$db2 ], [qw( x z )], "DB2 keys correct" );

    $db1->commit;

    ok( !exists $db1->{x}, "The transaction was committed, so DB1 still deleted X" );
    ok( !exists $db2->{x}, "DB2 can now see the deletion of X" );

    $db1->{foo} = 'bar';
    is( $db1->{foo}, 'bar', "Set foo to bar in DB1" );
    is( $db2->{foo}, 'bar', "Set foo to bar in DB2" );

    cmp_bag( [ keys %$db1 ], [qw( foo z )], "DB1 keys correct" );
    cmp_bag( [ keys %$db2 ], [qw( foo z )], "DB2 keys correct" );

    $db1->begin_work;

        %$db1 = (); # clear()
        ok( !exists $db1->{foo}, "Cleared foo" );
        is( $db2->{foo}, 'bar', "But in DB2, we can still see it" );

        cmp_bag( [ keys %$db1 ], [qw()], "DB1 keys correct" );
        cmp_bag( [ keys %$db2 ], [qw( foo z )], "DB2 keys correct" );

    $db1->rollback;

    is( $db1->{foo}, 'bar', "Rollback means 'foo' is still there" );
    is( $db2->{foo}, 'bar', "Rollback means 'foo' is still there" );

    cmp_bag( [ keys %$db1 ], [qw( foo z )], "DB1 keys correct" );
    cmp_bag( [ keys %$db2 ], [qw( foo z )], "DB2 keys correct" );

    SKIP: {
        skip "Optimize tests skipped on Win32", 7
            if $^O eq 'MSWin32' || $^O eq 'cygwin';

        $db1->optimize;

        is( $db1->{foo}, 'bar', 'After optimize, everything is ok' );
        is( $db2->{foo}, 'bar', 'After optimize, everything is ok' );

        is( $db1->{z}, 'a', 'After optimize, everything is ok' );
        is( $db2->{z}, 'a', 'After optimize, everything is ok' );

        cmp_bag( [ keys %$db1 ], [qw( foo z )], "DB1 keys correct" );
        cmp_bag( [ keys %$db2 ], [qw( foo z )], "DB2 keys correct" );

        $db1->begin_work;

            cmp_ok( $db1->_engine->trans_id, '==', 1, "Transaction ID has been reset after optimize" );

        $db1->rollback;
    }
}

done_testing;
