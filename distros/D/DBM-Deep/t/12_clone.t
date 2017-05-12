use strict;
use warnings FATAL => 'all';

use Test::More;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

my $dbm_factory = new_dbm();
while ( my $dbm_maker = $dbm_factory->() ) {

    {
        my $clone;

        {
            my $db = $dbm_maker->();

            $db->{key1} = "value1";

            ##
            # clone db handle, make sure both are usable
            ##
            $clone = $db->clone();

            is($clone->{key1}, "value1");

            $clone->{key2} = "value2";
            $db->{key3} = "value3";

            is($db->{key1}, "value1");
            is($db->{key2}, "value2");
            is($db->{key3}, "value3");

            is($clone->{key1}, "value1");
            is($clone->{key2}, "value2");
            is($clone->{key3}, "value3");
        }

        is($clone->{key1}, "value1");
        is($clone->{key2}, "value2");
        is($clone->{key3}, "value3");
    }

    {
        my $db = $dbm_maker->();

        is($db->{key1}, "value1");
        is($db->{key2}, "value2");
        is($db->{key3}, "value3");
    }
}
done_testing;
