use strict;
use warnings FATAL => 'all';

use Test::More;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

my $dbm_factory = new_dbm();
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    my $val1 = "a" x 6000;

    $db->{foo} = $val1;
    is( $db->{foo}, $val1, "6000 char value stored and retrieved" );

#    delete $db->{foo};
#    my $size = -s $filename;
#    $db->{bar} = "a" x 300;
#    is( $db->{bar}, 'a' x 300, "New 256 char value is stored" );
#    cmp_ok( $size, '==', -s $filename, "Freespace is reused" );
}

done_testing;
