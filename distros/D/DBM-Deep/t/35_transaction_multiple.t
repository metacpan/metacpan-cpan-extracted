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
);
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db1 = $dbm_maker->();
    next unless $db1->supports( 'transactions' );
    my $db2 = $dbm_maker->();
    my $db3 = $dbm_maker->();

    $db1->{foo} = 'bar';
    is( $db1->{foo}, 'bar', "Before transaction, DB1's foo is bar" );
    is( $db2->{foo}, 'bar', "Before transaction, DB2's foo is bar" );
    is( $db3->{foo}, 'bar', "Before transaction, DB3's foo is bar" );

    $db1->begin_work;

    is( $db1->{foo}, 'bar', "Before transaction work, DB1's foo is bar" );
    is( $db2->{foo}, 'bar', "Before transaction work, DB2's foo is bar" );
    is( $db3->{foo}, 'bar', "Before transaction work, DB3's foo is bar" );

    $db1->{foo} = 'bar2';

    is( $db1->{foo}, 'bar2', "After DB1 foo to bar2, DB1's foo is bar2" );
    is( $db2->{foo}, 'bar', "After DB1 foo to bar2, DB2's foo is bar" );
    is( $db3->{foo}, 'bar', "After DB1 foo to bar2, DB3's foo is bar" );

    $db1->{bar} = 'foo';

    ok(  exists $db1->{bar}, "After DB1 set bar to foo, DB1's bar exists" );
    ok( !exists $db2->{bar}, "After DB1 set bar to foo, DB2's bar doesn't exist" );
    ok( !exists $db3->{bar}, "After DB1 set bar to foo, DB3's bar doesn't exist" );
     
    $db2->begin_work;

    is( $db1->{foo}, 'bar2', "After DB2 transaction begin, DB1's foo is still bar2" );
    is( $db2->{foo}, 'bar', "After DB2 transaction begin, DB2's foo is still bar" );
    is( $db3->{foo}, 'bar', "After DB2 transaction begin, DB3's foo is still bar" );

    ok(  exists $db1->{bar}, "After DB2 transaction begin, DB1's bar exists" );
    ok( !exists $db2->{bar}, "After DB2 transaction begin, DB2's bar doesn't exist" );
    ok( !exists $db3->{bar}, "After DB2 transaction begin, DB3's bar doesn't exist" );

    $db2->{foo} = 'bar333';

    is( $db1->{foo}, 'bar2', "After DB2 foo to bar2, DB1's foo is bar2" );
    is( $db2->{foo}, 'bar333', "After DB2 foo to bar2, DB2's foo is bar333" );
    is( $db3->{foo}, 'bar', "After DB2 foo to bar2, DB3's foo is bar" );

    $db2->{bar} = 'mybar';

    ok(  exists $db1->{bar}, "After DB2 set bar to mybar, DB1's bar exists" );
    ok(  exists $db2->{bar}, "After DB2 set bar to mybar, DB2's bar exists" );
    ok( !exists $db3->{bar}, "After DB2 set bar to mybar, DB3's bar doesn't exist" );

    is( $db1->{bar}, 'foo', "DB1's bar is still foo" );
    is( $db2->{bar}, 'mybar', "DB2's bar is now mybar" );

    $db2->{mykey} = 'myval';

    ok( !exists $db1->{mykey}, "After DB2 set mykey to myval, DB1's mykey doesn't exist" );
    ok(  exists $db2->{mykey}, "After DB2 set mykey to myval, DB2's mykey exists" );
    ok( !exists $db3->{mykey}, "After DB2 set mykey to myval, DB3's mykey doesn't exist" );

    cmp_bag( [ keys %$db1 ], [qw( foo bar )], "DB1 keys correct" );
    cmp_bag( [ keys %$db2 ], [qw( foo bar mykey )], "DB2 keys correct" );
    cmp_bag( [ keys %$db3 ], [qw( foo )], "DB3 keys correct" );

    $db1->commit;

    is( $db1->{foo}, 'bar2', "After DB1 commit, DB1's foo is bar2" );
    is( $db2->{foo}, 'bar333', "After DB1 commit, DB2's foo is bar333" );
    is( $db3->{foo}, 'bar2', "After DB1 commit, DB3's foo is bar2" );

    is( $db1->{bar}, 'foo', "DB1's bar is still foo" );
    is( $db2->{bar}, 'mybar', "DB2's bar is still mybar" );
    is( $db3->{bar}, 'foo', "DB3's bar is now foo" );

    cmp_bag( [ keys %$db1 ], [qw( foo bar )], "DB1 keys correct" );
    cmp_bag( [ keys %$db2 ], [qw( foo bar mykey )], "DB2 keys correct" );
    cmp_bag( [ keys %$db3 ], [qw( foo bar )], "DB3 keys correct" );

    $db2->commit;

    is( $db1->{foo}, 'bar333', "After DB2 commit, DB1's foo is bar333" );
    is( $db2->{foo}, 'bar333', "After DB2 commit, DB2's foo is bar333" );
    is( $db3->{foo}, 'bar333', "After DB2 commit, DB3's foo is bar333" );

    is( $db1->{bar}, 'mybar', "DB1's bar is now mybar" );
    is( $db2->{bar}, 'mybar', "DB2's bar is still mybar" );
    is( $db3->{bar}, 'mybar', "DB3's bar is now mybar" );

    cmp_bag( [ keys %$db1 ], [qw( foo bar mykey )], "DB1 keys correct" );
    cmp_bag( [ keys %$db2 ], [qw( foo bar mykey )], "DB2 keys correct" );
    cmp_bag( [ keys %$db3 ], [qw( foo bar mykey )], "DB3 keys correct" );
}

done_testing;
