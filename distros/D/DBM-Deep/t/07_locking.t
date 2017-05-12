use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

my $dbm_factory = new_dbm( locking => 1 );
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    lives_ok {
        $db->unlock;
    } "Can call unlock on an unlocked DB.";

    ##
    # basic put/get
    ##
    $db->{key1} = "value1";
    is( $db->{key1}, "value1", "key1 is set" );

    $db->{key2} = [ 1 .. 3 ];
    is( $db->{key2}[1], 2, "The value is set properly" );

    ##
    # explicit lock
    ##
    $db->lock_exclusive;
    $db->{key1} = "value2";
    $db->unlock();
    is( $db->{key1}, "value2", "key1 is overridden" );
}

done_testing;
