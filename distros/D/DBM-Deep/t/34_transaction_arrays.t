use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Deep;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

my $dbm_factory = new_dbm(
    locking => 1,
    autoflush => 1,
    num_txns  => 16,
    type => DBM::Deep->TYPE_ARRAY,
);
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db1 = $dbm_maker->();
    next unless $db1->supports( 'transactions' );
    my $db2 = $dbm_maker->();

    $db1->[0] = 'y';
    is( $db1->[0], 'y', "Before transaction, DB1's 0 is Y" );
    is( $db2->[0], 'y', "Before transaction, DB2's 0 is Y" );

    $db1->begin_work;

        is( $db1->[0], 'y', "DB1 transaction started, no actions - DB1's 0 is Y" );
        is( $db2->[0], 'y', "DB1 transaction started, no actions - DB2's 0 is Y" );

        $db1->[0] = 'z';
        is( $db1->[0], 'z', "Within DB1 transaction, DB1's 0 is Z" );
        is( $db2->[0], 'y', "Within DB1 transaction, DB2's 0 is still Y" );

        $db2->[1] = 'foo';
        is( $db2->[1], 'foo', "DB2 set 1 within DB1's transaction, so DB2 can see it" );
        ok( !exists $db1->[1], "Since 1 was added after the transaction began, DB1 doesn't see it." );

        cmp_ok( scalar(@$db1), '==', 1, "DB1 has 1 element" );
        cmp_ok( scalar(@$db2), '==', 2, "DB2 has 2 elements" );

    $db1->rollback;

    is( $db1->[0], 'y', "After rollback, DB1's 0 is Y" );
    is( $db2->[0], 'y', "After rollback, DB2's 0 is Y" );

    is( $db1->[1], 'foo', "After DB1 transaction is over, DB1 can see 1" );
    is( $db2->[1], 'foo', "After DB1 transaction is over, DB2 can still see 1" );

    cmp_ok( scalar(@$db1), '==', 2, "DB1 now has 2 elements" );
    cmp_ok( scalar(@$db2), '==', 2, "DB2 still has 2 elements" );

    $db1->begin_work;

        is( $db1->[0], 'y', "DB1 transaction started, no actions - DB1's 0 is Y" );
        is( $db2->[0], 'y', "DB1 transaction started, no actions - DB2's 0 is Y" );

        $db1->[2] = 'z';
        is( $db1->[2], 'z', "Within DB1 transaction, DB1's 2 is Z" );
        ok( !exists $db2->[2], "Within DB1 transaction, DB2 cannot see 2" );

        cmp_ok( scalar(@$db1), '==', 3, "DB1 has 3 elements" );
        cmp_ok( scalar(@$db2), '==', 2, "DB2 has 2 elements" );

    $db1->commit;

    is( $db1->[0], 'y', "After rollback, DB1's 0 is Y" );
    is( $db2->[0], 'y', "After rollback, DB2's 0 is Y" );

    is( $db1->[2], 'z', "After DB1 transaction is over, DB1 can still see 2" );
    is( $db2->[2], 'z', "After DB1 transaction is over, DB2 can now see 2" );

    cmp_ok( scalar(@$db1), '==', 3, "DB1 now has 2 elements" );
    cmp_ok( scalar(@$db2), '==', 3, "DB2 still has 2 elements" );

    $db1->begin_work;

        push @$db1, 'foo';
        unshift @$db1, 'bar';

        cmp_ok( scalar(@$db1), '==', 5, "DB1 now has 5 elements" );
        cmp_ok( scalar(@$db2), '==', 3, "DB2 still has 3 elements" );

        is( $db1->[0], 'bar' );
        is( $db1->[-1], 'foo' );

    $db1->rollback;

    cmp_ok( scalar(@$db1), '==', 3, "DB1 is back to 3 elements" );
    cmp_ok( scalar(@$db2), '==', 3, "DB2 still has 3 elements" );

    $db1->begin_work;

        push @$db1, 'foo';
        unshift @$db1, 'bar';

        cmp_ok( scalar(@$db1), '==', 5, "DB1 now has 5 elements" );
        cmp_ok( scalar(@$db2), '==', 3, "DB2 still has 3 elements" );

    $db1->commit;

    cmp_ok( scalar(@$db1), '==', 5, "DB1 is still at 5 elements" );
    cmp_ok( scalar(@$db2), '==', 5, "DB2 now has 5 elements" );

    is( $db1->[0], 'bar' );
    is( $db1->[-1], 'foo' );

    is( $db2->[0], 'bar' );
    is( $db2->[-1], 'foo' );

    $db1->begin_work;

        @$db1 = (); # clear()

        cmp_ok( scalar(@$db1), '==', 0, "DB1 now has 0 elements" );
        cmp_ok( scalar(@$db2), '==', 5, "DB2 still has 5 elements" );

    $db1->rollback;

    cmp_ok( scalar(@$db1), '==', 5, "DB1 now has 5 elements" );
    cmp_ok( scalar(@$db2), '==', 5, "DB2 still has 5 elements" );
}

done_testing;
