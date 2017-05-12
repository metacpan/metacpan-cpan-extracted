use strict;
use warnings;

use Test::Fatal;
use Test::More;
use lib 't/lib';

BEGIN {
    eval 'use Dancer2::Session::Sereal';
    plan skip_all => "Dancer2::Session::Sereal required to run these tests" if $@;
}

diag "Dancer2::Session::Sereal $Dancer2::Session::Sereal::VERSION";

use Tests;

Tests::run_tests( { session => 'Sereal' } );

done_testing;
