#!perl

use warnings;
use strict;

use Test::More tests => 1;

use Carp::Assert::More;

eval {
    assert_fail( "Everything is broken!" );
};
like( $@, qr/Everything is broken!/ );
