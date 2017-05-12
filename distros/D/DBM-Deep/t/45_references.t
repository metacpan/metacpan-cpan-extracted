use strict;
use warnings FATAL => 'all';

use Test::More;
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

    $db1->{foo} = 5;
    $db1->{bar} = $db1->{foo};

    is( $db1->{foo}, 5, "Foo is still 5" );
    is( $db1->{bar}, 5, "Bar is now 5" );

    $db1->{foo} = 6;

    is( $db1->{foo}, 6, "Foo is now 6" );
    is( $db1->{bar}, 5, "Bar is still 5" );

    $db1->{foo} = [ 1 .. 3 ];
    $db1->{bar} = $db1->{foo};

    is( $db1->{foo}[1], 2, "Foo[1] is still 2" );
    is( $db1->{bar}[1], 2, "Bar[1] is now 2" );

    $db1->{foo}[3] = 42;

    is( $db1->{foo}[3], 42, "Foo[3] is now 42" );
    is( $db1->{bar}[3], 42, "Bar[3] is also 42" );

    delete $db1->{foo};
    is( $db1->{bar}[3], 42, "After delete Foo, Bar[3] is still 42" );

    $db1->{foo} = $db1->{bar};
    $db2->begin_work;

        delete $db2->{bar};
        delete $db2->{foo};

        is( $db2->{bar}, undef, "It's deleted in the transaction" );
        is( $db1->{bar}[3], 42, "... but not in the main" );

    $db2->rollback;

    # Why hasn't this failed!? Is it because stuff isn't getting deleted as
    # expected? I need a test that walks the sectors
    is( $db1->{bar}[3], 42, "After delete Foo, Bar[3] is still 42" );
    is( $db2->{bar}[3], 42, "After delete Foo, Bar[3] is still 42" );

    delete $db1->{foo};

    is( $db1->{bar}[3], 42, "After delete Foo, Bar[3] is still 42" );
}

done_testing;

__END__
$db2->begin_work;

  delete $db2->{bar};

$db2->commit;

ok( !exists $db1->{bar}, "After commit, bar is gone" );
