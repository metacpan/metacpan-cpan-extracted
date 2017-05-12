use strict;
use warnings;

use Test::Fatal;
use Test::More;
use lib 't/lib';

BEGIN {
    eval 'use Dancer2::Session::PSGI';
    plan skip_all => "Dancer2::Session::PSGI required to run these tests" if $@;
    $ENV{DANCER_APPHANDLER} = 'PSGI';
}

diag "Dancer2::Session::PSGI $Dancer2::Session::PSGI::VERSION";

use Tests;

Tests::run_tests( { session => 'PSGI' } );

done_testing;
