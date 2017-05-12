use strict;
use warnings;

use Test::Fatal;
use Test::More;
use lib 't/lib';

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'cookie';

    eval 'use Dancer2::Session::Cookie';
    plan skip_all => "Dancer2::Session::Cookie required to run these tests" if $@;
}

diag "Dancer2::Session::Cookie $Dancer2::Session::Cookie::VERSION";

use Tests;

Tests::run_tests( { session => 'Cookie' } );

done_testing;
