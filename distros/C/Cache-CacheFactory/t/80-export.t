#!perl -T

use strict;
use warnings;

use Test::More;
use Cache::CacheFactory qw/:best_available $NO_MAX_SIZE/;

plan tests => 4;

ok( best_available_storage_policy( 'memory', 'file' ), "best available storage policy exported" );
ok( best_available_pruning_policy( 'time', 'size' ), "best available pruning policy exported" );
ok( best_available_validity_policy( 'time', 'size' ), "best available validity policy exported" );
is( defined( $NO_MAX_SIZE ), 1, "\$NO_MAX_SIZE exported" );
