use strict;
use warnings;

use Test::Fatal;
use Test::More;
use lib 't/lib';

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'redis';

    eval 'use Redis';
    plan skip_all => "Redis required to run these tests" if $@;

    eval 'use Dancer2::Session::Redis 0.008';
    plan skip_all => "Dancer2::Session::Redis >= 0.008 required to run these tests" if $@;

    eval 'use Sereal::Decoder';
    plan skip_all => "Sereal::Decoder required to run these tests" if $@;

    eval 'use Sereal::Encoder';
    plan skip_all => "Sereal::Encoder required to run these tests" if $@;
}

diag "Redis $Redis::VERSION Dancer2::Session::Redis $Dancer2::Session::Redis::VERSION";

eval { Redis->new; 1 } or plan skip_all => $@;

use Tests;

Tests::run_tests();

done_testing;
