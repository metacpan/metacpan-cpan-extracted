#!perl -Tw

use warnings;
use strict;

use Test::More tests=>2;

BEGIN { use_ok( 'Carp::Assert::More' ); }

eval {
    assert_fail( "Everything is broken!" );
};
like( $@, qr/Everything is broken!/ );
